"""NTC's long-distance timetables, from the text PDFs in its Drive folders.

docs/PLAN.md, Which bus: a sheet gives a route's number, its two end towns, its
class and each end's departures. Most sheets are two halves side by side, one
per direction, each a row of times per trip at the route's timing points (or
"arrive at the terminal" and "depart" columns). The column headers are Sinhala
whose letters partly come out of the PDF wrong, so a half's direction is found
by comparing the consonants of its first and last headers with the two end
towns' names. The end towns themselves come from the English file name.

Left out: scanned sheets (no text), special-day sheets and operators' time
cards, and any sheet whose halves can't be told apart. A route whose newest
sheet is a scan is left out too, rather than shown with old times.
"""

from __future__ import annotations

import difflib
import html
import re
from collections.abc import Callable
from dataclasses import dataclass, field

from towns import Town, Towns, names_of, spelling

FOLDERS = {
    "Normalway": "1IXszV0llAjHNvumrKR99U0yzGQ7_Rd2x",
    "Expressway": "1CU2zYTLomUcnElUnOoB0kdMtQjYK0oVH",
}
FOLDER_VIEW = "https://drive.google.com/embeddedfolderview?id={id}"
DOWNLOAD = "https://drive.google.com/uc?export=download&id={id}"

CREDIT = "Timetables from the National Transport Commission, Sri Lanka"

EVERY_DAY = 0b1111111
# How much better one way round must score than the other, and how well each
# of a half's end headers must match its town.
MARGIN = 0.4
MATCH = 0.6

_ENTRY = re.compile(
    r'<div class="flip-entry" id="entry-([A-Za-z0-9_-]+)".*?'
    r'<a href="([^"]+)".*?<div class="flip-entry-title">(.*?)</div>',
    re.S,
)


@dataclass(frozen=True)
class DriveFile:
    id: str
    name: str
    folder: str


def folder_entries(page: str) -> list[tuple[str, str, bool]]:
    """(id, name, is a folder) for each entry of Drive's embedded folder view."""
    found = []
    for entry_id, href, title in _ENTRY.findall(page):
        name = html.unescape(re.sub(r"<[^>]+>", "", title)).strip()
        found.append((entry_id, name, "/folders/" in href))
    return found


def crawl(fetch_text: Callable[[str], str]) -> list[DriveFile]:
    """Every PDF under the timetable folders."""
    files: list[DriveFile] = []
    queue = list(FOLDERS.items())
    seen: set[str] = set()
    while queue:
        path, folder_id = queue.pop(0)
        if folder_id in seen:
            continue
        seen.add(folder_id)
        for entry_id, name, is_folder in folder_entries(
            fetch_text(FOLDER_VIEW.format(id=folder_id))
        ):
            if is_folder:
                queue.append((f"{path}/{name}", entry_id))
            elif name.lower().endswith(".pdf"):
                files.append(DriveFile(entry_id, name, path))
    return files


# File names ------------------------------------------------------------------

# "15-87", "1-245", "138/2", "08" (also glued to a name: "08Colombo").
_NUMBER = re.compile(
    r"^\s*(\d+(?:[A-Za-z](?![A-Za-z]))?(?:\s*[-/]\s*\d+(?:[A-Za-z](?![A-Za-z]))?)*)"
)
_DATE = re.compile(r"(20\d\d)[._-](\d\d)[._-](\d\d)")
_ONE_END = re.compile(r"\(?\b([A-Za-z]+)\s+End\b\)?", re.I)
_CLASS_TOKEN = re.compile(r"\b(N|SL|L|AC)\b")
_CLASS_GROUP = re.compile(r"\b(?:N|SL|L|AC)(?:\s*[,/-]\s*(?:N|SL|L|AC))+\b")
_CLASS_ONLY = re.compile(r"\s*(?:N|SL|L|AC)(?:\s*[,/-]\s*(?:N|SL|L|AC))*\s*")
_WORDS = re.compile(
    r"\b(?:semi\s+luxury|luxury|normal|special[\s_]*day|day|panal|panel|new|imp|"
    r"implement|implementation|mid\s*night|card|ac|time\s*table)\b",
    re.I,
)


@dataclass(frozen=True)
class SheetName:
    number: str | None
    ends: tuple[str, str]
    classes: tuple[str, ...]
    dated: str | None = None
    special: bool = False
    card: bool = False
    one_end: str | None = None


