"""OpenStreetMap's numbered bus routes, as route data (docs/PLAN.md, Which bus).

Most of Sri Lanka's route relations are one unordered bag of ways for both
directions, often with gaps and often mapped only part of the way, so the ways
aren't joined in order: they are treated as a small road network, and each
direction is the shortest road through it between its two ends. The ends come
from the from and to tags or the route's name ("A - B", "A/B/C - D"): each is
the town of that name nearest the network, or, for a name that isn't a town
("Bakery Junction"), the network's far end from the other one. A partly mapped
route keeps the part that is mapped, with its real boards, and the rest of its
road to its towns is guessed along real roads by OSRM, through the "via" towns
its name gives ("A - B via C"); the guessed parts ("before" and "after") are
kept apart from the mapped road, so the app can tell them apart. A name with
several towns at one end ("A/B/C") gives a direction to each of them, since
their buses show different boards.
"""

from __future__ import annotations

import heapq
import json
import re
import time
from collections import defaultdict
from collections.abc import Callable, Sequence
from dataclasses import dataclass
from itertools import pairwise

from geometry import (
    Point,
    decode_polyline,
    encode_polyline,
    length,
    metres,
    project,
    simplify,
)
from towns import Town, Towns, names_of

# Guesses a road through points, or None (OSRM, or a fake in tests).
Router = Callable[[list[Point]], list[Point] | None]

OSRM = "https://router.project-osrm.org/route/v1/driving/"

# A town further than this from where the mapped road stops gets the rest of
# the road guessed; a via town this far off the mapped road is on that rest.
FILL_M = 500
VIA_OFF_M = 1000
# A via town further than this from both of a route's towns is a namesake.
VIA_WITHIN_M = 50_000

QUERY = (
    '[out:json][timeout:300];area["ISO3166-1"="LK"][admin_level=2]->.lk;'
    "relation[type=route][route=bus](area.lk);out body geom;"
)

CREDIT = (
    "Bus routes from OpenStreetMap, (c) OpenStreetMap contributors, ODbL; "
    "the rest of a partly mapped road guessed with OSRM"
)

# A town further than this from the route's roads is a namesake elsewhere.
TOWN_WITHIN_M = 15_000
# Mapping gaps between ways bridged as if joined, at a cost.
BRIDGE_M = 300
# How far a stop may sit from the road, and how short a road is too short.
STOP_WITHIN_M = 60
SHORTEST_M = 500

_NUMBERS = re.compile(r"\s*[,;]\s*")
_BUS_PREFIX = re.compile(r"^\s*bus\s+[^:]*:\s*", re.I)
_VIA = re.compile(r"\s+via\s+.*$", re.I)
_BRACKETS = re.compile(r"\([^)]*\)")
_SEPARATORS = re.compile(r"\s*(?:=>|->|\u2192|\u2013|\u2014|\s-\s|-|\sto\s)\s*", re.I)

Key = tuple[float, float]


def ends_from(tags: dict[str, str]) -> tuple[list[str], list[str]]:
    """The names at each end: several where one end is given as "A/B/C"."""
    if tags.get("from") and tags.get("to"):
        start, end = tags["from"], tags["to"]
    else:
        name = tags.get("name", "")
        name = _VIA.sub("", _BRACKETS.sub("", _BUS_PREFIX.sub("", name))).strip()
        parts = [part for part in _SEPARATORS.split(name) if part.strip()]
        if len(parts) != 2:
            return [], []
        start, end = parts
    return (
        [n.strip() for n in start.split("/") if n.strip()],
        [n.strip() for n in end.split("/") if n.strip()],
    )


_VIA_NAMES = re.compile(r"\bvia\s+(.+)$", re.I)
_VIA_SPLIT = re.compile(r"\s*(?:,|&|/|\band\b)\s*", re.I)


def vias_from(tags: dict[str, str]) -> list[str]:
    """The towns a route's name says it goes through ("A - B via C, D")."""
    name = _BRACKETS.sub("", tags.get("name", ""))
    match = _VIA_NAMES.search(name)
    if not match:
        return []
    return [part.strip() for part in _VIA_SPLIT.split(match[1]) if part.strip()]


def osrm_router(fetch: Callable[[str], bytes], pause: float = 1.0) -> Router:
    """Guesses roads with OSRM's public server: light use, a request a second.

    A guess that runs on an expressway is no guess: a bus (bar an expressway
    bus) keeps off them, and the public server can't be told to.
    """

    def route(points: list[Point]) -> list[Point] | None:
        time.sleep(pause)
        coords = ";".join(f"{lng:.5f},{lat:.5f}" for lat, lng in points)
        url = f"{OSRM}{coords}?overview=full&geometries=polyline&steps=true"
        try:
            answer = json.loads(fetch(url))
        except (OSError, ValueError):
            return None
        if answer.get("code") != "Ok" or not answer.get("routes"):
            return None
        best = answer["routes"][0]
        steps = [step for leg in best.get("legs", []) for step in leg.get("steps", [])]
        if any(_on_expressway(step) for step in steps):
            return None
        return decode_polyline(best["geometry"])

    return route


