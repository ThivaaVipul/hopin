import pytest

from geometry import (
    chain,
    decode_polyline,
    encode_polyline,
    fraction_along,
    length,
    metres,
    project,
    simplify,
)

FORT = (6.9344, 79.8428)


def test_polyline_matches_googles_example():
    points = [(38.5, -120.2), (40.7, -120.95), (43.252, -126.453)]
    assert encode_polyline(points) == "_p~iF~ps|U_ulLnnqC_mqNvxq`@"
    assert decode_polyline("_p~iF~ps|U_ulLnnqC_mqNvxq`@") == points


def test_metres_and_length():
    north = (FORT[0] + 1, FORT[1])
    assert metres(FORT, north) == pytest.approx(111_195, rel=1e-3)
    assert length([FORT, north, FORT]) == pytest.approx(2 * 111_195, rel=1e-3)


def test_simplify_drops_points_on_the_line_and_keeps_corners():
    line = [(6.90, 79.85), (6.91, 79.85), (6.92, 79.85), (6.92, 79.86)]
    assert simplify(line, 10) == [(6.90, 79.85), (6.92, 79.85), (6.92, 79.86)]
    assert simplify(line[:2]) == line[:2]


def test_project_finds_the_nearest_point_along_the_path():
    path = [(6.90, 79.85), (6.91, 79.85), (6.91, 79.86)]
    along, away = project(path, (6.905, 79.8501))
    assert along == pytest.approx(metres(path[0], (6.905, 79.85)), rel=1e-3)
    assert away == pytest.approx(11, abs=1)
    along, _ = project(path, (6.911, 79.86))
    assert along == pytest.approx(length(path), rel=1e-3)


def test_fraction_along_a_straight_way():
    a, b = (6.90, 79.85), (7.00, 79.85)
    assert fraction_along(a, b, (6.95, 79.86)) == pytest.approx(0.5)
    # Before the start and past the end fall outside 0 to 1.
    assert fraction_along(a, b, (6.89, 79.85)) == pytest.approx(-0.1)
    assert fraction_along(a, b, (7.02, 79.85)) == pytest.approx(1.2)
    assert fraction_along(a, a, b) == 0.0


def test_chain_turns_lines_round_to_join_them():
    a = [(6.90, 79.85), (6.91, 79.85)]
    b = [(6.92, 79.85), (6.91, 79.85)]  # drawn the other way
    assert chain([a, b]) == [[(6.90, 79.85), (6.91, 79.85), (6.92, 79.85)]]
    # The first line only shows its direction once the second meets it.
    assert chain([a[::-1], b]) == [[(6.90, 79.85), (6.91, 79.85), (6.92, 79.85)]]


def test_chain_starts_a_new_run_after_a_gap():
    runs = chain([[(6.90, 79.85), (6.91, 79.85)], [(6.95, 79.85), (6.96, 79.85)]])
    assert len(runs) == 2
