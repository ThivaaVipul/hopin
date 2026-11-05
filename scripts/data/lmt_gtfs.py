"""LMT's Metro bus routes and their recent timetables, from the community GTFS feed.

docs/PLAN.md, Which bus. The feed is built from the buses' own runs: each day
of the last few weeks is a service of its own, with the times its trips kept.
So a direction's timetable here is its latest weekday, Saturday and Sunday.
Each direction keeps its stops in order along its shape, with the minutes from
its first stop, and its trips' departures from that first stop.
"""

from __future__ import annotations

import csv
import datetime
import io
import statistics
import zipfile
from collections import Counter, defaultdict
from itertools import pairwise

from geometry import Point, encode_polyline, project, simplify
from towns import Towns, names_of

GTFS = "https://api.transit.seyone.dev/api/v1/gtfs/download?agency=LMT"
CREDIT = "Lanka Metro Transit's buses, from the community transit feed (transit.seyone.dev)"

# Day masks, Monday first (bit 0).
WEEKDAYS = 0b0011111
SATURDAY = 0b0100000
SUNDAY = 0b1000000

# A stop further than this from its direction's shape isn't on it.
STOP_WITHIN_M = 150


def _rows(archive: zipfile.ZipFile, name: str) -> list[dict[str, str]]:
    if name not in archive.namelist():
        return []
    with archive.open(name) as raw:
        return list(csv.DictReader(io.TextIOWrapper(raw, encoding="utf-8-sig")))


def clock(text: str) -> int | None:
    """GTFS's "HH:MM:SS" (hours may pass 24) as whole minutes after midnight."""
    try:
        hours, mins, secs = (int(part) for part in text.strip().split(":"))
    except ValueError:
        return None
    return hours * 60 + mins + round(secs / 60)


def day_kind(date: datetime.date) -> int:
    weekday = date.weekday()
    return WEEKDAYS if weekday < 5 else SATURDAY if weekday == 5 else SUNDAY


def _service_dates(archive: zipfile.ZipFile) -> dict[str, list[datetime.date]]:
    def parse(text: str) -> datetime.date:
        return datetime.datetime.strptime(text, "%Y%m%d").date()

    dates: dict[str, list[datetime.date]] = defaultdict(list)
    names = ("monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday")
    for row in _rows(archive, "calendar.txt"):
        day, last = parse(row["start_date"]), parse(row["end_date"])
        while day <= last:
            if row.get(names[day.weekday()]) == "1":
                dates[row["service_id"]].append(day)
            day += datetime.timedelta(days=1)
    for row in _rows(archive, "calendar_dates.txt"):
        if row.get("exception_type") == "1":
            dates[row["service_id"]].append(parse(row["date"]))
    return dates


def _offsets(
    order: list[str], visits: list[dict[str, int]], along: dict[str, float]
) -> dict[str, int]:
    """Minutes from the first stop to each, chaining the median time from stop to stop.

    The feed's trips are pieces of runs (a few stops each, as the buses were
    seen), so no one trip spans the route. A step no trip saw takes the pace
    of the steps that were seen.
    """
    pairs = list(pairwise(order))
    steps: list[float | None] = []
    for a, b in pairs:
        gaps = [t[b] - t[a] for t in visits if a in t and b in t and t[b] >= t[a]]
        steps.append(statistics.median(gaps) if gaps else None)
    seen_m = sum(
        along[b] - along[a] for (a, b), step in zip(pairs, steps, strict=True) if step is not None
    )
    seen_minutes = sum(step for step in steps if step is not None)
    # Minutes per metre; about 25 km/h when nothing was seen.
    pace = seen_minutes / seen_m if seen_m > 0 else 60 / 25_000
    total = 0.0
    offsets = {order[0]: 0}
    for (a, b), step in zip(pairs, steps, strict=True):
        total += step if step is not None else pace * (along[b] - along[a])
        offsets[b] = round(total)
    return offsets


def _distinct(minutes: list[int], apart: int = 3) -> list[int]:
    """Departures at least a few minutes apart: pieces of one run give about the same time."""
    kept: list[int] = []
    for minute in sorted(minutes):
        if not kept or minute - kept[-1] >= apart:
            kept.append(minute)
    return kept