def parse_name(filename: str, folder: str = "") -> SheetName | None:
    """What a sheet's file name says, or None when its two ends can't be read."""
    text = re.sub(r"\.pdf$", "", filename, flags=re.I).replace("_", " ")
    lower = text.lower()
    date = _DATE.search(text)
    dated = f"{date[1]}-{date[2]}-{date[3]}" if date else None
    text = _DATE.sub(" ", text)
    # Classes in brackets or a list ("(SL)", "N,SL,L") say it best; words
    # ("Luxury", "Normal") only when there are none; the folder last.
    classes: list[str] = []
    for bracket in re.findall(r"\(([^)]*)\)", text):
        if _CLASS_ONLY.fullmatch(bracket):
            classes += _CLASS_TOKEN.findall(bracket)
    for group in _CLASS_GROUP.findall(text):
        classes += _CLASS_TOKEN.findall(group)
    if not classes:
        if re.search(r"semi\s+luxury", lower):
            classes.append("SL")
        elif "luxury" in lower:
            classes.append("L")
        if re.search(r"\bnormal\b", lower):
            classes.append("N")
        if re.search(r"\bac\b", lower):
            classes.append("AC")
    if not classes:
        if folder.endswith("/Semi Luxury"):
            classes.append("SL")
        elif folder.endswith("/Luxury"):
            classes.append("L")
        elif folder.startswith("Expressway"):
            classes.append("EX")
    one_end_match = _ONE_END.search(text)
    one_end = one_end_match[1] if one_end_match else None
    text = _ONE_END.sub(" ", text)
    number_match = _NUMBER.match(text)
    number = re.sub(r"\s+", "", number_match[1]) if number_match else None
    if number_match:
        text = text[number_match.end() :]
    text = re.sub(r"\|\s*\d+", " ", text)
    text = re.sub(r"\([^)]*\)", " ", text)
    text = _CLASS_GROUP.sub(" ", text)
    text = _WORDS.sub(" ", text)
    text = _CLASS_TOKEN.sub(" ", text)
    parts = [part.strip(" ,.") for part in re.split(r"\s*-\s*", text) if part.strip(" ,.")]
    if len(parts) != 2 or any("," in part or not re.search("[A-Za-z]", part) for part in parts):
        return None
    return SheetName(
        number=number,
        ends=(parts[0], parts[1]),
        classes=tuple(dict.fromkeys(classes)),
        dated=dated,
        special="special" in lower,
        card="card" in lower,
        one_end=one_end,
    )


# Times and headers -------------------------------------------------------------

_TIME = re.compile(r"(\d{1,2})[:.](\d{2})")
_CID = re.compile(r"\(cid:\d+\)")
# Sinhala consonants and independent vowels: what survives the PDF's mix-ups.
_SINHALA_KEEP = re.compile("[^\u0d85-\u0d96\u0d9a-\u0dc6]")
# "Depart" (pitath), as consonants.
_DEPART = "\u0db4\u0da7\u0dad"


def minutes(cell: str | None) -> list[int] | None:
    """The times in a cell made only of times, as minutes after midnight; else None."""
    if not cell or not cell.strip():
        return None
    found = _TIME.findall(cell)
    if not found or _TIME.sub("", cell).strip():
        return None
    times = []
    for hours, mins in found:
        h, m = int(hours), int(mins)
        if h > 29 or m > 59:
            return None
        times.append((h % 24) * 60 + m)
    return times


def skeleton(text: str) -> str:
    """A Sinhala text's consonants, which the sheets' text keeps in order."""
    return _SINHALA_KEEP.sub("", _CID.sub("", text))


def _partial(wanted: str, text: str) -> float:
    if not wanted or not text:
        return 0.0
    if wanted in text:
        return 1.0
    best = difflib.SequenceMatcher(None, wanted, text).ratio()
    size = len(wanted)
    for width in (size - 1, size, size + 1):
        for start in range(0, len(text) - width + 1):
            window = text[start : start + width]
            best = max(best, difflib.SequenceMatcher(None, wanted, window).ratio())
    return best


