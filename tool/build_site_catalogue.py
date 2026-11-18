# SPDX-License-Identifier: GPL-3.0-or-later
# Input data: Submersion site catalogue (ODbL-1.0), https://github.com/submersion-app/submersion
"""Builds DiveDown's bundled dive site catalogue (ADR 0006, tasks.md T13).

Keeps only openly licensed dive sites (OpenStreetMap, Wikidata, Submersion's own
curation), drops wreck/obstruction registers and sources with their own terms,
cleans names, removes near-duplicates and writes a reproducible gzip file.

Usage:
    python -I tool/build_site_catalogue.py \
        --input submersion-referenz/assets/data/site_catalogue.json \
        --output assets/data/dive_sites.json.gz \
        --source-commit e78a87cb
"""
import argparse
import gzip
import hashlib
import json
import math
import os
import unicodedata

# Highest priority first: when two entries describe the same site, the one from
# the more carefully reviewed source wins.
KEPT_SOURCES = ("curated", "research", "osm", "wikidata")
_PRIORITY = {name: i for i, name in enumerate(KEPT_SOURCES)}

MAX_NAME_LENGTH = 120
DUPLICATE_RADIUS_M = 50.0

NOTICE = (
    "DiveDown dive site catalogue. This database is made available under the Open "
    "Database License (ODbL) 1.0, https://opendatacommons.org/licenses/odbl/1-0/ . "
    "Contains information from OpenStreetMap, which is made available under the ODbL, "
    "https://www.openstreetmap.org/copyright . Derived from the Submersion site "
    "catalogue (ODbL-1.0, https://github.com/submersion-app/submersion), using only its "
    "OpenStreetMap (ODbL-1.0), Wikidata (CC0-1.0, https://www.wikidata.org/wiki/"
    "Wikidata:Copyright) and Submersion-curated (ODbL-1.0) records."
)

_APOSTROPHES = str.maketrans({"’": "'", "‘": "'", "ʼ": "'", "`": "'", "´": "'"})


def clean_name(name):
    """Returns a display-safe name, or None when the entry must be dropped.

    A U+FFFD replacement character means the original letters are already lost,
    so such entries are dropped rather than shown with a broken name.
    """
    if not isinstance(name, str):
        return None
    if "�" in name:
        return None
    if "Ã" in name or "Â" in name:  # typical UTF-8-read-as-Latin-1 mojibake
        for codec in ("cp1252", "latin-1"):
            try:
                name = name.encode(codec).decode("utf-8")
                break
            except (UnicodeEncodeError, UnicodeDecodeError):
                continue
    name = " ".join(name.split())
    if not name:
        return None
    return name[:MAX_NAME_LENGTH].rstrip()


def _match_key(name):
    """Name form used only for duplicate detection: no case, accents or apostrophe variants."""
    decomposed = unicodedata.normalize("NFKD", name.translate(_APOSTROPHES))
    stripped = "".join(c for c in decomposed if not unicodedata.combining(c))
    return " ".join(stripped.casefold().split())


def _valid_coordinate(value, limit):
    return isinstance(value, (int, float)) and math.isfinite(value) and -limit <= value <= limit


def _distance_m(a, b):
    lat1, lon1, lat2, lon2 = map(math.radians, (a["lat"], a["lon"], b["lat"], b["lon"]))
    h = (math.sin((lat2 - lat1) / 2) ** 2
         + math.cos(lat1) * math.cos(lat2) * math.sin((lon2 - lon1) / 2) ** 2)
    return 2 * 6371000.0 * math.asin(math.sqrt(h))


def _output_record(site, name):
    types = site.get("types")
    return {
        "id": site["id"],
        "name": name,
        "region": site.get("region"),
        "country_code": site.get("country_code"),
        "lat": round(float(site["lat"]), 5),
        "lon": round(float(site["lon"]), 5),
        "max_depth_m": site.get("max_depth_m"),
        "types": list(types) if isinstance(types, list) else [],
    }


def build(catalogue, source_commit):
    """Filters and cleans a Submersion catalogue (format 2). Returns (data, report)."""
    report = {"input": 0, "other_source": 0, "invalid": 0, "replacement_char": 0,
              "names_changed": 0, "duplicates": 0}
    candidates = []
    for site in catalogue.get("sites", []):
        report["input"] += 1
        if site.get("source") not in _PRIORITY:
            report["other_source"] += 1
            continue
        raw = site.get("name")
        if isinstance(raw, str) and "�" in raw:
            report["replacement_char"] += 1
            continue
        name = clean_name(raw)
        if (name is None or not site.get("id")
                or not _valid_coordinate(site.get("lat"), 90)
                or not _valid_coordinate(site.get("lon"), 180)):
            report["invalid"] += 1
            continue
        if isinstance(raw, str) and name != " ".join(raw.split())[:MAX_NAME_LENGTH].rstrip():
            report["names_changed"] += 1
        candidates.append((site, name))

    candidates.sort(key=lambda c: (_PRIORITY[c[0]["source"]], str(c[0]["id"])))
    kept_by_key = {}
    kept = []
    for site, name in candidates:
        key = _match_key(name)
        if any(_distance_m(site, other) < DUPLICATE_RADIUS_M for other in kept_by_key.get(key, [])):
            report["duplicates"] += 1
            continue
        kept_by_key.setdefault(key, []).append(site)
        kept.append(_output_record(site, name))

    kept.sort(key=lambda s: (s["country_code"] or "", s["name"].casefold(), str(s["id"])))
    source_md = catalogue.get("metadata", {})
    data = {
        "metadata": {
            "format": 1,
            "notice": NOTICE,
            "license": "ODbL-1.0",
            "sources": sorted(KEPT_SOURCES),
            "source_commit": source_commit,
            "source_generated_at": source_md.get("generated_at"),
            "count": len(kept),
        },
        "sites": kept,
    }
    report["output"] = len(kept)
    return data, report


def write_gz(data, path):
    """Writes byte-identical output for identical data (no timestamp in the gzip header)."""
    payload = json.dumps(data, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    blob = gzip.compress(payload, compresslevel=9, mtime=0)
    with open(path, "wb") as f:
        f.write(blob)
    return hashlib.sha256(blob).hexdigest()


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--source-commit", required=True)
    args = parser.parse_args(argv)

    with open(args.input, encoding="utf-8") as f:
        catalogue = json.load(f)
    data, report = build(catalogue, args.source_commit)
    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    digest = write_gz(data, args.output)
    version_path = os.path.splitext(os.path.splitext(args.output)[0])[0] + ".version"
    with open(version_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(digest + "\n")
    print(json.dumps({**report, "sha256": digest}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
