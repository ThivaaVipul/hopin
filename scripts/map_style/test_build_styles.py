from build_styles import OUT, PALETTES, recolor, write

STYLE = {
    "version": 8,
    "layers": [
        {"id": "background", "type": "background"},
        {"id": "water", "type": "fill", "source-layer": "water"},
        {"id": "waterway", "type": "line", "source-layer": "waterway"},
        {"id": "park", "type": "fill", "source-layer": "park"},
        {"id": "park_outline", "type": "line", "source-layer": "park"},
        {"id": "landuse_residential", "type": "fill", "source-layer": "landuse"},
        {"id": "building", "type": "fill", "source-layer": "building"},
        {"id": "highway_minor", "type": "line", "source-layer": "transportation"},
        {"id": "highway_major_casing", "type": "line", "source-layer": "transportation"},
        {"id": "highway_motorway_inner", "type": "line", "source-layer": "transportation"},
        {"id": "railway", "type": "line", "source-layer": "transportation"},
        {"id": "poi_r1", "type": "symbol", "source-layer": "poi"},
        {"id": "place_town", "type": "symbol", "source-layer": "place"},
        {"id": "place_country_major", "type": "symbol", "source-layer": "place"},
    ],
}


def layer(style: dict, layer_id: str) -> dict:
    return next(item for item in style["layers"] if item["id"] == layer_id)


def test_keeps_only_what_hopin_shows():
    ids = [item["id"] for item in recolor(STYLE, PALETTES["light"])["layers"]]
    assert ids == [
        "background",
        "water",
        "waterway",
        "park",
        "building",
        "highway_minor",
        "highway_major_casing",
        "highway_motorway_inner",
        "place_town",
    ]


def test_paints_the_board_palette():
    c = PALETTES["dark"]
    style = recolor(STYLE, c)
    assert layer(style, "background")["paint"]["background-color"] == c["land"]
    assert layer(style, "water")["paint"]["fill-color"] == c["water"]
    assert layer(style, "waterway")["paint"]["line-color"] == c["water"]
    assert layer(style, "park")["paint"]["fill-color"] == c["park"]
    assert layer(style, "highway_minor")["paint"]["line-color"] == c["minor"]
    assert layer(style, "highway_major_casing")["paint"]["line-color"] == c["casing"]
    assert layer(style, "highway_motorway_inner")["paint"]["line-color"] == c["major"]


def test_town_names_in_english_with_a_halo():
    c = PALETTES["light"]
    town = layer(recolor(STYLE, c), "place_town")
    assert town["layout"]["text-field"][1] == ["get", "name:en"]
    assert town["paint"]["text-color"] == c["label"]
    assert town["paint"]["text-halo-color"] == c["land"]


def test_leaves_the_source_style_alone():
    recolor(STYLE, PALETTES["light"])
    assert "paint" not in STYLE["layers"][0]


def test_writes_each_style_for_the_app_and_the_web_page(tmp_path):
    assert [str(path).replace("\\", "/") for path in OUT] == [
        "app/assets/map",
        "firebase/hosting/public/map",
    ]
    outs = [tmp_path / "app", tmp_path / "web"]
    style = recolor(STYLE, PALETTES["dark"])
    written = write(style, "dark", outs)
    assert [path.name for path in written] == ["board_dark.json", "board_dark.json"]
    assert written[0].read_text(encoding="utf-8") == written[1].read_text(encoding="utf-8")
