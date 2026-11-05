"""Polite HTTP for the route data job: an identifying user agent and a few retries."""

from __future__ import annotations

import time
import urllib.error
import urllib.parse
import urllib.request

AGENT = "hopin-route-data/1 (https://github.com/ThivaaVipul/hopin)"

OVERPASS = (
    "https://overpass-api.de/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
)


def get(
    url: str,
    *,
    form: dict[str, str] | None = None,
    timeout: float = 120,
    tries: int = 3,
    pause: float = 10,
) -> bytes:
    """The body at url (a POST when form is given). Retries busy servers and network errors."""
    body = urllib.parse.urlencode(form).encode() if form is not None else None
    for attempt in range(1, tries + 1):
        request = urllib.request.Request(url, data=body, headers={"User-Agent": AGENT})
        try:
            with urllib.request.urlopen(request, timeout=timeout) as response:
                return response.read()
        except urllib.error.HTTPError as error:
            if attempt == tries or (error.code < 500 and error.code != 429):
                raise
        except (urllib.error.URLError, TimeoutError):
            if attempt == tries:
                raise
        time.sleep(pause * attempt)
    raise AssertionError("unreachable")


def overpass(query: str, timeout: float = 360) -> bytes:
    """Runs an Overpass query, trying a second server when the first is at capacity."""
    errors = []
    for server in OVERPASS:
        try:
            return get(server, form={"data": query}, timeout=timeout, tries=2, pause=30)
        except (urllib.error.URLError, TimeoutError) as error:
            errors.append(f"{server}: {error}")
    raise RuntimeError("Overpass failed: " + "; ".join(errors))
