import json

import pytest

import build_data


def test_each_source_writes_its_file_and_a_failure_keeps_the_last_one(
    tmp_path, monkeypatch, capsys
):
    route = {"id": "osm:1", "number": "1", "directions": [{"board": {"en": "A", "ta": "x"}}]}

    def broken(towns):
        raise OSError("server down")

    monkeypatch.setattr(build_data.net, "overpass", lambda query: b'{"elements": []}')
    monkeypatch.setattr(build_data.net, "get", lambda url: b'{"entities": {}}')
    monkeypatch.setattr(
        build_data,
        "BUILDERS",
        {"osm": lambda towns: ([route], ["a note"]), "ntc": lambda towns: ([], []), "lmt": broken},
    )
    assert build_data.main(["--out", str(tmp_path)]) == 1
    assert sorted(p.name for p in tmp_path.iterdir()) == ["osm-routes.json"]
    payload = json.loads((tmp_path / "osm-routes.json").read_text(encoding="utf-8"))
    assert payload["format"] == 1 and payload["source"] == "osm"
    assert payload["routes"] == [route]
    assert "OpenStreetMap" in payload["credit"] and "Wikidata" in payload["credit"]
    out = capsys.readouterr().out
    assert "  a note" in out
    assert "osm: 1 routes, 1 directions; boards with Tamil 1, with Sinhala 0" in out
    assert "ntc: failed: RuntimeError('no routes found')" in out
    assert "lmt: failed: OSError('server down')" in out


def test_only_some_sources(tmp_path, monkeypatch):
    monkeypatch.setattr(build_data.net, "overpass", lambda query: b'{"elements": []}')
    monkeypatch.setattr(build_data.net, "get", lambda url: b'{"entities": {}}')
    route = {"id": "lmt:CM1", "number": "CM1", "directions": [{"board": {"en": "B"}}]}
    monkeypatch.setattr(build_data, "BUILDERS", {"lmt": lambda towns: ([route], [])})
    assert build_data.main(["--out", str(tmp_path), "--only", "lmt"]) == 0
    assert [p.name for p in tmp_path.iterdir()] == ["lmt-routes.json"]
    with pytest.raises(SystemExit):
        build_data.main(["--out", str(tmp_path), "--only", "bus"])
