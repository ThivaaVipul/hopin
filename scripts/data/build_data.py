"""Builds the route data files the app downloads (docs/PLAN.md, Which bus).

Run from the repo root: `python scripts/data/build_data.py --out <folder>`.
It fetches Sri Lanka's towns and bus stands from OpenStreetMap, then writes
one file per source, for the whole island:

  osm-routes.json  OpenStreetMap's numbered bus routes (ODbL)
  ntc-routes.json  NTC's long-distance timetables (the text sheets)
  lmt-routes.json  LMT's Metro routes and their recent timetables

Every file has the same shape: {"format", "source", "built", "credit",
"routes": [{"id", "number", "directions": [...]}]}. An NTC route also has
"classes", "long" and, for a sheet of several routes, "also" (the other
numbers its trips may carry). A direction has "board"
(the end town's names: "ta", "si", "en", whichever are known) and "origin",
and as its source allows: "path" (Google's encoded polyline, precision 5),
"before" and "after" (an OpenStreetMap route's road guessed by OSRM where
the mapped "path" stops short of its towns),
"stops" ([lat, lng] or [lat, lng, name, minutes from the first stop]),
"ends" (NTC: the two towns' points), "stand" (NTC: [lat, lng, name] of a bus
stand at the start) and "times" ([{"days": a 7-bit mask with Monday as bit 0,
"departs": minutes after midnight}]).

A source that fails, or finds no routes, writes nothing, so its last good file
stays on the release; the run still writes the others and then exits 1.
The weekly workflow (.github/workflows/data.yml) uploads the files to the
repo's `data` release.
"""

from __future__ import annotations

import argparse
import datetime
import json
import sys
import time
from collections.abc import Callable
from pathlib import Path

import lmt_gtfs
import net
import ntc_sheets
import osm_routes
import towns as towns_module
from towns import Towns

FORMAT = 1
SOURCES = ("osm", "ntc", "lmt")
CREDITS = {
    "osm": osm_routes.CREDIT,
    "ntc": ntc_sheets.CREDIT,
    "lmt": lmt_gtfs.CREDIT,
}
NAMES_CREDIT = "Town names from OpenStreetMap and Wikidata"


def _ntc(towns: Towns) -> tuple[list[dict], list[str]]:
    files = ntc_sheets.crawl(lambda url: net.get(url).decode("utf-8", "replace"))

    def download(url: str) -> bytes:
        time.sleep(1)  # gentle with Drive
        return net.get(url)

    # The sheets' directions are read by the end towns' Sinhala names.
    return ntc_sheets.build(
        files, towns, download, before_reading=lambda: towns.fill_from_wikidata(net.get)
    )


BUILDERS: dict[str, Callable[[Towns], tuple[list[dict], list[str]]]] = {
    "osm": lambda towns: osm_routes.build(
        json.loads(net.overpass(osm_routes.QUERY)), towns, osm_routes.osrm_router(net.get)
    ),
    "ntc": _ntc,
    "lmt": lambda towns: lmt_gtfs.build(net.get(lmt_gtfs.GTFS), towns),
}


def summary(routes: list[dict]) -> str:
    directions = [d for route in routes for d in route["directions"]]
    boards = [d["board"] for d in directions]
    tamil = sum(1 for board in boards if "ta" in board)
    sinhala = sum(1 for board in boards if "si" in board)
    return (
        f"{len(routes)} routes, {len(directions)} directions; "
        f"boards with Tamil {tamil}, with Sinhala {sinhala}"
    )


def write(out: Path, source: str, routes: list[dict], built: str) -> Path:
    path = out / f"{source}-routes.json"
    payload = {
        "format": FORMAT,
        "source": source,
        "built": built,
        "credit": f"{CREDITS[source]}. {NAMES_CREDIT}.",
        "routes": routes,
    }
    path.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    return path


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out", type=Path, required=True, help="folder for the files")
    parser.add_argument("--only", default=",".join(SOURCES), help="sources to build, e.g. osm,lmt")
    args = parser.parse_args(argv)
    chosen = [source for source in args.only.split(",") if source]
    unknown = sorted(set(chosen) - set(SOURCES))
    if unknown:
        parser.error(f"unknown source: {', '.join(unknown)}")
    args.out.mkdir(parents=True, exist_ok=True)

    towns = Towns.from_overpass(json.loads(net.overpass(towns_module.QUERY)))
    print(f"towns: {len(towns.towns)} towns, {len(towns.stands)} bus stands")
    built: dict[str, list[dict]] = {}
    failed: list[str] = []
    for source in chosen:
        try:
            routes, notes = BUILDERS[source](towns)
            for note in notes:
                print(f"  {note}")
            if not routes:
                raise RuntimeError("no routes found")
            built[source] = routes
        except Exception as error:  # one source failing mustn't stop the others
            failed.append(source)
            print(f"{source}: failed: {error!r}")
    towns.fill_from_wikidata(net.get)
    print(f"wikidata: {towns.names_added} names added")
    stamp = datetime.datetime.now(datetime.UTC).strftime("%Y-%m-%dT%H:%M:%SZ")
    for source, routes in built.items():
        path = write(args.out, source, routes, stamp)
        print(f"{source}: {summary(routes)}; {path.stat().st_size // 1024} KB")
    if failed:
        print(f"failed: {', '.join(failed)}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
