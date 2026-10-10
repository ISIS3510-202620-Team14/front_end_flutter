"""Validate manual Flutter exports and calculate independent reference totals."""
from datetime import date
from collections import Counter

EVENTS = {"activity_selected", "grouping_method_selected"}
COLUMNS = ["date", "name", "title", "subject", "source", "method", "classSize", "count", "platform"]

def normalize_rows(rows):
    result = []
    for row in rows:
        if row.get("platform") != "flutter" or row.get("name") not in EVENTS:
            continue
        date.fromisoformat(row["date"])
        clean = {column: row.get(column, "") for column in COLUMNS}
        clean["count"] = 1
        if clean["name"] == "activity_selected":
            if clean["source"] not in {"library", "custom"}:
                raise ValueError("Unverified activity source")
        else:
            if clean["method"] not in {"automatic", "manual"}:
                raise ValueError("Unverified grouping method")
            clean["classSize"] = int(clean["classSize"])
            if clean["classSize"] < 0:
                raise ValueError("Invalid class size")
        result.append(clean)
    return result

def reference_totals(rows, start=None, end=None):
    filtered = []
    for row in normalize_rows(rows):
        if start is not None and row["date"] < start:
            continue
        if end is not None and row["date"] > end:
            continue
        filtered.append(row)
    activities = [row for row in filtered if row["name"] == "activity_selected"]
    library = len([row for row in activities if row["source"] == "library"])
    percentage = None
    if activities:
        percentage = library / len(activities)
    return {"activities": len(activities), "library": library,
            "custom": len(activities) - library, "libraryPercentage": percentage,
            "ranking": dict(Counter(row["title"] for row in activities)),
            "groupingSample": len([row for row in filtered if row["name"] == "grouping_method_selected"])}
