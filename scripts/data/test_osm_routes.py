from geometry import decode_polyline, metres
from osm_routes import build, ends_from, routes_from
from towns import Towns

# Two made-up towns about 3.3 km apart, south of Colombo Fort.
ALPHA = (6.900, 79.850)
BETA = (6.930, 79.850)

TOWNS = Towns.from_overpass(
    {
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
)


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
    path = decode_polyline(routes[0]["directions"][0]["path"])
    assert routes[0]["directions"][0]["board"]["en"] == "Beta"
    assert metres(path[-1], (6.920, 79.850)) < 10


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