def build(data: bytes, towns: Towns) -> tuple[list[dict], list[str]]:
    """Every route in the feed, a direction per direction_id, and a note per one left out."""
    archive = zipfile.ZipFile(io.BytesIO(data))
    notes: list[str] = []
    stops = {
        row["stop_id"]: ((float(row["stop_lat"]), float(row["stop_lon"])), row["stop_name"])
        for row in _rows(archive, "stops.txt")
    }
    shapes: dict[str, list[tuple[int, Point]]] = defaultdict(list)
    for row in _rows(archive, "shapes.txt"):
        point = (float(row["shape_pt_lat"]), float(row["shape_pt_lon"]))
        shapes[row["shape_id"]].append((int(row["shape_pt_sequence"]), point))
    dates = _service_dates(archive)
    trips = {row["trip_id"]: row for row in _rows(archive, "trips.txt")}
    visits: dict[str, dict[str, int]] = defaultdict(dict)
    for row in _rows(archive, "stop_times.txt"):
        minute = clock(row.get("departure_time") or row.get("arrival_time") or "")
        if minute is not None and row["trip_id"] in trips:
            visits[row["trip_id"]].setdefault(row["stop_id"], minute)
    groups: dict[tuple[str, str], list[dict[str, str]]] = defaultdict(list)
    for trip in trips.values():
        groups[(trip["route_id"], trip.get("direction_id", "0"))].append(trip)
    routes = {row["route_id"]: row for row in _rows(archive, "routes.txt")}
    built: dict[str, dict] = {}
    for (route_id, direction_id), group in sorted(groups.items()):
        route = routes.get(route_id)
        if route is None:
            continue
        number = route.get("route_short_name") or route_id
        direction = _direction(group, visits, dates, stops, shapes, towns)
        if direction is None:
            notes.append(f"lmt {number} direction {direction_id}: left out, no usable trips")
            continue
        entry = built.setdefault(
            route_id, {"id": f"lmt:{number}", "number": number, "directions": []}
        )
        entry["directions"].append(direction)
    for entry in built.values():
        # Each direction starts where the other one is headed.
        directions = entry["directions"]
        if len(directions) == 2:
            directions[0]["origin"] = directions[1]["board"]
            directions[1]["origin"] = directions[0]["board"]
    return list(built.values()), notes


def _along(
    path: list[Point],
    trips: list[dict[str, str]],
    visits: dict[str, dict[str, int]],
    stops: dict[str, tuple[Point, str]],
) -> dict[str, float]:
    """Metres along the path to each stop the trips passed, for stops on it."""
    along: dict[str, float] = {}
    for trip in trips:
        for stop in visits[trip["trip_id"]]:
            if stop in stops and stop not in along:
                distance, away = project(path, stops[stop][0])
                if away <= STOP_WITHIN_M:
                    along[stop] = distance
    return along


def _runs_backwards(
    along: dict[str, float], trips: list[dict[str, str]], visits: dict[str, dict[str, int]]
) -> bool:
    """Whether most trips move back along the path: later stops nearer its start."""
    votes = 0
    for trip in trips:
        seen = sorted(
            (minute, along[s]) for s, minute in visits[trip["trip_id"]].items() if s in along
        )
        if len(seen) >= 2 and seen[-1][1] != seen[0][1]:
            votes += 1 if seen[-1][1] > seen[0][1] else -1
    return votes < 0


def _direction(
    group: list[dict[str, str]],
    visits: dict[str, dict[str, int]],
    dates: dict[str, list[datetime.date]],
    stops: dict[str, tuple[Point, str]],
    shapes: dict[str, list[tuple[int, Point]]],
    towns: Towns,
) -> dict | None:
    # The busiest day of each kind: the newest day may be under way, and a
    # holiday runs fewer buses.
    by_day: dict[datetime.date, list[dict[str, str]]] = defaultdict(list)
    for trip in group:
        if visits.get(trip["trip_id"]):
            for date in dates.get(trip["service_id"], []):
                by_day[date].append(trip)
    chosen: dict[int, list[dict[str, str]]] = {}
    for date in sorted(by_day, key=lambda day: (len(by_day[day]), day), reverse=True):
        chosen.setdefault(day_kind(date), by_day[date])
    picked = [trip for trips in chosen.values() for trip in trips]
    shape_id = Counter(trip.get("shape_id", "") for trip in picked).most_common(1)
    shape = sorted(shapes.get(shape_id[0][0], [])) if shape_id else []
    if not picked or len(shape) < 2:
        return None
    path = simplify([point for _, point in shape], 10.0)
    along = _along(path, picked, visits, stops)
    if _runs_backwards(along, picked, visits):
        # The feed has been seen to give a direction the other one's shape.
        path.reverse()
        along = _along(path, picked, visits, stops)
    order = sorted(along, key=along.__getitem__)
    if len(order) < 2:
        return None
    trip_visits = [
        {stop: minute for stop, minute in visits[trip["trip_id"]].items() if stop in along}
        for trip in picked
    ]
    offsets = _offsets(order, trip_visits, along)
    times = []
    for kind in (WEEKDAYS, SATURDAY, SUNDAY):
        departs = []
        for trip in chosen.get(kind, []):
            seen = {s: m for s, m in visits[trip["trip_id"]].items() if s in offsets}
            if seen:
                stop = min(seen, key=lambda s: along[s])
                departs.append((seen[stop] - offsets[stop]) % 1440)
        if departs:
            times.append({"days": kind, "departs": _distinct(departs)})
    headsign = Counter(trip.get("trip_headsign", "") for trip in picked).most_common(1)[0][0]
    last = stops[order[-1]][0]
    board = names_of(towns.named(headsign, near=last, within_m=5000), headsign or None)
    return {
        "board": board,
        "origin": {},
        "path": encode_polyline(path),
        "stops": [
            [round(stops[s][0][0], 5), round(stops[s][0][1], 5), stops[s][1], offsets.get(s, 0)]
            for s in order
        ],
        "times": times,
    }
