#!/usr/bin/env python3
"""Gate the Verify action on the recomputed required score, and write the
step summary. Run by .github/workflows/verify.yml after check.sh."""
import json
import os
import sys

report = json.load(open("results/report.json", encoding="utf-8"))
failed = [item["name"] for item in report["results"] if item["status"] != "pass"]
headline = f"### Required score: {report['score']} / {report['total']}"

summary = os.environ.get("GITHUB_STEP_SUMMARY")
if summary:
    with open(summary, "a", encoding="utf-8") as fh:
        fh.write(headline + "\n\n")
        if failed:
            fh.write("Not passing: " + ", ".join(failed) + "\n")

print(headline)
if failed:
    print("Not passing: " + ", ".join(failed))
    sys.exit(1)