def likeness(header: str, names: dict[str, str]) -> float:
    """How well a header names a town, by its Sinhala consonants or its English letters."""
    scores = [0.0]
    if names.get("si"):
        scores.append(_partial(skeleton(names["si"]), skeleton(header)))
    if names.get("en"):
        scores.append(_partial(spelling(names["en"]), spelling(header)))
    return max(scores)


@dataclass
class Half:
    """One direction of a sheet: its first and last headers and its departures."""

    first: str
    last: str
    departs: list[int] = field(default_factory=list)


def _clean(table: list[list[str | None]]) -> list[list[str]]:
    rows = [[(cell or "").replace("\n", " ").strip() for cell in row] for row in table]
    width = max((len(row) for row in rows), default=0)
    return [row + [""] * (width - len(row)) for row in rows]


def _first_data(rows: list[list[str]]) -> int | None:
    return next((i for i, row in enumerate(rows) if any(minutes(c) for c in row)), None)


def join_continued(tables: list[list[list[str | None]]]) -> list[list[list[str]]]:
    """Tables with no header of their own continue the table before them (next page)."""
    joined: list[list[list[str]]] = []
    for table in map(_clean, tables):
        if not table:
            continue
        if joined and _first_data(table) == 0 and len(table[0]) == len(joined[-1][0]):
            joined[-1] = joined[-1] + table
        else:
            joined.append(table)
    return joined


def halves(table: list[list[str]]) -> list[Half]:
    """A table's directions: each run of side-by-side time columns is one."""
    start = _first_data(table)
    if start is None:
        return []
    header, data = table[:start], table[start:]
    width = len(table[0])

    def is_times(column: int) -> bool:
        cells = [row[column] for row in data if row[column]]
        timed = sum(1 for cell in cells if minutes(cell))
        return timed >= 1 and timed >= 0.6 * len(cells)

    columns = [c for c in range(width) if is_times(c)]
    runs: list[list[int]] = []
    for column in columns:
        if runs and column == runs[-1][-1] + 1:
            runs[-1].append(column)
        else:
            runs.append([column])
    found = []
    for run in runs:
        heads = {c: " ".join(row[c] for row in header if row[c]) for c in run}
        found_half = Half(heads[run[0]], heads[run[-1]])
        depart = next((c for c in run if _DEPART in skeleton(heads[c])), None)
        if depart is None:
            # "Arrive at the terminal" and "depart" share the origin's name,
            # written once over both: the second column's top header is empty.
            top = next((row for row in header if any(row[c] for c in run)), None)
            paired = top is not None and len(run) > 2 and top[run[0]] and not top[run[1]]
            depart = run[1] if paired else run[0]
        # Only trips that run the whole way, first timing point to last: a
        # sheet of several routes has trips that start or end part way.
        whole = [row for row in data if minutes(row[run[0]]) and minutes(row[run[-1]])]
        found_half.departs = sorted({m for row in whole for m in (minutes(row[depart]) or [])})
        if found_half.departs:
            found.append(found_half)
    return found


def _same_headers(half: Half) -> tuple[str, str, str, str]:
    return (skeleton(half.first), spelling(half.first), skeleton(half.last), spelling(half.last))


def merge(parts: list[Half]) -> list[Half]:
    """Joins halves with the same headers: a sheet over several pages repeats them."""
    merged: dict[tuple[str, str, str, str], Half] = {}
    for half in parts:
        key = _same_headers(half)
        if key in merged:
            merged[key].departs = sorted(set(merged[key].departs) | set(half.departs))
        else:
            merged[key] = Half(half.first, half.last, list(half.departs))
    return list(merged.values())


