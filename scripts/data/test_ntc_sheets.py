import pytest

import ntc_sheets
from ntc_sheets import (
    DriveFile,
    Half,
    SheetName,
    build,
    by_weekday,
    corridor,
    directions,
    folder_entries,
    halves,
    join_continued,
    kept,
    likeness,
    merge,
    middle_towns,
    minutes,
    numbers_in_text,
    parse_name,
    skeleton,
)
from towns import Towns

COLOMBO_SI = "කොළඹ"  # as OSM has it
COLOMBO_SHEET = "ෙක(cid:12)ළඹ"  # as a sheet's text gives it
MATARA_SI = "මාතර"
DEPART_SI = "පිටත්වීම"
ARRIVE_SI = "පැමිණීම"

COLOMBO = {"en": "Colombo", "si": COLOMBO_SI}
MATARA = {"en": "Matara", "si": MATARA_SI}


@pytest.mark.parametrize(
    ("name", "expected"),
    [
        (
            "11-1 Embilipitiya - Matara (N).pdf",
            SheetName("11-1", ("Embilipitiya", "Matara"), ("N",)),
        ),
        (
            "08Colombo-Matale Luxury2026.01.20.pdf",
            SheetName("08", ("Colombo", "Matale"), ("L",), dated="2026-01-20"),
        ),
        (
            "06 Kurunagala - Colombo (R.N.06) AC Panal .pdf",
            SheetName("06", ("Kurunagala", "Colombo"), ("AC",)),
        ),
        (
            "2-3 Ambalangoda - Colombo (N-SL-AC).pdf",
            SheetName("2-3", ("Ambalangoda", "Colombo"), ("N", "SL", "AC")),
        ),
        (
            "01 Kandy-Colombo(L)Normal Day2025.04.06.pdf",
            SheetName("01", ("Kandy", "Colombo"), ("L",), dated="2025-04-06"),
        ),
        (
            "122 | 03 Embilipitiya - Colombo (Colombo End).pdf",
            SheetName("122", ("Embilipitiya", "Colombo"), (), one_end="Colombo"),
        ),
        (
            "4-11 Chilaw - Colombo Card New Imp 2025.10.10 Mid Night.pdf",
            SheetName("4-11", ("Chilaw", "Colombo"), (), dated="2025-10-10", card=True),
        ),
    ],
)
def test_file_names(name, expected):
    assert parse_name(name) == expected


def test_file_names_without_two_ends_or_number():
    assert parse_name("Galle - Negombo, Kandy.pdf") is None
    assert parse_name("92-4,92-5 Kuliyapitiya Panel.pdf") is None
    sheet = parse_name("Matara - Moratuwa Campus.pdf", "Expressway")
    assert sheet == SheetName(None, ("Matara", "Moratuwa Campus"), ("EX",))
    assert parse_name("1-1 Kegalle - Colombo.pdf", "Normalway/Semi Luxury").classes == ("SL",)
    assert parse_name("01 Kandy-Colombo(L)Special_day2026.02.13.pdf").special


def test_minutes():
    assert minutes("7:15") == [435]
    assert minutes(" 07.15 ") == [435]
    assert minutes("0:45") == [45]
    assert minutes("24:10") == [10]
    assert minutes("7:15\n7:45") == [435, 465]
    assert minutes("NB-5906") is None
    assert minutes("7:75") is None
    assert minutes("") is None


def test_sheet_headers_match_towns_by_their_consonants():
    assert skeleton(COLOMBO_SHEET) == skeleton(COLOMBO_SI)
    assert likeness(COLOMBO_SHEET, COLOMBO) == 1.0
    assert likeness(COLOMBO_SHEET, MATARA) < 0.5
    assert likeness("MATARA", MATARA) == 1.0
    assert likeness(f"{COLOMBO_SHEET} {ARRIVE_SI}", COLOMBO) == 1.0


