import datetime
import io
import zipfile

from lmt_gtfs import SATURDAY, SUNDAY, WEEKDAYS, build, clock, day_kind
from towns import Towns

STOPS = {"S1": (6.900, 79.850), "S2": (6.910, 79.850), "S3": (6.920, 79.850), "S4": (6.930, 79.850)}
NAMES = {"S1": "One", "S2": "Two", "S3": "Three", "S4": "Four"}

TOWNS = Towns.from_overpass(
    {
        "elements": [
            {
                "type": "node",
                "id": 1,
                "lat": 6.899,
                "lon": 79.850,
                "tags": {"place": "suburb", "name": "Alpha"},
            },
            {
                "type": "node",
                "id": 2,
                "lat": 6.931,
                "lon": 79.850,
                "tags": {"place": "suburb", "name": "Beta", "name:ta": "ப"},
            },
        ]
    }
)


def csv_text(header, rows):
    return "\n".join([",".join(header), *(",".join(map(str, row)) for row in rows)]) + "\n"


def feed(trips, times, shapes=None):
    """A small GTFS zip: one route, four stops in a line, a day per service."""
    shapes = shapes or {"SH0": list(STOPS.values()), "SH1": list(STOPS.values())}
    files = {
        "routes.txt": csv_text(["route_id", "route_short_name"], [["R1", "CM99"]]),
        "stops.txt": csv_text(
            ["stop_id", "stop_name", "stop_lat", "stop_lon"],
            [[s, NAMES[s], *p] for s, p in STOPS.items()],
        ),
        "shapes.txt": csv_text(
            ["shape_id", "shape_pt_lat", "shape_pt_lon", "shape_pt_sequence"],
            [[sid, p[0], p[1], i] for sid, pts in shapes.items() for i, p in enumerate(pts)],
        ),
        "calendar.txt": csv_text(
            ["service_id", *_DAYS, "start_date", "end_date"],
            [
                ["WED", *_only(2), "20261104", "20261104"],
                ["THU", *_only(3), "20261105", "20261105"],
                ["SUN", *_only(6), "20261101", "20261101"],
            ],
        ),
        "trips.txt": csv_text(
            ["trip_id", "route_id", "service_id", "trip_headsign", "direction_id", "shape_id"],
            trips,
        ),
        "stop_times.txt": csv_text(
            ["trip_id", "arrival_time", "departure_time", "stop_id", "stop_sequence"],
            [[t, "", at, s, i] for t, stops in times.items() for i, (s, at) in enumerate(stops)],
        ),
    }
    out = io.BytesIO()
    with zipfile.ZipFile(out, "w") as archive:
        for name, text in files.items():
            archive.writestr(name, text)
    return out.getvalue()


_DAYS = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]


def _only(day):
    return ["1" if i == day else "0" for i in range(7)]


TRIPS = [
    ["a", "R1", "WED", "Beta", "0", "SH0"],
    ["b", "R1", "WED", "Beta", "0", "SH0"],
    ["c", "R1", "WED", "Beta", "0", "SH0"],
    ["d", "R1", "THU", "Beta", "0", "SH0"],
    ["e", "R1", "SUN", "Beta", "0", "SH0"],
    # The other way, given a shape drawn the wrong way round.
    ["f", "R1", "WED", "Alpha", "1", "SH1"],
]
TIMES = {
    # Two pieces of one run, seen at different stops.
    "a": [("S1", "07:00:00"), ("S2", "07:10:00")],
    "b": [("S2", "07:11:00"), ("S3", "07:20:00"), ("S4", "07:31:00")],
    "c": [("S1", "08:00:00"), ("S2", "08:10:00"), ("S3", "08:20:00"), ("S4", "08:30:00")],
    # Thursday is under way: one trip so far, so Wednesday stands for weekdays.
    "d": [("S1", "09:00:00"), ("S2", "09:10:00")],
    "e": [("S1", "10:00:00"), ("S4", "10:31:00")],
    "f": [("S4", "07:00:00"), ("S3", "07:10:00"), ("S2", "07:20:00"), ("S1", "07:30:00")],
}


def test_clock_and_day_kinds():
    assert clock("07:05:31") == 426
    assert clock("25:10:00") == 1510
    assert clock("") is None
    assert day_kind(datetime.date(2026, 11, 4)) == WEEKDAYS
    assert day_kind(datetime.date(2026, 11, 7)) == SATURDAY
    assert day_kind(datetime.date(2026, 11, 8)) == SUNDAY


def test_a_route_with_a_direction_each_way():
    routes, notes = build(feed(TRIPS, TIMES), TOWNS)
    assert notes == []
    (route,) = routes
    assert (route["id"], route["number"]) == ("lmt:CM99", "CM99")
    to_beta, to_alpha = route["directions"]
    assert to_beta["board"] == {"en": "Beta", "ta": "ப"}
    assert to_beta["origin"] == {"en": "Alpha"}
    assert to_alpha["board"] == {"en": "Alpha"}
    # Minutes from the first stop chain the median time between stops.
    assert to_beta["stops"] == [
        [6.9, 79.85, "One", 0],
        [6.91, 79.85, "Two", 10],
        [6.92, 79.85, "Three", 20],
        [6.93, 79.85, "Four", 30],
    ]
    # Pieces of one run count once; the busier weekday stands for all.
    assert to_beta["times"] == [
        {"days": WEEKDAYS, "departs": [420, 480]},
        {"days": SUNDAY, "departs": [600]},
    ]
    # The shape drawn the wrong way round is turned to how the buses run.
    assert [stop[2] for stop in to_alpha["stops"]] == ["Four", "Three", "Two", "One"]
    assert to_alpha["times"] == [{"days": WEEKDAYS, "departs": [420]}]


def test_a_direction_without_a_shape_is_left_out():
    routes, notes = build(feed(TRIPS, TIMES, shapes={"SH0": list(STOPS.values())}), TOWNS)
    assert [len(r["directions"]) for r in routes] == [1]
    assert notes == ["lmt CM99 direction 1: left out, no usable trips"]
