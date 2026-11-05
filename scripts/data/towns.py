"""Towns and bus stands from OpenStreetMap, with their Tamil, Sinhala and English names.

A bus's board shows its route's end town, so every route end is matched to a
town here, for the board's three lines. OpenStreetMap has Tamil and Sinhala
names for every city but for only a part of the towns and few suburbs, so
Wikidata's labels fill in where a town links to it. A name nobody has stays
missing, and the app shows the others.
"""

from __future__ import annotations

import difflib
import json
import re
from collections.abc import Callable
from dataclasses import dataclass

from geometry import Point, metres

# Every place kind a route can end at, biggest first.
KINDS = ("city", "town", "suburb", "quarter", "village", "neighbourhood")
LANGUAGES = ("ta", "si", "en")

QUERY = (
    '[out:json][timeout:300];area["ISO3166-1"="LK"][admin_level=2]->.lk;('
    'nwr[place~"^(city|town|suburb|quarter|village|neighbourhood)$"](area.lk);'
    "nwr[amenity=bus_station](area.lk););out tags center;"
)

WIKIDATA = "https://www.wikidata.org/w/api.php"

_SINHALA = re.compile("[\u0d80-\u0dff]")
_TAMIL = re.compile("[\u0b80-\u0bff]")
_LATIN = re.compile("^[A-Za-z0-9 .,'()/&-]+$")


_SHORT_FORMS = (
    (re.compile(r"\bmt\b\.?"), "mount"),
    (re.compile(r"\b(?:jn|jct)\b\.?"), "junction"),
)


def spelling(text: str) -> str:
    """Letters only, lower case, short forms spelled out: how English names are compared."""
    text = text.lower()
    for short, full in _SHORT_FORMS:
        text = short.sub(full, text)
    return re.sub("[^a-z]", "", text)


def point_of(element: dict) -> Point | None:
    if "lat" in element and "lon" in element:
        return (element["lat"], element["lon"])
    center = element.get("center")
    if center:
        return (center["lat"], center["lon"])
    return None


@dataclass
class Town:
    id: str
    kind: str
    point: Point
    # The board's names by language ("ta", "si", "en"); only those known.
    names: dict[str, str]
    # English spellings to match route ends against, letters only.
    spellings: tuple[str, ...]
    wikidata: str | None = None


@dataclass(frozen=True)
class Stand:
    name: str | None
    point: Point


def town_from(element: dict) -> Town | None:
    tags = element.get("tags", {})
    kind = tags.get("place")
    point = point_of(element)
    if kind not in KINDS or point is None:
        return None
    names: dict[str, str] = {}
    for language in LANGUAGES:
        value = tags.get(f"name:{language}", "").strip()
        if value:
            names[language] = value
    default = tags.get("name", "").strip()
    if default:
        if _LATIN.match(default):
            names.setdefault("en", default)
        elif _SINHALA.search(default) and not _TAMIL.search(default):
            names.setdefault("si", default)
        elif _TAMIL.search(default) and not _SINHALA.search(default):
            names.setdefault("ta", default)
    english = [names.get("en", "")]
    for key in ("name", "alt_name", "old_name", "official_name"):
        english += [part for part in tags.get(key, "").split(";") if _LATIN.match(part.strip())]
    spellings = tuple(dict.fromkeys(s for s in map(spelling, english) if s))
    if not spellings and "en" not in names:
        return None
    return Town(
        id=f"{element['type'][0]}{element['id']}",
        kind=kind,
        point=point,
        names=names,
        spellings=spellings,
        wikidata=tags.get("wikidata"),
    )


def _likeness(wanted: str, candidate: str) -> float:
    if wanted == candidate:
        return 1.0
    # A short form of a longer name: "Trinco" for "Trincomalee".
    if len(wanted) >= 5 and candidate.startswith(wanted):
        return 0.9
    return difflib.SequenceMatcher(None, wanted, candidate).ratio()