def two_halves():
    """A sheet of timing points, two halves side by side, as most NTC sheets are."""
    return [
        [
            "NTC",
            "Bus",
            COLOMBO_SHEET,
            "x",
            MATARA_SI,
            "",
            "NTC",
            "Bus",
            MATARA_SI,
            "x",
            COLOMBO_SHEET,
        ],
        ["T1", "NB-1", "7:15", "8:50", "10:30", "", "T3", "NB-3", "6:15", "7:50", "9:30"],
        ["T2", "NB-2", "", "", "", "", "T4", "NB-4", "", "", ""],
        ["T5", "NB-5", "14:30", "16:05", "17:45", "", "T6", "NB-6", "11:50", "13:25", "15:05"],
    ]


def test_halves_of_a_timing_point_sheet():
    found = halves(join_continued([two_halves()])[0])
    assert [(h.first, h.last, h.departs) for h in found] == [
        (COLOMBO_SHEET, MATARA_SI, [435, 870]),
        (MATARA_SI, COLOMBO_SHEET, [375, 710]),
    ]


def test_an_arrive_and_depart_sheet_departs_from_the_second_column():
    table = [
        ["No", COLOMBO_SHEET, "", MATARA_SI, "No", MATARA_SI, "", COLOMBO_SHEET],
        ["", ARRIVE_SI, "x", "", "", ARRIVE_SI, "x", ""],
        ["C1", "3:00", "3:45", "7:45", "M1", "2:45", "3:15", "7:15"],
        ["C2", "3:45", "4:25", "8:25", "M2", "3:15", "3:55", "7:55"],
    ]
    found = halves(join_continued([table])[0])
    assert [h.departs for h in found] == [[225, 265], [195, 235]]
    # Or wherever the header says "depart".
    table[1][2] = DEPART_SI
    table[0][2] = "x"
    assert halves(join_continued([table])[0])[0].departs == [225, 265]


def test_pages_continue_and_repeat_their_headers():
    page_two = [
        ["T7", "NB-7", "20:00", "21:35", "23:15", "", "T8", "NB-8", "19:00", "20:35", "22:15"]
    ]
    joined = join_continued([two_halves(), page_two, two_halves()])
    assert len(joined) == 2
    merged = merge([h for table in joined for h in halves(table)])
    assert [h.departs for h in merged] == [[435, 870, 1200], [375, 710, 1140]]


def test_directions_from_the_headers():
    parts = [Half(COLOMBO_SHEET, MATARA_SI, [435]), Half(MATARA_SI, COLOMBO_SHEET, [375])]
    assert directions(parts, (MATARA, COLOMBO)) == [(1, 0, [435]), (0, 1, [375])]
    english = [Half("MATARA", "COLOMBO", [240]), Half("COLOMBO", "MATARA", [330])]
    assert directions(english, (COLOMBO, MATARA)) == [(1, 0, [240]), (0, 1, [330])]


def test_directions_left_unread_when_unclear():
    unclear = [Half("x", "y", [435]), Half("y", "x", [375])]
    assert directions(unclear, (MATARA, COLOMBO)) == "directions unclear"
    same = [Half(COLOMBO_SHEET, MATARA_SI, [435]), Half(COLOMBO_SHEET, MATARA_SI, [500])]
    assert directions(same, (MATARA, COLOMBO)) == "both halves read the same way"
    assert directions([], (MATARA, COLOMBO)) == "no times"
    # One half, from the end the file name gives.
    assert directions([Half("x", "y", [435])], (MATARA, COLOMBO), one_end=1) == [(1, 0, [435])]


def test_a_sheet_in_sections_joins_each_clear_section_to_its_direction():
    parts = [
        Half(COLOMBO_SHEET, MATARA_SI, [435]),
        Half(MATARA_SI, COLOMBO_SHEET, [375]),
        Half(COLOMBO_SHEET, MATARA_SI, [500]),
        Half("x", "y", [600]),
    ]
    assert directions(parts, (MATARA, COLOMBO)) == [(0, 1, [375]), (1, 0, [435, 500])]


