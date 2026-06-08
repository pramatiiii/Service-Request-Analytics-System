"""
reports/text_report.py
=======================
Generates the plain-text summary report: output/summary_report.txt

Why plain text?
Plain .txt files are universally readable — no software required.
They're ideal for logs, audit trails, and quick summaries that
need to be readable on any machine or operating system.
"""

import os
from datetime import datetime
from analytics.stats import (
    status_breakdown,
    priority_breakdown,
    average_resolution_time,
    top_failure_categories,
)


def generate_text_report(requests, df, output_dir="output"):
    """
    Write a formatted plain-text summary report to output/summary_report.txt.

    Parameters
    ----------
    requests   : list of ServiceRequest objects
    df         : pandas DataFrame (same data, used for average calculation)
    output_dir : folder to save the report in (default: "output")

    Returns
    -------
    str — the full file path of the saved report

    How the file is built:
    ----------------------
    We first build a list of strings (one per line), then join them with
    newline characters and write the whole thing in one operation.

    "\n".join(lines) is more efficient than calling f.write() repeatedly
    because it makes one single write call to disk instead of many small ones.
    """

    # Create the output folder if it doesn't exist
    # exist_ok=True means: don't raise an error if the folder is already there
    os.makedirs(output_dir, exist_ok=True)

    # Build the output file path in a cross-platform safe way
    # os.path.join uses the correct separator for each OS (/ on Mac/Linux, \ on Windows)
    filepath = os.path.join(output_dir, "summary_report.txt")

    # ── Gather all statistics first ─────────────────────────────────────────
    sb          = status_breakdown(requests)
    pb          = priority_breakdown(requests)
    avg_time    = average_resolution_time(df)
    top_failures = top_failure_categories(requests, n=5)

    # ── Build the report as a list of lines ─────────────────────────────────
    lines = [
        "=" * 52,
        "      SERVICE REQUEST ANALYTICS REPORT",
        "=" * 52,
        f"  Generated : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "  OVERVIEW",
        f"  {'Total Requests':<22}: {len(requests)}",
        "",
        "  STATUS BREAKDOWN",
    ]

    # Loop through statuses in a fixed order (not dict order) for consistency
    for status in ["Open", "In Progress", "Completed"]:
        lines.append(f"    {status:<20}: {sb.get(status, 0)}")

    lines += ["", "  PRIORITY BREAKDOWN"]
    for priority in ["High", "Medium", "Low"]:
        lines.append(f"    {priority:<20}: {pb.get(priority, 0)}")

    lines += [
        "",
        f"  {'Avg Resolution Time':<22}: {avg_time} Hours",
        "",
        "  TOP 5 FAILURE CATEGORIES",
    ]

    # enumerate starts rank at 1 (not 0) for human-readable numbering
    for rank, (category, count) in enumerate(top_failures, start=1):
        lines.append(f"    {rank}. {category:<22} ({count} occurrences)")

    lines += ["", "=" * 52]

    # ── Write to file ────────────────────────────────────────────────────────
    # "\n".join(lines) connects all strings with a newline between each one
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"[✓] Text report saved   → {filepath}")
    return filepath
