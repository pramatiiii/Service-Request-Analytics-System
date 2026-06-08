"""
analytics/stats.py
===================
Contains all statistical calculation functions.
These functions take the list of requests or the DataFrame and return
numerical summaries — counts, averages, breakdowns, rankings.

Why use both 'requests' (list of objects) and 'df' (DataFrame)?
----------------------------------------------------------------
- List of objects → used when we need OOP-style access (sr.failure_category)
- DataFrame → used when we need math operations (.mean(), .groupby(), .agg())
  pandas is optimised for this and makes the code much shorter and faster.
"""

from collections import Counter


def total_requests(requests):
    """
    Return the total number of service requests.

    Parameters
    ----------
    requests : list of ServiceRequest objects

    Returns
    -------
    int — total count

    len() is Python's built-in function for counting items in any sequence.
    """
    return len(requests)


def status_breakdown(requests):
    """
    Count how many requests exist for each status value.

    Parameters
    ----------
    requests : list of ServiceRequest objects

    Returns
    -------
    dict — e.g. {"Open": 120, "In Progress": 80, "Completed": 300}

    How it works:
    Counter is from Python's built-in 'collections' module.
    It takes any iterable and automatically counts occurrences of each value.

    Step 1: (sr.status for sr in requests)
        A generator expression that yields one status string at a time.
        Like a list comprehension but without building an intermediate list.

    Step 2: Counter(...)
        Counts how many times each unique status appears.
        Returns something like Counter({"Completed": 300, "Open": 120, ...})

    Step 3: dict(...)
        Converts Counter to a plain dictionary for simpler use elsewhere.
    """
    return dict(Counter(sr.status for sr in requests))


def priority_breakdown(requests):
    """
    Count how many requests exist for each priority level.

    Parameters
    ----------
    requests : list of ServiceRequest objects

    Returns
    -------
    dict — e.g. {"High": 150, "Medium": 220, "Low": 130}

    Same Counter pattern as status_breakdown() — only the attribute changes.
    """
    return dict(Counter(sr.priority for sr in requests))


def average_resolution_time(df):
    """
    Calculate the average resolution time across COMPLETED requests only.

    Parameters
    ----------
    df : pandas DataFrame (loaded from the CSV)

    Returns
    -------
    float — average hours, rounded to 2 decimal places. Returns 0.0 if none.

    Why exclude non-completed requests?
    -------------------------------------
    Open and In Progress tickets have Resolution_Time_Hours = 0 because
    they haven't been resolved yet. Including those zeros would drag the
    average down artificially — a statistical mistake called DATA CONTAMINATION.
    We only want the average of ACTUAL resolution times.

    How boolean indexing works:
        df["Status"] == "Completed"
        → creates a True/False column for every row

        df[df["Status"] == "Completed"]
        → keeps only the rows where the condition is True
        → this is called BOOLEAN INDEXING in pandas

    .mean() then calculates the arithmetic average of the filtered column.
    """

    # Filter: keep only rows where Status is Completed
    completed = df[df["Status"] == "Completed"]

    # Guard: if there are no completed rows, return 0 to avoid errors
    if completed.empty:
        return 0.0

    return round(completed["Resolution_Time_Hours"].mean(), 2)


def top_failure_categories(requests, n=5):
    """
    Return the top-N most common failure categories by occurrence count.

    Parameters
    ----------
    requests : list of ServiceRequest objects
    n        : how many top categories to return (default: 5)

    Returns
    -------
    list of tuples — e.g. [("Electrical", 74), ("Sensor", 67), ...]

    How it works:
    Step 1: Extract just the failure_category from every request
        [sr.failure_category for sr in requests]
        → ["Electrical", "Hydraulic", "Electrical", "Sensor", ...]

    Step 2: Counter counts each unique value
        Counter({...}) → {"Electrical": 74, "Sensor": 67, ...}

    Step 3: .most_common(n) returns top-n as a sorted list of (value, count) tuples
        [("Electrical", 74), ("Sensor", 67), ("Mechanical", 63), ...]
    """

    # Build a list of all failure categories from every request
    categories = [sr.failure_category for sr in requests]

    # Count and return the top n
    return Counter(categories).most_common(n)


def technician_performance(df):
    """
    For each technician: count completed jobs and calculate average resolution time.

    Parameters
    ----------
    df : pandas DataFrame

    Returns
    -------
    pandas DataFrame with columns:
        Technician, Completed_Requests, Avg_Resolution_Time
    Sorted by Completed_Requests descending (best performer first).

    How groupby works — the Split / Apply / Combine pattern:
    ---------------------------------------------------------
    Think of it like sorting cards into piles, then counting each pile.

    Step 1 — FILTER:
        Keep only rows where Status == "Completed"

    Step 2 — SPLIT (groupby):
        Split the table into one mini-table per technician.
        If there are 8 technicians, you get 8 groups.

    Step 3 — APPLY (agg):
        For each group, apply two functions:
          • count on SR_ID     → how many completed jobs
          • mean  on hours     → average speed

    Step 4 — COMBINE:
        Merge all group results back into a single table.

    Step 5 — reset_index():
        After groupby, "Technician" becomes the row label (index).
        reset_index() promotes it back to a normal column.

    Step 6 — sort_values():
        Order by most completions first (ascending=False = highest first).

    SQL equivalent:
        SELECT Technician, COUNT(SR_ID), AVG(Resolution_Time_Hours)
        FROM service_requests
        WHERE Status = 'Completed'
        GROUP BY Technician
        ORDER BY COUNT(SR_ID) DESC
    """

    # Step 1: Keep only completed tickets
    completed_df = df[df["Status"] == "Completed"]

    # Steps 2–4: groupby → agg
    # Named aggregation syntax: NewColumnName=("SourceColumn", "function")
    performance = (
        completed_df
        .groupby("Technician")
        .agg(
            Completed_Requests  = ("SR_ID", "count"),
            Avg_Resolution_Time = ("Resolution_Time_Hours", "mean"),
        )
        .reset_index()                                          # Step 5
        .sort_values("Completed_Requests", ascending=False)    # Step 6
    )

    # Round average to 2 decimal places for cleaner display
    performance["Avg_Resolution_Time"] = performance["Avg_Resolution_Time"].round(2)

    return performance
