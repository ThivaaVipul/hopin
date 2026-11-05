import json

from geometry import decode_polyline, encode_polyline, metres
from osm_routes import build, ends_from, osrm_router, routes_from, vias_from
from towns import Towns

# Two made-up towns about 3.3 km apart, south of Colombo Fort.
ALPHA = (6.900, 79.850)
BETA = (6.930, 79.850)

TOWNS_JSON = {
    "elements": [
        {
            "type": "node",
            "id": 1,
            "lat": ALPHA[0],
            "lon": ALPHA[1],
            "tags": {"place": "town", "name": "Alpha", "name:ta": "அ"},
        },
        {
            "type": "node",
            "id": 2,
            "lat": BETA[0],
            "lon": BETA[1],
            "tags": {"place": "town", "name": "Beta"},
        },
    ]
}
TOWNS = Towns.from_overpass(TOWNS_JSON)


def way(*points):
    return {
        "type": "way",
        "role": "",
        "geometry": [{"lat": lat, "lon": lng} for lat, lng in points],
    }


def relation(tags, members, id_=10):
    return {"type": "relation", "id": id_, "tags": tags, "members": members}


# Ways out of order and the middle one drawn backwards, as mappers leave them.
WAYS = [
    way((6.910, 79.850), (6.920, 79.850)),
    way((6.900, 79.850), (6.905, 79.850), (6.910, 79.850)),
    way((6.930, 79.850), (6.925, 79.850), (6.920, 79.850)),
]
PLATFORMS = [
    {"type": "node", "role": "platform", "lat": 6.9151, "lon": 79.8501},
    {"type": "node", "role": "stop", "lat": 6.9152, "lon": 79.8500},  # the same stop
    {"type": "node", "role": "platform", "lat": 6.9050, "lon": 79.8502},
]


def test_ends_come_from_tags_or_the_name():
    assert ends_from({"from": "Alpha", "to": "Beta", "name": "x"}) == (["Alpha"], ["Beta"])
    assert ends_from({"name": "Bus 138: Alpha => Beta"}) == (["Alpha"], ["Beta"])
    assert ends_from({"name": "Alpha-Beta via Gamma"}) == (["Alpha"], ["Beta"])
    assert ends_from({"name": "Alpha/Gamma - Beta (night)"}) == (["Alpha", "Gamma"], ["Beta"])
    assert ends_from({"name": "Alpha Beta"}) == ([], [])


def test_a_relation_for_both_ways_gives_a_direction_each_way():
    routes = routes_from(relation({"ref": "101", "name": "Alpha - Beta"}, WAYS + PLATFORMS), TOWNS)
    assert [r["number"] for r in routes] == ["101"]
    to_beta, to_alpha = routes[0]["directions"]
    assert to_beta["board"] == {"en": "Beta"}
    assert to_beta["origin"] == {"en": "Alpha", "ta": "அ"}
    path = decode_polyline(to_beta["path"])
    assert metres(path[0], ALPHA) < 10 and metres(path[-1], BETA) < 10
    # Stops in order along the road, a stop and its platform counted once.
    assert to_beta["stops"] == [[6.905, 79.8502], [6.9151, 79.8501]]
    assert to_alpha["board"]["en"] == "Alpha"
    assert decode_polyline(to_alpha["path"])[0] == path[-1]
    # Going the other way, the stop's pin comes before its platform.
    assert to_alpha["stops"] == [[6.9152, 79.85], [6.905, 79.8502]]


def test_a_one_way_relation_gives_one_direction():
    tags = {"ref": "101", "from": "Alpha", "to": "Beta", "public_transport:version": "2"}
    routes = routes_from(relation(tags, WAYS), TOWNS)
    assert [d["board"]["en"] for d in routes[0]["directions"]] == ["Beta"]


def test_an_end_that_is_no_town_is_the_far_end_of_the_roads():
    routes = routes_from(relation({"ref": "7", "name": "Alpha - Depot Junction"}, WAYS), TOWNS)
    to_depot = routes[0]["directions"][0]
    assert to_depot["board"] == {"en": "Depot Junction"}
    assert metres(decode_polyline(to_depot["path"])[-1], BETA) < 10


def test_a_partly_mapped_route_keeps_the_part_that_is_mapped():
    tags = {"ref": "9", "name": "Alpha - Beta"}
    routes = routes_from(relation(tags, WAYS[1:2] + WAYS[0:1]), TOWNS)
    direction = routes[0]["directions"][0]
    path = decode_polyline(direction["path"])
    assert direction["board"]["en"] == "Beta"
    assert metres(path[-1], (6.920, 79.850)) < 10
    # Its end town, a kilometre past where the mapped road stops.
    assert direction["ends"] == [list(ALPHA), list(BETA)]


