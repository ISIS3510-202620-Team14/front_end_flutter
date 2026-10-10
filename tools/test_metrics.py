import unittest
from metrics import normalize_rows, reference_totals

class MetricsTests(unittest.TestCase):
    def fixture(self):
        rows = []
        for title, source in [("Lectura", "library"), ("Lectura", "library"), ("Mi actividad", "custom")]:
            rows.append({"date": "2026-10-10", "name": "activity_selected", "title": title,
                         "source": source, "platform": "flutter"})
        rows.append({"date": "2026-10-10", "name": "grouping_method_selected", "subject": "lectura",
                     "method": "manual", "classSize": 12, "platform": "flutter"})
        return rows

    def test_known_totals_and_ranking(self):
        totals = reference_totals(self.fixture())
        self.assertEqual(totals["activities"], 3)
        self.assertEqual(totals["library"], 2)
        self.assertEqual(totals["custom"], 1)
        self.assertAlmostEqual(totals["libraryPercentage"], 2 / 3)
        self.assertEqual(totals["ranking"], {"Lectura": 2, "Mi actividad": 1})
        self.assertEqual(totals["groupingSample"], 1)

    def test_empty_period_has_no_percentage(self):
        totals = reference_totals(self.fixture(), "2026-11-01", "2026-11-30")
        self.assertEqual(totals["activities"], 0)
        self.assertIsNone(totals["libraryPercentage"])
        self.assertEqual(totals["groupingSample"], 0)

    def test_other_and_unknown_platform_never_enter_report(self):
        rows = self.fixture()
        for platform in ["kotlin", "", None]:
            other = dict(rows[0])
            other["platform"] = platform
            rows.append(other)
        self.assertEqual(len(normalize_rows(rows)), 4)

    def test_unknown_source_is_not_reported_as_custom(self):
        row = self.fixture()[0]
        row["source"] = "unknown"
        with self.assertRaises(ValueError):
            normalize_rows([row])

if __name__ == "__main__":
    unittest.main()