def directions(
    parts: list[Half], ends: tuple[dict[str, str], dict[str, str]], one_end: int | None = None
) -> list[tuple[int, int, list[int]]] | str:
    """(from end, to end, departures) for each direction, or why the sheet can't be read.

    one_end is the end a one-direction sheet leaves from, when its name says so.
    """
    if not parts:
        return "no times"
    if one_end is not None:
        if len(parts) > 1:
            return "two directions in a one-end sheet"
        return [(one_end, 1 - one_end, parts[0].departs)]
    read = [_reading(half, ends) for half in parts]
    if len(parts) == 2:
        (a, clear_a), (b, clear_b) = read
        if clear_a and clear_b:
            if a == b:
                return "both halves read the same way"
        elif clear_a or clear_b:
            # The other half of the sheet runs the opposite way, as long as
            # its own headers lean that way at all.
            clear, other = (a, b) if clear_a else (b, a)
            if other == clear:
                kept = parts[0] if clear_a else parts[1]
                return [(clear, 1 - clear, kept.departs)]
            a, b = (clear, 1 - clear) if clear_a else (1 - clear, clear)
        else:
            return "directions unclear"
        return [(a, 1 - a, parts[0].departs), (b, 1 - b, parts[1].departs)]
    # One half, or a sheet in sections: each clear one joins its direction.
    joined: dict[int, set[int]] = {}
    for half, (origin, clear) in zip(parts, read, strict=True):
        if clear:
            joined.setdefault(origin, set()).update(half.departs)
    if not joined:
        return "direction unclear" if len(parts) == 1 else "directions unclear"
    return [(origin, 1 - origin, sorted(times)) for origin, times in sorted(joined.items())]


def _reading(half: Half, ends: tuple[dict[str, str], dict[str, str]]) -> tuple[int, bool]:
    """The end a half leaves from, and whether its headers say so clearly.

    Clearly: one way round scores well ahead of the other, and both its first
    and last headers match their towns (a half of another route on the same
    sheet starts or ends at a town that isn't one of the two).
    """
    scores = []
    for origin in (0, 1):
        first = likeness(half.first, ends[origin])
        last = likeness(half.last, ends[1 - origin])
        scores.append((first + last, min(first, last)))
    origin = 0 if scores[0][0] >= scores[1][0] else 1
    margin = abs(scores[0][0] - scores[1][0])
    return origin, margin >= MARGIN and scores[origin][1] >= MATCH


def read_pdf(data: bytes) -> tuple[str, list[list[list[str | None]]]] | None:
    """A PDF's text and tables, or None for a scan (no text at all)."""
    import io

    import pdfplumber  # the job's own dependency: scripts/data/requirements.txt

    with pdfplumber.open(io.BytesIO(data)) as pdf:
        text = "\n".join(page.extract_text() or "" for page in pdf.pages)
        if not text.strip():
            return None
        return text, [table for page in pdf.pages for table in page.extract_tables()]


# "Route No. EX1-22", or in Sinhala "route number" (anka, its short form, or
# ma.a.): "(maarga anka : EX 1-41)", "(ma.a. 49, 49/950)".
_NUMBER_TEXT = re.compile(
    r"(?:Route\s*No\.?|\u0d85\u0d82\u0d9a|\u0d85\u0d82|\u0db8\u0dcf\.\s*\u0d85\.)\s*[:\s-]*"
    r"([A-Z]{0,3}\s?\d[\w/-]*(?:\s*,\s*[A-Z]{0,3}\s?\d[\w/-]*)*)",
    re.I,
)


def numbers_in_text(text: str) -> list[str]:
    """The route numbers a sheet's title gives: several for a sheet of several routes."""
    match = _NUMBER_TEXT.search(text)
    if not match:
        return []
    return [re.sub(r"\s+", "", number) for number in match[1].split(",") if number.strip()]


# Weekday names (Friday, Monday, Sunday), as consonants: a sheet that names
# them gives different times on different days.
_WEEKDAY_NAMES = tuple(
    skeleton(day)
    for day in (
        "\u0dc3\u0dd2\u0d9a\u0dd4\u0dbb\u0dcf\u0daf\u0dcf",
        "\u0dc3\u0db3\u0dd4\u0daf\u0dcf",
        "\u0d89\u0dbb\u0dd2\u0daf\u0dcf",
    )
)


def by_weekday(text: str) -> bool:
    words = {skeleton(word) for word in text.split()}
    return sum(1 for day in _WEEKDAY_NAMES if any(day in word for word in words)) >= 2


# Building the routes ------------------------------------------------------------


def _key(sheet: SheetName) -> tuple:
    return (sheet.number, frozenset(spelling(end) for end in sheet.ends), sheet.classes)