class Towns:
    def __init__(self, towns: list[Town], stands: list[Stand]) -> None:
        self.towns = towns
        self.stands = stands
        # Towns a built route uses: only these get Wikidata's names.
        self.used: dict[str, Town] = {}
        self._asked: set[str] = set()
        self.names_added = 0

    @classmethod
    def from_overpass(cls, payload: dict) -> Towns:
        towns: list[Town] = []
        stands: list[Stand] = []
        for element in payload.get("elements", []):
            tags = element.get("tags", {})
            if tags.get("amenity") == "bus_station":
                point = point_of(element)
                if point:
                    stands.append(Stand(tags.get("name:en") or tags.get("name"), point))
            else:
                town = town_from(element)
                if town:
                    towns.append(town)
        return cls(towns, stands)

    def matches(self, name: str, cutoff: float = 0.8) -> list[tuple[float, Town]]:
        """Every town an English name could mean, allowing for spelling, best first.

        A name of several words that matches nothing is tried by its first word
        ("Moratuwa Campus").
        """
        wanted = spelling(name)
        if not wanted:
            return []
        found = []
        for town in self.towns:
            score = max((_likeness(wanted, s) for s in town.spellings), default=0.0)
            if score >= cutoff:
                found.append((round(score, 2), town))
        if not found:
            words = name.split()
            if len(words) > 1 and len(spelling(words[0])) >= 4:
                return self.matches(words[0], cutoff)
        found.sort(key=lambda item: (-item[0], KINDS.index(item[1].kind)))
        return found

    def named(
        self,
        name: str,
        near: Point | None = None,
        within_m: float | None = None,
        cutoff: float = 0.8,
    ) -> Town | None:
        """The town an English name means: near a point the nearest good match, else the biggest."""
        found = self.matches(name, cutoff)
        if near is not None:
            found = [
                (score, town)
                for score, town in found
                if within_m is None or metres(near, town.point) <= within_m
            ]
            found.sort(key=lambda item: (-item[0], metres(near, item[1].point)))
        return self._use(found[0][1]) if found else None

    def use(self, town: Town) -> Town:
        """Marks a town as used by a route, so Wikidata fills its names."""
        return self._use(town)

    def nearest(self, point: Point, within_m: float) -> Town | None:
        """The nearest town to point, preferring bigger places at a similar distance."""
        best = None
        for town in self.towns:
            away = metres(point, town.point)
            if away > within_m:
                continue
            # A town or suburb a little further off beats a nearby village.
            weight = away * (1.0 + 0.25 * KINDS.index(town.kind))
            if best is None or weight < best[0]:
                best = (weight, town)
        return self._use(best[1]) if best else None

    def stand_near(self, point: Point, within_m: float = 3000) -> Stand | None:
        """The nearest bus stand with a name, else the nearest without one."""
        near = sorted(
            ((metres(point, stand.point), stand) for stand in self.stands),
            key=lambda item: item[0],
        )
        near = [stand for away, stand in near if away <= within_m]
        return next((stand for stand in near if stand.name), near[0] if near else None)

    def _use(self, town: Town) -> Town:
        self.used[town.id] = town
        return town

    def fill_from_wikidata(self, fetch: Callable[[str], bytes], batch: int = 50) -> int:
        """Adds Wikidata's Tamil, Sinhala and English labels where the used towns lack them.

        fetch takes a URL and returns the body. Returns how many names were added;
        a town already asked about isn't asked again.
        """
        wanting = [
            town
            for town in self.used.values()
            if town.wikidata
            and town.id not in self._asked
            and any(lang not in town.names for lang in LANGUAGES)
        ]
        self._asked.update(town.id for town in wanting)
        added = 0
        for start in range(0, len(wanting), batch):
            group = wanting[start : start + batch]
            ids = "|".join(town.wikidata for town in group if town.wikidata)
            url = (
                f"{WIKIDATA}?action=wbgetentities&props=labels&languages=ta|si|en"
                f"&format=json&ids={ids}"
            )
            entities = json.loads(fetch(url)).get("entities", {})
            for town in group:
                labels = entities.get(town.wikidata or "", {}).get("labels", {})
                for language in LANGUAGES:
                    value = labels.get(language, {}).get("value")
                    if value and language not in town.names:
                        town.names[language] = value
                        added += 1
        self.names_added += added
        return added


def names_of(town: Town | None, fallback: str | None = None) -> dict[str, str]:
    """A board's names: the town's (one shared dict, so filling it later shows), else English."""
    if town is not None:
        if fallback and "en" not in town.names:
            town.names["en"] = fallback
        return town.names
    return {"en": fallback} if fallback else {}
