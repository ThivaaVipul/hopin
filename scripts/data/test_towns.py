import json

from towns import Towns, names_of, spelling, town_from


def place(id_, kind, lat, lng, **tags):
    tags = {"place": kind, **{k.replace("_", ":"): v for k, v in tags.items()}}
    return {"type": "node", "id": id_, "lat": lat, "lon": lng, "tags": tags}


TOWNS = {
    "elements": [
        place(1, "city", 5.948, 80.535, name="Matara", name_si="මාතර"),
        place(2, "town", 6.046, 80.211, name="Galle", wikidata="Q1"),
        place(3, "village", 6.050, 80.215, name="Galle"),
        place(4, "city", 8.587, 81.215, name="Trincomalee"),
        place(5, "suburb", 6.773, 79.882, name="Moratuwa"),
        place(6, "village", 6.775, 79.885, name="කඩුව"),
        {
            "type": "way",
            "id": 7,
            "center": {"lat": 6.85, "lon": 79.87},
            "tags": {"place": "suburb", "name": "Mount Lavinia"},
        },
        {
            "type": "node",
            "id": 8,
            "lat": 5.949,
            "lon": 80.540,
            "tags": {"amenity": "bus_station", "name": "Matara Bus Stand"},
        },
    ]
}


def towns():
    return Towns.from_overpass(TOWNS)


def test_names_come_from_the_name_tags():
    matara = town_from(TOWNS["elements"][0])
    assert matara.names == {"si": "මාතර", "en": "Matara"}
    # A place named only in Sinhala has nothing to match an English route name.
    assert town_from(TOWNS["elements"][5]) is None
    assert town_from({"type": "node", "id": 9, "lat": 1, "lon": 2, "tags": {}}) is None


def test_spelling_ignores_case_and_marks_and_spells_out_short_forms():
    assert spelling("Mt. Lavinia") == "mountlavinia"
    assert spelling("Kandy Jn.") == "kandyjunction"
    assert spelling("Nuwara-Eliya") == "nuwaraeliya"


def test_named_allows_for_spelling_and_short_forms():
    t = towns()
    assert t.named("Mathara").names["en"] == "Matara"
    assert t.named("Trinco").names["en"] == "Trincomalee"
    assert t.named("Moratuwa Campus").names["en"] == "Moratuwa"
    assert t.named("Mt. Lavinia").names["en"] == "Mount Lavinia"
    assert t.named("Kandy") is None


def test_named_prefers_the_bigger_town_or_the_nearer_one():
    t = towns()
    assert t.named("Galle").kind == "town"
    assert t.named("Galle", near=(6.0505, 80.2155)).kind == "village"
    assert t.named("Galle", near=(7.5, 80.0), within_m=1000) is None


def test_nearest_and_stands():
    t = towns()
    assert t.nearest((5.95, 80.53), within_m=3000).names["en"] == "Matara"
    assert t.nearest((7.5, 80.0), within_m=3000) is None
    assert t.stand_near((5.948, 80.535)).name == "Matara Bus Stand"
    assert t.stand_near((6.046, 80.211)) is None
    # A named stand a little further off beats a nameless one.
    nameless = Towns.from_overpass(
        {
            "elements": [
                *TOWNS["elements"],
                {
                    "type": "node",
                    "id": 9,
                    "lat": 5.948,
                    "lon": 80.536,
                    "tags": {"amenity": "bus_station"},
                },
            ]
        }
    )
    assert nameless.stand_near((5.948, 80.535)).name == "Matara Bus Stand"
    assert nameless.stand_near((5.948, 80.536), within_m=50).name is None


def test_wikidata_fills_the_names_the_used_towns_lack():
    t = towns()
    galle = t.named("Galle")
    asked = []

    def fetch(url):
        asked.append(url)
        labels = {"ta": {"value": "காலி"}, "en": {"value": "Galle"}}
        return json.dumps({"entities": {"Q1": {"labels": labels}}}).encode()

    assert t.fill_from_wikidata(fetch) == 1
    assert galle.names == {"en": "Galle", "ta": "காலி"}
    assert len(asked) == 1 and "ids=Q1" in asked[0]
    # A town already asked about isn't asked again.
    assert t.fill_from_wikidata(fetch) == 0
    assert len(asked) == 1 and t.names_added == 1


def test_names_of_falls_back_to_the_given_name():
    assert names_of(None, "Bakery Junction") == {"en": "Bakery Junction"}
    assert names_of(None) == {}
