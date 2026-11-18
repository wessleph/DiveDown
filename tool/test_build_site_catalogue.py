# SPDX-License-Identifier: GPL-3.0-or-later
"""Tests for build_site_catalogue.py (tasks.md T13, ADR 0006).

Run: python -I -m unittest discover -s tool -p "test_*.py"
"""
import gzip
import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_site_catalogue as bsc  # noqa: E402


def site(**kw):
    base = {
        "id": "osm_1", "name": "SS Thistlegorm", "lat": 27.813611, "lon": 33.920556,
        "country_code": "EG", "country": "Egypt", "region": "Red Sea",
        "max_depth_m": 30.0, "types": ["wreck"], "source": "osm",
        "source_ref": "https://www.openstreetmap.org/node/1", "trust": "community",
    }
    base.update(kw)
    return base


def catalogue(sites, notice="Contains information from OpenStreetMap ... ODbL"):
    return {"metadata": {"format": 2, "generated_at": "2026-11-17T01:54:24Z",
                         "notice": notice}, "sites": sites}


class T13_1_SourceFilter(unittest.TestCase):
    def test_keeps_only_open_sources(self):
        sites = [site(id="a", source="osm"), site(id="b", source="ukho", name="X1"),
                 site(id="c", source="njdep", name="X2"), site(id="d", source="wikidata", name="X3"),
                 site(id="e", source="curated", name="X4"), site(id="f", source="research", name="X5"),
                 site(id="g", source="hi_dar", name="X6"), site(id="h", source="tpwd", name="X7")]
        out, _ = bsc.build(catalogue(sites), source_commit="abc")
        self.assertEqual(sorted(s["id"] for s in out["sites"]), ["a", "d", "e", "f"])


class T13_2_Validity(unittest.TestCase):
    def test_drops_missing_name_and_bad_coordinates(self):
        sites = [site(id="ok"), site(id="noname", name=""), site(id="nullname", name=None),
                 site(id="lat", lat=90.5, name="A"), site(id="lon", lon=-180.5, name="B"),
                 site(id="nan", lat=float("nan"), name="C")]
        out, report = bsc.build(catalogue(sites), source_commit="abc")
        self.assertEqual([s["id"] for s in out["sites"]], ["ok"])
        self.assertEqual(report["invalid"], 5)


class T13_3_4_5_Names(unittest.TestCase):
    def test_repairs_mojibake(self):
        self.assertEqual(bsc.clean_name("ZÃ¼richsee"), "Zürichsee")

    def test_keeps_correct_umlauts(self):
        self.assertEqual(bsc.clean_name("Vierwaldstättersee - Tellskapelle"),
                         "Vierwaldstättersee - Tellskapelle")

    def test_replacement_char_drops_entry(self):
        self.assertIsNone(bsc.clean_name("Vierwaldst�ttersee"))
        out, report = bsc.build(catalogue([site(id="x", name="Bad�Name"), site(id="y")]),
                                source_commit="abc")
        self.assertEqual([s["id"] for s in out["sites"]], ["y"])
        self.assertEqual(report["replacement_char"], 1)

    def test_whitespace_and_length(self):
        self.assertEqual(bsc.clean_name("  Shark   Reef \t "), "Shark Reef")
        long = "A" * 130
        self.assertEqual(len(bsc.clean_name(long)), 120)


class T13_6_Dedupe(unittest.TestCase):
    def test_same_name_close_coordinates_keeps_highest_priority(self):
        sites = [site(id="w", source="wikidata", lat=27.81361, lon=33.92055),
                 site(id="o", source="osm", lat=27.81380, lon=33.92070),   # ~25 m away
                 site(id="c", source="curated", lat=27.81370, lon=33.92060)]
        out, report = bsc.build(catalogue(sites), source_commit="abc")
        self.assertEqual([s["id"] for s in out["sites"]], ["c"])
        self.assertEqual(report["duplicates"], 2)

    def test_same_name_far_apart_stays(self):
        sites = [site(id="a", name="Blue Hole", lat=27.57, lon=34.54, country_code="EG"),
                 site(id="b", name="Blue Hole", lat=7.13, lon=134.22, country_code="PW")]
        out, _ = bsc.build(catalogue(sites), source_commit="abc")
        self.assertEqual(len(out["sites"]), 2)

    def test_name_match_ignores_case_and_accents(self):
        sites = [site(id="a", source="osm", name="Sha’ab El Erg"),
                 site(id="b", source="wikidata", name="sha'ab el erg")]
        out, _ = bsc.build(catalogue(sites), source_commit="abc")
        self.assertEqual([s["id"] for s in out["sites"]], ["a"])


class T13_7_OutputShape(unittest.TestCase):
    def test_fields_rounding_and_sort(self):
        sites = [site(id="z", name="Zebra Reef", country_code="EG", lat=27.1234567, lon=33.7654321),
                 site(id="a", name="Alpha Reef", country_code="EG"),
                 site(id="ch", name="Walensee", country_code="CH", lat=47.12, lon=9.3,
                      types=None, max_depth_m=None, region=None)]
        out, _ = bsc.build(catalogue(sites), source_commit="abc")
        self.assertEqual([s["id"] for s in out["sites"]], ["ch", "a", "z"])
        for s in out["sites"]:
            self.assertEqual(set(s.keys()),
                             {"id", "name", "region", "country_code", "lat", "lon",
                              "max_depth_m", "types"})
        z = out["sites"][2]
        self.assertEqual(z["lat"], 27.12346)
        self.assertEqual(z["lon"], 33.76543)
        self.assertEqual(out["sites"][0]["types"], [])


class T13_8_Deterministic(unittest.TestCase):
    def test_byte_identical_output(self):
        data, _ = bsc.build(catalogue([site(id="a"), site(id="b", name="Yolanda Reef")]),
                            source_commit="abc")
        with tempfile.TemporaryDirectory() as d:
            p1, p2 = os.path.join(d, "1.json.gz"), os.path.join(d, "2.json.gz")
            bsc.write_gz(data, p1)
            bsc.write_gz(data, p2)
            with open(p1, "rb") as f1, open(p2, "rb") as f2:
                b1, b2 = f1.read(), f2.read()
            self.assertEqual(b1, b2)
            self.assertEqual(json.loads(gzip.decompress(b1).decode("utf-8")), data)


class T13_9_Metadata(unittest.TestCase):
    def test_metadata_carries_notice_and_provenance(self):
        out, _ = bsc.build(catalogue([site()], notice="NOTICE ODbL"), source_commit="e78a87cb")
        md = out["metadata"]
        self.assertIn("ODbL", md["notice"])
        self.assertIn("DiveDown", md["notice"])
        self.assertEqual(md["source_commit"], "e78a87cb")
        self.assertEqual(md["source_generated_at"], "2026-11-17T01:54:24Z")
        self.assertEqual(md["count"], 1)
        self.assertEqual(md["sources"], ["curated", "osm", "research", "wikidata"])


if __name__ == "__main__":
    unittest.main()