def test_route_numbers_in_a_title():
    route_number = "මාර්ග අංක"
    assert numbers_in_text("Panel Time Table (Route No. EX1-22)") == ["EX1-22"]
    assert numbers_in_text(f"({route_number} : 15/87)") == ["15/87"]
    assert numbers_in_text(f"{route_number} :- EX 1-18 x") == ["EX1-18"]
    assert numbers_in_text("(මා.අ. 49 , 49/950 )") == ["49", "49/950"]
    # The "NTC number" column header is no route number.
    assert numbers_in_text("NTC අංකය 1234") == []


def test_sheets_by_weekday():
    friday, monday = "සිකුරාදා", "සඳුදා"
    assert by_weekday(f"x {friday} y {monday} z")
    assert not by_weekday(f"x {friday} y")
    assert not by_weekday("MATARA GALLE")


def test_one_clear_half_sets_the_other():
    parts = [Half(COLOMBO_SHEET, MATARA_SI, [435]), Half("x", "y", [375])]
    assert directions(parts, (MATARA, COLOMBO)) == [(1, 0, [435]), (0, 1, [375])]


def test_folder_entries():
    page = (
        '<div class="flip-entry" id="entry-F1"><a href="https://drive.google.com/drive/folders/F1">'
        '<div class="flip-entry-title">Luxury</div></a></div>'
        '<div class="flip-entry" id="entry-P1"><a href="https://drive.google.com/file/d/P1/view">'
        '<div class="flip-entry-title">01 Kandy - Colombo &amp; more.pdf</div></a></div>'
    )
    assert folder_entries(page) == [
        ("F1", "Luxury", True),
        ("P1", "01 Kandy - Colombo & more.pdf", False),
    ]


def town(id_, name, lat, lng, si):
    return {
        "type": "node",
        "id": id_,
        "lat": lat,
        "lon": lng,
        "tags": {"place": "city", "name": name, "name:si": si},
    }


TOWNS = Towns.from_overpass(
    {
        "elements": [
            town(1, "Colombo", 6.934, 79.843, COLOMBO_SI),
            town(2, "Matara", 5.948, 80.535, MATARA_SI),
            {
                "type": "node",
                "id": 3,
                "lat": 6.935,
                "lon": 79.850,
                "tags": {"amenity": "bus_station", "name": "Central Bus Stand"},
            },
        ]
    }
)


def test_build_takes_the_newest_readable_sheet(monkeypatch):
    files = [
        DriveFile("old", "2 Colombo - Matara (N).pdf", "Normalway"),
        DriveFile("new", "2 Colombo - Matara (N) 2026.01.01.pdf", "Normalway"),
        DriveFile("spc", "2 Colombo - Matara (N) Special day.pdf", "Normalway"),
        DriveFile("scan", "3 Colombo - Matara (SL) 2026.02.01.pdf", "Normalway"),
        DriveFile("odd", "Colombo Matara.pdf", "Normalway"),
    ]
    downloaded = []

    def download(url):
        downloaded.append(url.rsplit("=", 1)[1])
        return b"%PDF-1.7 " + url.encode()

    def read_pdf(data):
        if data.endswith(b"scan"):
            return None
        return "", [two_halves()]

    monkeypatch.setattr(ntc_sheets, "read_pdf", read_pdf)
    routes, notes = build(files, TOWNS, download, before_reading=lambda: downloaded.append("-"))
    # The towns' names are filled in before any sheet is read.
    assert downloaded == ["-", "new", "scan"]
    assert len(routes) == 1
    route = routes[0]
    assert (route["id"], route["number"], route["classes"], route["long"]) == (
        "ntc:2:N",
        "2",
        ["N"],
        True,
    )
    to_matara, to_colombo = route["directions"]
    assert to_matara["board"]["en"] == "Matara" and to_matara["origin"]["en"] == "Colombo"
    assert to_matara["times"] == [{"days": 0b1111111, "departs": [435, 870]}]
    assert to_matara["stand"] == [6.935, 79.85, "Central Bus Stand"]
    assert to_matara["ends"] == [[6.934, 79.843], [5.948, 80.535]]
    assert "stand" not in to_colombo
    assert sorted(notes) == [
        "ntc 2 Colombo - Matara (N) Special day.pdf: left out, special days or a time card",
        "ntc 3 Colombo - Matara (SL) 2026.02.01.pdf: left out, a scan (its newest sheet)",
        "ntc Colombo Matara.pdf: left out, ends not in the name",
    ]


