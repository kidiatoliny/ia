#!/usr/bin/env python3
import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

HIGH_LABELS = {
    "critical": 100,
    "p0": 100,
    "severity:critical": 100,
    "security": 100,
    "high": 75,
    "p1": 75,
    "severity:high": 75,
    "bug": 70,
    "medium": 50,
    "p2": 50,
    "low": 20,
    "p3": 20,
    "chore": 10,
    "docs": 5,
}

KEYWORD_BONUS = {
    "security": 30,
    "vulnerability": 30,
    "outage": 30,
    "data loss": 30,
    "payment": 20,
    "checkout": 20,
    "invoice": 20,
    "auth": 20,
    "regression": 15,
    "urgent": 15,
}


def parse_iso(ts: str) -> datetime:
    return datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone(timezone.utc)


def calc_score(issue: dict) -> tuple[int, int, str]:
    labels = [l["name"].strip().lower() for l in issue.get("labels", []) if l.get("name")]
    title = issue.get("title", "").lower()
    score = 0

    for label in labels:
        score = max(score, HIGH_LABELS.get(label, 0))

    for keyword, bonus in KEYWORD_BONUS.items():
        if keyword in title:
            score += bonus

    created_at = parse_iso(issue["createdAt"])
    age_days = max(0, (datetime.now(timezone.utc) - created_at).days)
    score += min(age_days // 7, 15)

    reason = f"labels={labels or ['none']} age_days={age_days}"
    return score, age_days, reason


def main() -> int:
    parser = argparse.ArgumentParser(description="Prioritize GitHub issues by urgency")
    parser.add_argument("--input", required=True, help="Path to JSON from gh issue list")
    args = parser.parse_args()

    path = Path(args.input)
    issues = json.loads(path.read_text(encoding="utf-8"))

    scored = []
    for issue in issues:
        score, age_days, reason = calc_score(issue)
        scored.append((score, age_days, issue, reason))

    scored.sort(key=lambda x: (-x[0], -x[1], x[2]["number"]))

    for idx, (score, _, issue, reason) in enumerate(scored, start=1):
        print(f"{idx:02d}. #{issue['number']} score={score:03d} {issue['title']}")
        print(f"    {issue.get('url', '')}")
        print(f"    {reason}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
