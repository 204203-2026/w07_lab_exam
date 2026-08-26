#!/usr/bin/env python3
"""Write the bonus tally to the step summary. Never fails the run — bonus work
must not look like a required failure. Run by .github/workflows/challenge.yml."""
import json
import os

report = json.load(open("results/challenge_report.json", encoding="utf-8"))
done = [item["name"] for item in report["results"] if item["status"] == "bonus"]
todo = [item["name"] for item in report["results"] if item["status"] != "bonus"]

lines = [f"### Bonus: {report['bonus']} / {report['bonus_total']}", ""]
if done:
    lines += ["Done: " + ", ".join(done), ""]
if todo:
    lines += ["Not done: " + ", ".join(todo), ""]

summary = os.environ.get("GITHUB_STEP_SUMMARY")
if summary:
    with open(summary, "a", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")
print("\n".join(lines))