def test_build_keeps_a_sheet_of_several_routes_and_leaves_out_weekday_ones(monkeypatch):
    files = [
        DriveFile("a", "02 Colombo - Matara (N).pdf", "Normalway"),
        DriveFile("b", "3 Colombo - Matara (SL).pdf", "Normalway"),
        DriveFile("c", "4 Colombo - Galle (SL).pdf", "Normalway"),
    ]
    texts = {
        b"a": "Route No. 2, 2/1",
        b"b": "සිකුරාදා සඳුදා",
    }
    monkeypatch.setattr(
        ntc_sheets, "read_pdf", lambda data: (texts.get(data[-1:], ""), [two_halves()])
    )
    routes, notes = build(files, TOWNS, lambda url: b"%PDF " + url[-1:].encode())
    # Its trips that run end to end may carry any of the sheet's numbers.
    assert [(r["number"], r.get("also")) for r in routes] == [("02", ["2/1"])]
    assert notes == [
        "ntc 4 Colombo - Galle (SL).pdf: left out, no town found for Galle",
        "ntc 3 Colombo - Matara (SL).pdf: left out, times by day of the week",
    ]


GALLE_SI = "ගාල්ල"
GALLE_SHEET = "ගා(cid:7)ල"  # as a sheet's text might give it


def test_a_half_keeps_each_timing_points_minutes_after_departing():
    first, second = halves(join_continued([two_halves()])[0])
    assert first.points == [("x", 95), (MATARA_SI, 195)]
    assert second.points == [("x", 95), (COLOMBO_SHEET, 195)]


def place(id_, name, lat, lng, si, kind="town"):
    return {
        "type": "node",
        "id": id_,
        "lat": lat,
        "lon": lng,
        "tags": {"place": kind, "name": name, "name:si": si},
    }


def colombo_matara(*middle):
    return Towns.from_overpass(
        {
            "elements": [
                place(1, "Colombo", 6.93, 79.85, COLOMBO_SI, "city"),
                place(2, "Matara", 5.95, 80.54, MATARA_SI, "city"),
                *middle,
            ]
        }
    )


def middle_towns_fixture():
    return colombo_matara(
        # Half way along: where a time half way through puts it.
        place(3, "Galle", 6.44, 80.195, GALLE_SI),
        # The same name near the start: too early for that time.
        place(4, "Galle", 6.85, 79.91, GALLE_SI),
        # Off the way altogether.
        place(5, "Galle", 7.50, 81.20, GALLE_SI),
    )


def test_middle_timing_points_are_matched_to_towns_along_the_way():
    towns = middle_towns_fixture()
    colombo, matara = towns.named("Colombo"), towns.named("Matara")
    half = Half(COLOMBO_SHEET, MATARA_SI, [435], [(GALLE_SHEET, 100), (MATARA_SI, 200)])
    found = middle_towns(half, corridor(towns, colombo, matara), towns)
    assert [(town.id, minute) for town, minute in found] == [("n3", 100)]
    # A header no town along the way matches is left out.
    half.points[0] = ("x", 100)
    assert middle_towns(half, corridor(towns, colombo, matara), towns) == []


def test_a_town_back_from_either_end_or_past_it_is_not_on_the_way():
    towns = colombo_matara(
        # A tenth of the way past Matara: little further to go round, but no
        # bus to Matara gets there first.
        place(3, "Galle", 5.852, 80.609, GALLE_SI),
        # A tenth of the way back from Colombo.
        place(4, "Galle", 7.028, 79.781, GALLE_SI),
        place(5, "Galle", 6.44, 80.195, GALLE_SI),
    )
    along = corridor(towns, towns.named("Colombo"), towns.named("Matara"))
    assert [(a.town.id, round(a.share, 2), round(a.detour, 2)) for a in along] == [("n5", 0.5, 1.0)]


