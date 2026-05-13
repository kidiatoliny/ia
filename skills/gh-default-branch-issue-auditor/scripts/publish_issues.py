#!/usr/bin/env python3
"""Create prioritized GitHub issues from a JSON findings file."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

PRIORITY_LABELS = {
    "P0": "priority:P0",
    "P1": "priority:P1",
    "P2": "priority:P2",
    "P3": "priority:P3",
}

VALID_PRIORITIES = set(PRIORITY_LABELS)


@dataclass
class Finding:
    title: str
    priority: str
    summary: str
    why_this_matters: list[str]
    evidence: list[str]
    root_cause_hypothesis: str
    proposed_solution: list[str]
    acceptance_criteria: list[str]
    scope_and_risks: list[str]
    type_label: str
    labels: list[str]


def run_gh_json(args: list[str]) -> Any:
    proc = subprocess.run(["gh", *args], text=True, capture_output=True)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or f"gh command failed: {' '.join(args)}")
    if not proc.stdout.strip():
        return None
    return json.loads(proc.stdout)


def run_gh_text(args: list[str]) -> str:
    proc = subprocess.run(["gh", *args], text=True, capture_output=True)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or f"gh command failed: {' '.join(args)}")
    return proc.stdout


def normalize_priority(value: str) -> str:
    normalized = value.upper().strip()
    if normalized not in VALID_PRIORITIES:
        raise ValueError(f"Invalid priority '{value}'. Use one of: {', '.join(sorted(VALID_PRIORITIES))}")
    return normalized


def normalize_type_label(value: str | None) -> str:
    if not value:
        return "type:bug"
    raw = value.strip()
    if not raw:
        return "type:bug"
    return raw if raw.startswith("type:") else f"type:{raw}"


def load_findings(path: Path) -> list[Finding]:
    raw = json.loads(path.read_text())
    if not isinstance(raw, list) or not raw:
        raise ValueError("Input JSON must be a non-empty array of findings")

    findings: list[Finding] = []
    for idx, item in enumerate(raw, start=1):
        if not isinstance(item, dict):
            raise ValueError(f"Finding #{idx} must be an object")

        title = str(item.get("title", "")).strip()
        summary = str(item.get("summary", "")).strip()
        priority = normalize_priority(str(item.get("priority", "")).strip())

        if not title:
            raise ValueError(f"Finding #{idx} missing required field: title")
        if not summary:
            raise ValueError(f"Finding #{idx} missing required field: summary")

        findings.append(
            Finding(
                title=title,
                priority=priority,
                summary=summary,
                why_this_matters=coerce_string_list(item.get("why_this_matters")),
                evidence=coerce_string_list(item.get("evidence")),
                root_cause_hypothesis=str(item.get("root_cause_hypothesis", "")).strip(),
                proposed_solution=coerce_string_list(item.get("proposed_solution")),
                acceptance_criteria=coerce_string_list(item.get("acceptance_criteria")),
                scope_and_risks=coerce_string_list(item.get("scope_and_risks")),
                type_label=normalize_type_label(item.get("type")),
                labels=coerce_string_list(item.get("labels")),
            )
        )

    return findings


def coerce_string_list(value: Any) -> list[str]:
    if value is None:
        return []
    if not isinstance(value, list):
        raise ValueError("Expected list for list-like field")

    result: list[str] = []
    for element in value:
        text = str(element).strip()
        if text:
            result.append(text)
    return result


def bullet(items: list[str]) -> str:
    if not items:
        return "- N/A"
    return "\n".join(f"- {item}" for item in items)


def checkboxes(items: list[str]) -> str:
    if not items:
        return "- [ ] Define acceptance criteria"
    return "\n".join(f"- [ ] {item}" for item in items)


def build_issue_body(f: Finding) -> str:
    return "\n".join(
        [
            "## Summary",
            f.summary,
            "",
            "## Why This Matters",
            bullet(f.why_this_matters),
            "",
            "## Evidence",
            bullet(f.evidence),
            "",
            "## Root Cause Hypothesis",
            f.root_cause_hypothesis or "- To be confirmed during implementation",
            "",
            "## Proposed Solution",
            bullet(f.proposed_solution),
            "",
            "## Acceptance Criteria",
            checkboxes(f.acceptance_criteria),
            "",
            "## Scope And Risks",
            bullet(f.scope_and_risks),
        ]
    )


def fetch_open_titles(repo: str) -> set[str]:
    data = run_gh_json(
        [
            "issue",
            "list",
            "--repo",
            repo,
            "--state",
            "open",
            "--limit",
            "200",
            "--json",
            "title",
        ]
    )
    if not data:
        return set()
    return {str(item["title"]).strip().lower() for item in data if isinstance(item, dict) and "title" in item}


def create_issue(repo: str, finding: Finding, dry_run: bool) -> str:
    labels = [finding.type_label, PRIORITY_LABELS[finding.priority], *finding.labels]
    unique_labels = list(dict.fromkeys(label for label in labels if label.strip()))

    issue_body = build_issue_body(finding)

    if dry_run:
        return f"DRY-RUN: {finding.title} [{finding.priority}] labels={','.join(unique_labels)}"

    args = [
        "api",
        f"repos/{repo}/issues",
        "--method",
        "POST",
        "-f",
        f"title={finding.title}",
        "-f",
        f"body={issue_body}",
    ]

    for label in unique_labels:
        args.extend(["-f", f"labels[]={label}"])

    response = run_gh_text(args)
    payload = json.loads(response)
    return str(payload.get("html_url", "")).strip() or "<created-without-url>"


def main() -> int:
    parser = argparse.ArgumentParser(description="Publish prioritized GitHub issues from findings JSON")
    parser.add_argument("--repo", required=True, help="GitHub repository in owner/repo format")
    parser.add_argument("--input", required=True, type=Path, help="Path to findings JSON file")
    parser.add_argument("--dry-run", action="store_true", help="Validate and print actions without creating issues")
    parser.add_argument(
        "--allow-duplicates",
        action="store_true",
        help="Create issues even if an open issue with the same title exists",
    )
    args = parser.parse_args()

    findings = load_findings(args.input)
    existing_titles = set() if args.allow_duplicates else fetch_open_titles(args.repo)

    created = 0
    skipped = 0

    for finding in findings:
        if finding.title.strip().lower() in existing_titles:
            skipped += 1
            print(f"SKIP duplicate title: {finding.title}")
            continue

        url = create_issue(args.repo, finding, dry_run=args.dry_run)
        created += 1
        print(url)

    print(f"\nSummary: created={created} skipped={skipped}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
