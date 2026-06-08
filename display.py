"""
reports/display.py
===================
Contains all functions that print formatted tables and summaries
directly to the terminal.

Why separate from the other report files?
------------------------------------------
text_report.py  → writes to a .txt file
charts.py       → writes to .png files
excel_report.py → writes to an .xlsx file
display.py      → prints to the terminal (standard output / stdout)

Each output destination lives in its own file. If you ever want to change
how something is displayed on screen, you only edit this one file.
"""

from analytics.filters import get_high_priority_requests, get_completed_requests
from analytics.stats   import (
    status_breakdown,
    priority_breakdown,
    average_resolution_time,
    top_failure_categories,
    technician_performance,
    total_requests,
)


def show_summary(requests, df):
    """
    Print a concise summary of all key statistics to the terminal.

    Parameters
    ----------
    requests : list of ServiceRequest objects
    df       : pandas DataFrame (needed for average_resolution_time)
    """
    sb       = status_breakdown(requests)
    pb       = priority_breakdown(requests)
    avg_time = average_resolution_time(df)
    failures = top_failure_categories(requests, n=5)

    print(f"\n  {'─' * 42}")
    print(f"  {'SUMMARY':^42}")
    print(f"  {'─' * 42}")
    print(f"  {'Total Requests':<25}: {total_requests(requests)}")
    print()
    print(f"  Status Breakdown")

    # Loop in a fixed order so output is always consistent regardless of dict order
    for status in ["Open", "In Progress", "Completed"]:
        print(f"    {status:<20}: {sb.get(status, 0)}")

    print()
    print(f"  Priority Breakdown")
    for priority in ["High", "Medium", "Low"]:
        print(f"    {priority:<20}: {pb.get(priority, 0)}")

    print()
    print(f"  {'Avg Resolution Time':<25}: {avg_time} hrs")
    print()
    print(f"  Top 5 Failure Categories")

    # enumerate(iterable, start=1) → gives (1, item), (2, item), ...
    for rank, (category, count) in enumerate(failures, start=1):
        print(f"    {rank}. {category:<22} ({count} occurrences)")

    print(f"  {'─' * 42}\n")


def show_open_requests(requests):
    """
    Print a formatted table of all Open requests.

    Only shows the first 25 to avoid flooding the terminal.
    If there are more, a note is shown at the bottom.

    Parameters
    ----------
    requests : list of ServiceRequest objects
    """
    open_reqs = [sr for sr in requests if sr.status == "Open"]
    total     = len(open_reqs)

    print(f"\n  {'─' * 72}")
    print(f"  OPEN REQUESTS  ({total} total)")
    print(f"  {'─' * 72}")

    # f-string field width formatting: {value:<N} = left-align in N-character wide field
    # This ensures columns line up regardless of the actual string length
    print(f"  {'SR_ID':<8} {'Customer':<22} {'Machine':<22} {'Priority':<10} {'Date'}")
    print(f"  {'─' * 72}")

    # Show at most 25 rows to avoid flooding the terminal
    for sr in open_reqs[:25]:
        print(
            f"  {sr.sr_id:<8} "
            f"{sr.customer_name[:20]:<22} "
            f"{sr.machine_type:<22} "
            f"{sr.priority:<10} "
            f"{sr.reported_date}"
        )

    if total > 25:
        print(f"  ... and {total - 25} more records")

    print(f"  {'─' * 72}\n")


def show_high_priority_requests(requests):
    """
    Print a formatted table of all High priority requests.

    Parameters
    ----------
    requests : list of ServiceRequest objects
    """
    hp    = get_high_priority_requests(requests)
    total = len(hp)

    print(f"\n  {'─' * 72}")
    print(f"  HIGH PRIORITY REQUESTS  ({total} total)")
    print(f"  {'─' * 72}")
    print(f"  {'SR_ID':<8} {'Customer':<22} {'Machine':<22} {'Status':<14} {'Technician'}")
    print(f"  {'─' * 72}")

    for sr in hp:
        print(
            f"  {sr.sr_id:<8} "
            f"{sr.customer_name[:20]:<22} "
            f"{sr.machine_type:<22} "
            f"{sr.status:<14} "
            f"{sr.technician}"
        )

    print(f"  {'─' * 72}\n")


def show_completed_requests(requests):
    """
    Print a formatted table of all Completed requests with resolution times.

    Parameters
    ----------
    requests : list of ServiceRequest objects
    """
    completed = get_completed_requests(requests)
    total     = len(completed)

    print(f"\n  {'─' * 76}")
    print(f"  COMPLETED REQUESTS  ({total} total)")
    print(f"  {'─' * 76}")
    print(f"  {'SR_ID':<8} {'Customer':<22} {'Technician':<22} {'Res. Time (hrs)':<18} {'Priority'}")
    print(f"  {'─' * 76}")

    for sr in completed[:25]:
        print(
            f"  {sr.sr_id:<8} "
            f"{sr.customer_name[:20]:<22} "
            f"{sr.technician[:20]:<22} "
            f"{sr.resolution_time_hours:<18} "
            f"{sr.priority}"
        )

    if total > 25:
        print(f"  ... and {total - 25} more records")

    print(f"  {'─' * 76}\n")


def show_technician_performance(df):
    """
    Print a formatted table of technician performance metrics.

    Parameters
    ----------
    df : pandas DataFrame

    Uses pandas itertuples() to iterate over DataFrame rows efficiently.
    itertuples() returns each row as a named tuple — accessible by attribute name.
    """
    perf = technician_performance(df)

    print(f"\n  {'─' * 52}")
    print(f"  TECHNICIAN PERFORMANCE")
    print(f"  {'─' * 52}")
    print(f"  {'Technician':<24} {'Completed':<12} {'Avg Hrs'}")
    print(f"  {'─' * 52}")

    # itertuples(index=False) loops over rows without the integer index
    # Each row is accessible like: row.Technician, row.Completed_Requests
    for row in perf.itertuples(index=False):
        print(
            f"  {row.Technician[:22]:<24} "
            f"{row.Completed_Requests:<12} "
            f"{row.Avg_Resolution_Time}"
        )

    print(f"  {'─' * 52}\n")