OTHER_SHEET = "මගලද"  # another place, sharing two of Galle's letters


def test_a_header_keeps_its_letters_in_its_towns_name():
    galle = {"si": GALLE_SI, "en": "Galle"}
    assert kept(GALLE_SHEET, galle) == 1.0
    assert kept("Gale", galle) == 1.0
    # Alike, but half its letters aren't Galle's: not Galle.
    assert likeness(OTHER_SHEET, galle) >= 0.6
    assert kept(OTHER_SHEET, galle) == 0.5
    towns = middle_towns_fixture()
    half = Half(COLOMBO_SHEET, MATARA_SI, [435], [(OTHER_SHEET, 100), (MATARA_SI, 200)])
    along = corridor(towns, towns.named("Colombo"), towns.named("Matara"))
    assert middle_towns(half, along, towns) == []


def test_of_two_alike_towns_the_one_on_the_way_wins():
    towns = colombo_matara(
        # On the straight way, a little short of where the time puts it.
        place(3, "Galle", 6.5184, 80.1398, GALLE_SI),
        # Just where the time puts it, but well out of the way.
        place(4, "Galle", 6.7264, 80.6017, GALLE_SI),
    )
    half = Half(COLOMBO_SHEET, MATARA_SI, [435], [(GALLE_SHEET, 100), (MATARA_SI, 200)])
    along = corridor(towns, towns.named("Colombo"), towns.named("Matara"))
    found = middle_towns(half, along, towns)
    assert [(town.id, minute) for town, minute in found] == [("n3", 100)]


def test_build_gives_each_direction_its_middle_towns(monkeypatch):
    towns = middle_towns_fixture()
    table = [
        [
            "NTC",
            COLOMBO_SHEET,
            GALLE_SHEET,
            MATARA_SI,
            "",
            "NTC",
            MATARA_SI,
            GALLE_SHEET,
            COLOMBO_SHEET,
        ],
        ["T1", "7:00", "8:40", "10:20", "", "T2", "6:00", "7:40", "9:20"],
    ]
    monkeypatch.setattr(ntc_sheets, "read_pdf", lambda data: ("", [table]))
    files = [DriveFile("a", "2 Colombo - Matara (N).pdf", "Normalway")]
    (route,), _ = build(files, towns, lambda url: b"%PDF")
    to_matara, to_colombo = route["directions"]
    assert to_matara["stops"] == [[6.44, 80.195, "Galle", 100]]
    assert to_colombo["stops"] == [[6.44, 80.195, "Galle", 100]]


def test_the_same_sheet_in_two_folders_is_one_route(monkeypatch):
    files = [
        DriveFile("a", "2 Colombo - Matara (N-SL).pdf", "Normalway/Normal / Semi Luxury"),
        DriveFile("b", "2 Colombo - Matara (SL-AC).pdf", "Normalway/Semi Luxury"),
    ]
    monkeypatch.setattr(ntc_sheets, "read_pdf", lambda data: ("", [two_halves()]))
    routes, _ = build(files, TOWNS, lambda url: b"%PDF")
    assert [(r["id"], r["classes"]) for r in routes] == [("ntc:2:N-SL", ["N", "SL", "AC"])]


def test_only_trips_that_run_the_whole_way_count():
    table = two_halves()
    # A trip of another route on the sheet starts part way along.
    table.append(["T9", "NB-9", "", "9:00", "10:40", "", "T10", "NB-10", "8:00", "9:35", ""])
    found = halves(join_continued([table])[0])
    assert [h.departs for h in found] == [[435, 870], [375, 710]]


def test_a_half_of_another_route_is_no_clear_direction():
    # It leaves from a town that is neither end (Galle, on a Colombo - Matara sheet).
    other = [Half("ගාල්ල", MATARA_SI, [435])]
    assert directions(other, (COLOMBO, MATARA)) == "direction unclear"
    # Beside a clear half that runs the same way, it is left out.
    parts = [Half(COLOMBO_SHEET, MATARA_SI, [500]), other[0]]
    assert directions(parts, (COLOMBO, MATARA)) == [(0, 1, [500])]