_EXPRESSWAY_REF = re.compile(r"(?:^|;)\s*E\d")


def _on_expressway(step: dict) -> bool:
    name = (step.get("name") or "").lower()
    return "expressway" in name or bool(_EXPRESSWAY_REF.search(step.get("ref") or ""))


def _key(point: Point) -> Key:
    return (round(point[0], 6), round(point[1], 6))


class Network:
    """A relation's ways as an undirected road network."""

    def __init__(self, lines: Sequence[Sequence[Point]]) -> None:
        self.edges: dict[Key, list[tuple[Key, float]]] = defaultdict(list)
        self.points: dict[Key, Point] = {}
        ends: list[Key] = []
        for line in lines:
            keys = [_key(point) for point in line]
            for point, key in zip(line, keys, strict=True):
                self.points[key] = point
            for (a, ka), (b, kb) in pairwise(zip(line, keys, strict=True)):
                self._join(ka, kb, metres(a, b))
            if keys:
                ends += [keys[0], keys[-1]]
        ends = list(dict.fromkeys(ends))
        for i, a in enumerate(ends):
            for b in ends[i + 1 :]:
                gap = metres(self.points[a], self.points[b])
                if 0 < gap <= BRIDGE_M:
                    self._join(a, b, gap * 3)

    def _join(self, a: Key, b: Key, weight: float) -> None:
        self.edges[a].append((b, weight))
        self.edges[b].append((a, weight))

    def nearest(self, point: Point) -> tuple[Key, float]:
        away, key = min((metres(point, p), key) for key, p in self.points.items())
        return key, away

    def _search(self, source: Key) -> tuple[dict[Key, float], dict[Key, Key]]:
        best = {source: 0.0}
        came: dict[Key, Key] = {}
        queue = [(0.0, source)]
        while queue:
            cost, key = heapq.heappop(queue)
            if cost > best.get(key, float("inf")):
                continue
            for other, weight in self.edges[key]:
                new = cost + weight
                if new < best.get(other, float("inf")):
                    best[other] = new
                    came[other] = key
                    heapq.heappush(queue, (new, other))
        return best, came

    def road(self, source: Key, target: Key) -> list[Point] | None:
        """The shortest road between two network points, if they connect."""
        best, came = self._search(source)
        if target not in best or source == target:
            return None
        keys = [target]
        while keys[-1] != source:
            keys.append(came[keys[-1]])
        return [self.points[key] for key in reversed(keys)]

    def furthest(self, source: Key) -> Key:
        best, _ = self._search(source)
        return max(best, key=best.__getitem__)


@dataclass(frozen=True)
class End:
    name: str
    town: Town | None
    key: Key

    @property
    def names(self) -> dict[str, str]:
        return names_of(self.town, self.name)


def _ends(network: Network, towns: Towns, options: list[str]) -> list[End]:
    """Each option that is a town near the route, at the network point nearest it."""
    found = []
    for option in options:
        best = None
        for _, town in towns.matches(option):
            key, away = network.nearest(town.point)
            if away <= TOWN_WITHIN_M and (best is None or away < best[0]):
                best = (away, town, key)
        if best:
            found.append(End(option, towns.use(best[1]), best[2]))
    return found


def _stops(relation: dict, road: list[Point]) -> list[list[float]]:
    """The route's own stop nodes in order along a road (the app has their names)."""
    found: list[tuple[float, Point]] = []
    for member in relation.get("members", []):
        role = member.get("role", "")
        if member["type"] != "node" or not role.startswith(("stop", "platform")):
            continue
        point = (member["lat"], member["lon"])
        along, away = project(road, point)
        if away <= STOP_WITHIN_M:
            found.append((along, point))
    found.sort(key=lambda stop: stop[0])
    kept: list[tuple[float, Point]] = []
    for stop in found:
        # A stop and its platform are one stop.
        if not kept or stop[0] - kept[-1][0] >= 30:
            kept.append(stop)
    return [[round(p[0], 5), round(p[1], 5)] for _, p in kept]


def _guess(
    router: Router | None, start: Point, vias: list[Point], end: Point
) -> list[Point] | None:
    """The road from start to end through vias, guessed, or None."""
    if router is None:
        return None
    road = router([start, *vias, end])
    return simplify(road, 10.0) if road and len(road) > 1 else None