def build(
    files: list[DriveFile],
    towns: Towns,
    download: Callable[[str], bytes],
    before_reading: Callable[[], object] | None = None,
) -> tuple[list[dict], list[str]]:
    """The routes from every readable sheet, and a line for each sheet left out.

    before_reading runs once the end towns are known and before any sheet is
    read: the build fills their names from Wikidata there, since a sheet's
    directions are read by its towns' Sinhala names.
    """
    notes: list[str] = []
    groups: dict[tuple, list[tuple[SheetName, DriveFile]]] = {}
    for file in files:
        sheet = parse_name(file.name, file.folder)
        if sheet is None:
            notes.append(f"ntc {file.name}: left out, ends not in the name")
        elif sheet.special or sheet.card:
            notes.append(f"ntc {file.name}: left out, special days or a time card")
        else:
            groups.setdefault(_key(sheet), []).append((sheet, file))
    chosen: list[tuple[SheetName, DriveFile, list[Town]]] = []
    for group in groups.values():
        # The newest revision wins (an undated sheet counts as the oldest).
        group.sort(key=lambda item: item[0].dated or "", reverse=True)
        sheet, file = group[0]
        end_towns = [towns.named(end) for end in sheet.ends]
        missing = [end for end, town in zip(sheet.ends, end_towns, strict=True) if town is None]
        if missing:
            notes.append(f"ntc {file.name}: left out, no town found for {missing[0]}")
        else:
            chosen.append((sheet, file, [town for town in end_towns if town]))
    if before_reading:
        before_reading()
    routes = []
    for sheet, file, end_towns in chosen:
        built = _route(sheet, file, end_towns, towns, download)
        if isinstance(built, str):
            notes.append(f"ntc {file.name}: left out, {built}")
        else:
            routes.append(built)
    return _one_each(routes), notes


def _one_each(routes: list[dict]) -> list[dict]:
    """One route where sheets in two folders give the same times, with both classes."""
    kept: dict[tuple, dict] = {}
    for route in routes:
        key = (
            _plain(route["number"]),
            tuple((d["board"].get("en"), str(d["times"])) for d in route["directions"]),
        )
        if key in kept:
            same = kept[key]
            same["classes"] = list(dict.fromkeys(same["classes"] + route["classes"]))
        else:
            kept[key] = route
    return list(kept.values())


def _route(
    sheet: SheetName,
    file: DriveFile,
    end_towns: list[Town],
    towns: Towns,
    download: Callable[[str], bytes],
) -> dict | str:
    data = download(DOWNLOAD.format(id=file.id))
    if not data.startswith(b"%PDF"):
        return "not a PDF"
    read = read_pdf(data)
    if read is None:
        return "a scan (its newest sheet)"
    text, raw = read
    if by_weekday(text):
        return "times by day of the week"
    numbers = numbers_in_text(text)
    number = sheet.number or (numbers[0] if numbers else None)
    if not number:
        return "no route number"
    # A sheet of several routes: the trips that run end to end may be any of them.
    also = [n for n in numbers if _plain(n) != _plain(number)]
    tables = join_continued(raw)
    end_names = (names_of(end_towns[0], sheet.ends[0]), names_of(end_towns[1], sheet.ends[1]))
    one_end = None
    if sheet.one_end:
        matches = [likeness(sheet.one_end, names) for names in end_names]
        one_end = 0 if matches[0] >= matches[1] else 1
    parts = merge([half for table in tables for half in halves(table)])
    found = directions(parts, end_names, one_end)
    if isinstance(found, str):
        return found
    result = []
    for origin, destination, departs in found:
        start, end = end_towns[origin], end_towns[destination]
        stand = towns.stand_near(start.point)
        direction = {
            "board": end_names[destination],
            "origin": end_names[origin],
            "ends": [
                [round(start.point[0], 5), round(start.point[1], 5)],
                [round(end.point[0], 5), round(end.point[1], 5)],
            ],
            "times": [{"days": EVERY_DAY, "departs": departs}],
        }
        if stand:
            direction["stand"] = [
                round(stand.point[0], 5),
                round(stand.point[1], 5),
                stand.name,
            ]
        result.append(direction)
    classes = "-".join(sheet.classes) or "x"
    route = {
        "id": f"ntc:{number}:{classes}",
        "number": number,
        "classes": list(sheet.classes),
        "long": True,
        "directions": result,
    }
    if also:
        route["also"] = also
    return route


def _plain(number: str) -> str:
    """A route number for comparing: "06" and "6", "15/87" and "15-87" are one."""
    return re.sub(r"(^|-)0+(?=\d)", r"\1", number.replace("/", "-"))
