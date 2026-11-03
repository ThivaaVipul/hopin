"""Writes the app's Board map styles from OpenFreeMap's.

Run from the repo root: `python scripts/map_style/build_styles.py`. It fetches
OpenFreeMap's Positron (day) and Dark (night) styles, keeps only what Hopin
shows (land, water, parks, buildings, streets and town names), recolours them
to the Board palette (app/lib/app/theme.dart), and writes
app/assets/map/board_light.json and board_dark.json. Tiles, fonts and the
attribution still come from OpenFreeMap at run time.
"""

from __future__ import annotations

import copy
import json
import re
import urllib.request
from pathlib import Path

SOURCE = "https://tiles.openfreemap.org/styles/{name}"
AGENT = "hopin-map-style/1 (https://github.com/ThivaaVipul/hopin)"
OUT = Path("app/assets/map")

PALETTES: dict[str, dict[str, str]] = {
    "light": {
        "land": "#ECEFEA",
        "water": "#BCD0CE",
        "park": "#DCE5D8",
        "building": "#E1E5DF",
        "minor": "#FFFFFF",
        "major": "#F7F8F5",
        "casing": "#CDD5CF",
        "label": "#5B6660",
    },
    "dark": {
        "land": "#131D19",
        "water": "#0C2628",
        "park": "#16241D",
        "building": "#18231F",
        "minor": "#24312B",
        "major": "#2F3E36",
        "casing": "#1B2622",
        "label": "#7E8C85",
    },
}

_PARK = re.compile(r"park|wood|grass|forest|scrub")
_SKIP_ROAD = re.compile(r"rail|ferry|path|track|aeroway")
_MAJOR = re.compile(r"motorway|trunk|primary|major|secondary")
_WIDE_PLACES = re.compile(r"country|state|continent")


def recolor(style: dict, c: dict[str, str]) -> dict:
    """A copy of the style with only Hopin's layers, in the given palette."""
    out = copy.deepcopy(style)
    kept = []
    for layer in out["layers"]:
        layer_id = layer["id"]
        source_layer = layer.get("source-layer", "")
        kind = layer["type"]
        paint = layer.setdefault("paint", {})
        if kind == "background":
            paint["background-color"] = c["land"]
        elif kind == "symbol":
            # Town names only: the app draws its own markers and labels.
            if source_layer != "place" or _WIDE_PLACES.search(layer_id):
                continue
            layout = layer.setdefault("layout", {})
            layout["text-field"] = [
                "coalesce",
                ["get", "name:en"],
                ["get", "name:latin"],
                ["get", "name"],
            ]
            paint["text-color"] = c["label"]
            paint["text-halo-color"] = c["land"]
            paint["text-halo-width"] = 1.4
        elif source_layer in ("water", "waterway"):
            paint[f"{kind}-color"] = c["water"]
        elif source_layer == "park" or _PARK.search(layer_id):
            if kind != "fill":
                continue
            paint["fill-color"] = c["park"]
            paint["fill-opacity"] = 1
        elif source_layer in ("landuse", "landcover"):
            continue
        elif source_layer == "building":
            if kind != "fill":
                continue
            paint["fill-color"] = c["building"]
            paint["fill-outline-color"] = c["building"]
        elif source_layer == "transportation":
            if kind != "line" or _SKIP_ROAD.search(layer_id):
                continue
            if "casing" in layer_id:
                paint["line-color"] = c["casing"]
            elif _MAJOR.search(layer_id):
                paint["line-color"] = c["major"]
            else:
                paint["line-color"] = c["minor"]
        else:
            continue
        kept.append(layer)
    out["layers"] = kept
    out["name"] = "Hopin Board"
    return out


def fetch(name: str) -> dict:
    request = urllib.request.Request(SOURCE.format(name=name), headers={"User-Agent": AGENT})
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for mode, base in (("light", "positron"), ("dark", "dark")):
        style = recolor(fetch(base), PALETTES[mode])
        path = OUT / f"board_{mode}.json"
        path.write_text(json.dumps(style, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"{path}: {len(style['layers'])} layers")


if __name__ == "__main__":
    main()