def _directions_to(
    network: Network,
    relation: dict,
    origins: list[End],
    destinations: list[End],
    router: Router | None = None,
    vias: Sequence[Point] = (),
) -> list[dict]:
    """A direction to each destination, from the origin furthest along the roads.

    Where the mapped road stops short of a town, the rest is guessed, through
    the via towns that are off the mapped road, each on the side it is nearer.
    """
    directions = []
    for destination in destinations:
        roads = []
        for origin in origins:
            road = network.road(origin.key, destination.key)
            if road and length(road) >= SHORTEST_M:
                roads.append((length(road), road, origin))
        if not roads:
            continue
        _, road, origin = max(roads, key=lambda item: item[0])
        road = simplify(road, 10.0)
        # The two towns themselves: a route mapped only part of the way still
        # goes to its end town, past where its road stops.
        start = origin.town.point if origin.town else road[0]
        end = destination.town.point if destination.town else road[-1]
        off = [via for via in vias if project(road, via)[1] > VIA_OFF_M]
        direction = {
            "board": destination.names,
            "origin": origin.names,
            "path": encode_polyline(road),
            "stops": _stops(relation, road),
            "ends": [
                [round(start[0], 5), round(start[1], 5)],
                [round(end[0], 5), round(end[1], 5)],
            ],
        }
        if metres(road[0], start) > FILL_M:
            near_start = sorted(
                (v for v in off if metres(v, start) < metres(v, end)),
                key=lambda v: metres(v, start),
            )
            before = _guess(router, start, near_start, road[0])
            if before:
                direction["before"] = encode_polyline(before)
        if metres(road[-1], end) > FILL_M:
            near_end = sorted(
                (v for v in off if metres(v, end) <= metres(v, start)),
                key=lambda v: metres(v, road[-1]),
            )
            after = _guess(router, road[-1], near_end, end)
            if after:
                direction["after"] = encode_polyline(after)
        directions.append(direction)
    return directions


def _via_points(towns: Towns, names: list[str], route_towns: list[Point]) -> list[Point]:
    """The via towns' points: each the town of that name nearest the route's towns."""
    points = []
    for name in names:
        best = None
        for _, town in towns.matches(name):
            away = min((metres(town.point, p) for p in route_towns), default=float("inf"))
            if away <= VIA_WITHIN_M and (best is None or away < best[0]):
                best = (away, town)
        if best:
            points.append(best[1].point)
    return points


def routes_from(relation: dict, towns: Towns, router: Router | None = None) -> list[dict] | str:
    """The route data for one relation (one route per number it carries), or why not.

    router guesses the rest of a partly mapped route's road; without one, a
    route keeps only its mapped part.
    """
    tags = relation.get("tags", {})
    numbers = [n for n in _NUMBERS.split(tags.get("ref", "").strip()) if n]
    if not numbers:
        return "no number"
    lines = [
        [(p["lat"], p["lon"]) for p in member.get("geometry", [])]
        for member in relation.get("members", [])
        if member["type"] == "way" and not member.get("role", "").startswith("platform")
    ]
    network = Network(lines)
    if not network.points:
        return "no roads"
    starts, ends = ends_from(tags)
    if not starts or not ends:
        return "no end towns in its name or tags"
    start_ends, end_ends = _ends(network, towns, starts), _ends(network, towns, ends)
    if not start_ends and not end_ends:
        return "neither end is a town near its roads"
    # An end that isn't a town: the far end of the roads from the other one.
    if not start_ends:
        start_ends = [End(starts[0], None, network.furthest(end_ends[0].key))]
    if not end_ends:
        end_ends = [End(ends[0], None, network.furthest(start_ends[0].key))]
    route_towns = [e.town.point for e in start_ends + end_ends if e.town]
    vias = _via_points(towns, vias_from(tags), route_towns)
    directions = _directions_to(network, relation, start_ends, end_ends, router, vias)
    one_way = tags.get("public_transport:version") == "2" or bool(
        tags.get("from") and tags.get("to")
    )
    if not one_way:
        directions += _directions_to(network, relation, end_ends, start_ends, router, vias)
    if not directions:
        return "no road between its ends"
    return [
        {
            "id": f"osm:{relation['id']}" + (f":{number}" if len(numbers) > 1 else ""),
            "number": number,
            "directions": directions,
        }
        for number in numbers
    ]


def build(
    payload: dict, towns: Towns, router: Router | None = None
) -> tuple[list[dict], list[str]]:
    """All usable numbered routes in an Overpass answer, and a line for each one left out."""
    routes: list[dict] = []
    notes: list[str] = []
    for element in payload.get("elements", []):
        if element.get("type") != "relation":
            continue
        built = routes_from(element, towns, router)
        if isinstance(built, str):
            name = element.get("tags", {}).get("name", "?")
            notes.append(f"osm {element['id']} ({name}): left out, {built}")
        else:
            routes += built
    return routes, notes
