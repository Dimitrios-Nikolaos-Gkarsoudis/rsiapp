#!/usr/bin/env python3
"""Snap the mock road segments onto the real road network.

The mock segments in assets/data/road_segments.geojson were drawn from a few
hand-placed points, so on the map they cut across blocks instead of following
streets. This script sends each segment's points to the OSRM map matching
service (OpenStreetMap roads, which Mapbox's street map is also built from)
and replaces the geometry with the matched road shape.

A match is only used when every point matched, the result is one piece, and
its length is close to the drawn length. Segments that fail keep their drawn
shape and are listed at the end so their points can be fixed.

The hand-placed points are kept in properties.sourceCoordinates, so the script
can be re-run safely after editing them.

Usage:
    python3 tool/snap_road_segments.py            # update the data file
    python3 tool/snap_road_segments.py --dry-run  # only print the results
"""

import argparse
import json
import math
import os
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

DATA_FILE = (
    Path(__file__).resolve().parent.parent / "assets" / "data" / "road_segments.geojson"
)
BASE_URL = os.environ.get(
    "RSI_ROUTING_BASE_URL", "https://router.project-osrm.org"
).rstrip("/")
USER_AGENT = "RoadSafetyInsights-dev/0.1 (mock data preparation)"

# Search radius around each point, tried in order. The public OSRM server
# rejects radii of 50 m and more ("TooBig").
RADII_METERS = (20, 35)

# Matched length / drawn length must fall in this range. Shorter means part of
# the drawn road was not matched; longer usually means a detour, for example
# driving round a one-way street.
MIN_LENGTH_RATIO = 0.8
MAX_LENGTH_RATIO = 1.4

# The public OSRM server is a shared demo service; keep requests slow.
REQUEST_PAUSE_SECONDS = 1.0

EARTH_RADIUS_METERS = 6_371_000


def distance_m(a, b):
    """Great-circle distance between two [lng, lat] points."""
    lng1, lat1, lng2, lat2 = map(math.radians, (a[0], a[1], b[0], b[1]))
    h = (
        math.sin((lat2 - lat1) / 2) ** 2
        + math.cos(lat1) * math.cos(lat2) * math.sin((lng2 - lng1) / 2) ** 2
    )
    return 2 * EARTH_RADIUS_METERS * math.asin(math.sqrt(h))


def length_m(coordinates):
    return sum(distance_m(a, b) for a, b in zip(coordinates, coordinates[1:]))


def match(coordinates, radius):
    """Returns (result, None) on success or (None, reason) on failure."""
    path = ";".join(f"{lng:.6f},{lat:.6f}" for lng, lat in coordinates)
    query = urllib.parse.urlencode(
        {
            "geometries": "geojson",
            "overview": "full",
            "radiuses": ";".join([str(radius)] * len(coordinates)),
        }
    )
    request = urllib.request.Request(
        f"{BASE_URL}/match/v1/driving/{path}?{query}",
        headers={"User-Agent": USER_AGENT},
    )

    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            body = json.load(response)
    except urllib.error.HTTPError as error:
        # OSRM reports problems such as NoMatch as JSON with a 400 status.
        try:
            body = json.load(error)
        except json.JSONDecodeError:
            return None, f"HTTP {error.code}"
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as error:
        return None, f"request failed: {error}"

    matchings = body.get("matchings") or []
    if body.get("code") != "Ok" or not matchings:
        return None, body.get("code", "unknown error")

    matched = []
    for matching in matchings:
        part = matching["geometry"]["coordinates"]
        if matched and part and matched[-1] == part[0]:
            part = part[1:]
        matched.extend(part)

    return {
        "coordinates": matched,
        "distance": sum(m.get("distance", 0.0) for m in matchings),
        "pieces": len(matchings),
        "unmatched": sum(1 for point in body.get("tracepoints", []) if point is None),
    }, None


def snap(source):
    """Best acceptable match for a segment (or None), plus the attempts made."""
    drawn_length = length_m(source)
    attempts = []
    accepted = []

    for radius in RADII_METERS:
        for reverse in (False, True):
            label = f"r{radius}{' reversed' if reverse else ''}"
            points = list(reversed(source)) if reverse else source
            result, error = match(points, radius)
            time.sleep(REQUEST_PAUSE_SECONDS)

            if error:
                attempts.append(f"{label}: {error}")
                continue

            if reverse:
                result["coordinates"].reverse()

            result["ratio"] = result["distance"] / drawn_length
            result["radius"] = radius
            result["reversed"] = reverse
            attempts.append(
                f"{label}: ratio {result['ratio']:.2f}, {result['pieces']} piece(s), "
                f"{result['unmatched']} unmatched point(s)"
            )

            if (
                result["pieces"] == 1
                and result["unmatched"] == 0
                and MIN_LENGTH_RATIO <= result["ratio"] <= MAX_LENGTH_RATIO
            ):
                accepted.append(result)

        if accepted:
            break  # prefer the tighter search radius

    if not accepted:
        return None, attempts

    return min(accepted, key=lambda result: abs(result["ratio"] - 1)), attempts


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--dry-run", action="store_true", help="print results without saving"
    )
    args = parser.parse_args()

    collection = json.loads(DATA_FILE.read_text())
    snapped = 0
    kept = []

    for feature in collection["features"]:
        properties = feature["properties"]

        # Shapes traced directly from an OpenStreetMap street are already on
        # the road; matching them again could only make them worse.
        if properties.get("shapeSource") == "openstreetmap":
            print(f"SKIPPED {properties['id']:<11} {properties['name']} (traced from OpenStreetMap)")
            continue

        source = properties.get("sourceCoordinates") or feature["geometry"]["coordinates"]
        result, attempts = snap(source)

        if result is None:
            kept.append(properties["id"])
            properties["sourceCoordinates"] = source
            feature["geometry"]["coordinates"] = source
            print(f"KEPT    {properties['id']:<11} {properties['name']}: {'; '.join(attempts)}")
            continue

        properties["sourceCoordinates"] = source
        feature["geometry"]["coordinates"] = [
            [round(lng, 6), round(lat, 6)] for lng, lat in result["coordinates"]
        ]
        snapped += 1
        print(
            f"SNAPPED {properties['id']:<11} {len(source)} -> "
            f"{len(result['coordinates'])} points, "
            f"{length_m(source):.0f} m -> {result['distance']:.0f} m "
            f"(ratio {result['ratio']:.2f}"
            f"{', reversed' if result['reversed'] else ''}, radius {result['radius']} m) "
            f"{properties['name']}"
        )

    if not args.dry_run:
        DATA_FILE.write_text(json.dumps(collection, indent=2) + "\n")

    suffix = " (dry run, file unchanged)" if args.dry_run else ""
    print(f"\n{snapped} snapped, {len(kept)} kept as drawn{suffix}")
    if kept:
        print("kept as drawn: " + ", ".join(kept))


if __name__ == "__main__":
    main()