def test_an_end_that_is_no_town_ends_where_the_road_does():
    routes = routes_from(relation({"ref": "7", "name": "Alpha - Depot Junction"}, WAYS), TOWNS)
    ends = routes[0]["directions"][0]["ends"]
    assert ends[0] == list(ALPHA)
    assert metres(tuple(ends[1]), BETA) < 10


def test_via_towns_come_from_the_name():
    assert vias_from({"name": "Alpha-Beta via Gamma"}) == ["Gamma"]
    assert vias_from({"name": "Alpha - Beta via Gamma, Delta (night)"}) == ["Gamma", "Delta"]
    assert vias_from({"name": "Alpha - Beta"}) == []


def test_the_rest_of_a_partly_mapped_road_is_guessed_through_its_via_town():
    gamma = (6.925, 79.862)  # off the mapped road, near Beta
    towns = Towns.from_overpass(
        {
            "elements": [
                *TOWNS_JSON["elements"],
                {
                    "type": "node",
                    "id": 3,
                    "lat": gamma[0],
                    "lon": gamma[1],
                    "tags": {"place": "village", "name": "Gamma"},
                },
            ]
        }
    )
    asked = []

    def router(points):
        asked.append(points)
        return list(points)

    tags = {"ref": "9", "name": "Alpha - Beta via Gamma"}
    routes = routes_from(relation(tags, WAYS[1:2] + WAYS[0:1]), towns, router)
    to_beta, to_alpha = routes[0]["directions"]
    # The mapped road stops at 6.92; Beta is at 6.93, through Gamma.
    after = decode_polyline(to_beta["after"])
    assert metres(after[0], (6.920, 79.850)) < 10 and after[-1] == BETA
    assert gamma in asked[0]
    assert "before" not in to_beta
    # The other way: guessed from Beta to where the mapped road starts.
    before = decode_polyline(to_alpha["before"])
    assert before[0] == BETA and metres(before[-1], (6.920, 79.850)) < 10
    assert "after" not in to_alpha


def test_no_guess_without_a_router_or_an_answer():
    partial = relation({"ref": "9", "name": "Alpha - Beta"}, WAYS[1:2] + WAYS[0:1])
    (direction, _) = routes_from(partial, TOWNS)[0]["directions"]
    assert "after" not in direction
    (direction, _) = routes_from(partial, TOWNS, lambda points: None)[0]["directions"]
    assert "after" not in direction
    # A fully mapped road needs no guess.
    (direction, _) = routes_from(
        relation({"ref": "9", "name": "Alpha - Beta"}, WAYS), TOWNS, lambda p: list(p)
    )[0]["directions"]
    assert "after" not in direction and "before" not in direction


def osrm_answer(road, *steps):
    route = {"geometry": encode_polyline(road), "legs": [{"steps": list(steps)}]}
    return json.dumps({"code": "Ok", "routes": [route]}).encode()


def test_osrm_guesses_a_road_through_the_points():
    asked = []

    def fetch(url):
        asked.append(url)
        return osrm_answer([ALPHA, BETA], {"name": "Main Street", "ref": "A2"})

    assert osrm_router(fetch, pause=0)([ALPHA, BETA]) == [ALPHA, BETA]
    assert "/79.85000,6.90000;79.85000,6.93000?" in asked[0]
    assert "steps=true" in asked[0]


def test_no_osrm_guess_on_an_expressway_or_without_a_road():
    # A bus (bar an expressway bus) keeps off expressways; OSRM can't be told to.
    for step in ({"name": "Southern Expressway"}, {"name": "", "ref": "E01"}):
        route = osrm_router(lambda url, step=step: osrm_answer([ALPHA, BETA], step), pause=0)
        assert route([ALPHA, BETA]) is None
    assert osrm_router(lambda url: b'{"code": "NoRoute"}', pause=0)([ALPHA, BETA]) is None

    def offline(url):
        raise OSError("no network")

    assert osrm_router(offline, pause=0)([ALPHA, BETA]) is None


def test_each_number_of_a_shared_relation_is_a_route():
    routes = routes_from(relation({"ref": "101; 102", "name": "Alpha - Beta"}, WAYS), TOWNS)
    assert [(r["id"], r["number"]) for r in routes] == [
        ("osm:10:101", "101"),
        ("osm:10:102", "102"),
    ]


def test_relations_left_out_say_why():
    routes, notes = build(
        {
            "elements": [
                relation({"name": "Alpha - Beta"}, WAYS, 1),
                relation({"ref": "5", "name": "Gamma - Delta"}, WAYS, 2),
                relation({"ref": "6", "name": "Alpha - Beta"}, WAYS, 3),
            ]
        },
        TOWNS,
    )
    assert [r["id"] for r in routes] == ["osm:3"]
    assert notes == [
        "osm 1 (Alpha - Beta): left out, no number",
        "osm 2 (Gamma - Delta): left out, neither end is a town near its roads",
    ]
