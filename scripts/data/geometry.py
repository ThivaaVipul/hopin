"""Distances, lines and Google's encoded polylines for the route data.

Points are (lat, lng) pairs in degrees. Distances are in metres, worked out on
a flat local projection, which is plenty for bus routes.
"""

from __future__ import annotations

import math
from collections.abc import Iterable, Sequence

Point = tuple[float, float]

EARTH_M = 6_371_000.0


def metres(a: Point, b: Point) -> float:
    """Great-circle distance between two points."""
    lat1, lng1, lat2, lng2 = map(math.radians, (*a, *b))
    h = (
        math.sin((lat2 - lat1) / 2) ** 2
        + math.cos(lat1) * math.cos(lat2) * math.sin((lng2 - lng1) / 2) ** 2
    )
    return 2 * EARTH_M * math.asin(min(1.0, math.sqrt(h)))


def length(path: Sequence[Point]) -> float:
    return sum(metres(a, b) for a, b in zip(path, path[1:], strict=False))


def _xy(origin: Point, point: Point) -> tuple[float, float]:
    """Metres east and north of origin."""
    scale = math.radians(1) * EARTH_M
    return (
        (point[1] - origin[1]) * scale * math.cos(math.radians(origin[0])),
        (point[0] - origin[0]) * scale,
    )


def fraction_along(a: Point, b: Point, point: Point) -> float:
    """Where point falls on the straight way from a to b: 0 at a, 1 at b,
    below 0 back from a and above 1 past b."""
    bx, by = _xy(a, b)
    px, py = _xy(a, point)
    span = bx * bx + by * by
    return 0.0 if span == 0 else (px * bx + py * by) / span


def _segment(p: tuple[float, float], a: tuple[float, float], b: tuple[float, float]):
    """Where p falls on segment a-b: (fraction along it, distance from it)."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    span = dx * dx + dy * dy
    t = 0.0 if span == 0 else max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / span))
    x, y = a[0] + t * dx, a[1] + t * dy
    return t, math.hypot(p[0] - x, p[1] - y)


def project(path: Sequence[Point], point: Point) -> tuple[float, float]:
    """The nearest point of path to point: (metres along the path, metres away)."""
    if not path:
        raise ValueError("empty path")
    if len(path) == 1:
        return 0.0, metres(path[0], point)
    best_along, best_away = 0.0, math.inf
    along = 0.0
    for a, b in zip(path, path[1:], strict=False):
        step = metres(a, b)
        t, away = _segment(_xy(a, point), (0.0, 0.0), _xy(a, b))
        if away < best_away:
            best_along, best_away = along + t * step, away
        along += step
    return best_along, best_away


def simplify(points: Sequence[Point], tolerance_m: float = 10.0) -> list[Point]:
    """Douglas-Peucker: drops points that sit within tolerance of the line."""
    if len(points) < 3:
        return list(points)
    keep = [False] * len(points)
    keep[0] = keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        first, last = stack.pop()
        origin = points[first]
        a, b = (0.0, 0.0), _xy(origin, points[last])
        worst, worst_at = 0.0, -1
        for i in range(first + 1, last):
            _, away = _segment(_xy(origin, points[i]), a, b)
            if away > worst:
                worst, worst_at = away, i
        if worst > tolerance_m:
            keep[worst_at] = True
            stack.append((first, worst_at))
            stack.append((worst_at, last))
    return [point for point, kept in zip(points, keep, strict=True) if kept]


def chain(lines: Sequence[Sequence[Point]], join_m: float = 30.0) -> list[list[Point]]:
    """Joins lines given in order (a route's ways) into as few runs as it can.

    Each line may run either way: it is turned round when its far end meets the
    run so far. A gap wider than join_m starts a new run.
    """
    runs: list[list[Point]] = []
    # The last run holds a single line, whose direction the next one decides.
    fresh = False
    for line in lines:
        if len(line) < 2:
            continue
        line = list(line)
        if runs:
            run = runs[-1]
            options = [
                (metres(run[-1], line[0]), False, False),
                (metres(run[-1], line[-1]), False, True),
            ]
            if fresh:
                options += [
                    (metres(run[0], line[0]), True, False),
                    (metres(run[0], line[-1]), True, True),
                ]
            gap, flip_run, flip_line = min(options)
            if gap <= join_m:
                if flip_run:
                    run.reverse()
                if flip_line:
                    line.reverse()
                run.extend(line[1:])
                fresh = False
                continue
        runs.append(line)
        fresh = True
    return runs


def encode_polyline(points: Iterable[Point]) -> str:
    """Google's encoded polyline, precision 5 (as the app's ride paths)."""
    out: list[str] = []
    last_lat = last_lng = 0
    for lat, lng in points:
        ilat, ilng = round(lat * 1e5), round(lng * 1e5)
        for delta in (ilat - last_lat, ilng - last_lng):
            value = ~(delta << 1) if delta < 0 else delta << 1
            while value >= 0x20:
                out.append(chr((0x20 | (value & 0x1F)) + 63))
                value >>= 5
            out.append(chr(value + 63))
        last_lat, last_lng = ilat, ilng
    return "".join(out)


def decode_polyline(text: str) -> list[Point]:
    points: list[Point] = []
    index = lat = lng = 0
    while index < len(text):
        deltas = []
        for _ in range(2):
            shift = result = 0
            while True:
                byte = ord(text[index]) - 63
                index += 1
                result |= (byte & 0x1F) << shift
                shift += 5
                if byte < 0x20:
                    break
            deltas.append(~(result >> 1) if result & 1 else result >> 1)
        lat += deltas[0]
        lng += deltas[1]
        points.append((lat / 1e5, lng / 1e5))
    return points
