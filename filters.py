"""
analytics/filters.py
=====================
Contains all filtering functions — functions that search through the list
of ServiceRequest objects and return only those matching a condition.

Why separate from stats.py?
Filtering (which records?) and statistics (what numbers?) are two different
types of operations. Keeping them in separate files makes each file shorter,
easier to read, and easier to test individually.
"""


def get_open_requests(requests):
    """
    Return all service requests with Status == 'Open'.

    Parameters
    ----------
    requests : list of ServiceRequest objects

    Returns
    -------
    A new list containing only the Open requests.
    The original list is NOT modified (non-destructive filtering).

    How it works — list comprehension
    -----------------------------------
    [sr for sr in requests if sr.status == "Open"]

    This is equivalent to:
        result = []
        for sr in requests:
            if sr.status == "Open":
                result.append(sr)
        return result

    The list comprehension is just a shorter, more Pythonic way to write
    the same logic. 'sr' is the loop variable — it represents one
    ServiceRequest object at a time as Python walks through the list.
    """
    return [sr for sr in requests if sr.status == "Open"]


def get_high_priority_requests(requests):
    """
    Return all service requests with Priority == 'High'.

    Parameters
    ----------
    requests : list of ServiceRequest objects

    Returns
    -------
    A new list containing only High priority requests.

    Same list comprehension pattern as get_open_requests(),
    but the condition checks sr.priority instead of sr.status.
    """
    return [sr for sr in requests if sr.priority == "High"]


def get_completed_requests(requests):
    """
    Return all service requests with Status == 'Completed'.

    Parameters
    ----------
    requests : list of ServiceRequest objects

    Returns
    -------
    A new list containing only Completed requests.

    Used by:
    - show_completed_requests() in reports/display.py
    - The Excel exporter for the "Completed Requests" sheet
    """
    return [sr for sr in requests if sr.status == "Completed"]


def get_requests_by_technician(requests, technician_name):
    """
    Return all requests assigned to a specific technician.

    Parameters
    ----------
    requests         : list of ServiceRequest objects
    technician_name  : exact name string to match

    Returns
    -------
    A new list of requests for that technician.

    The .lower() comparison makes the match case-insensitive:
    "raj kumar" and "Raj Kumar" will both match "RAJ KUMAR".
    """
    return [
        sr for sr in requests
        if sr.technician.lower() == technician_name.lower()
    ]


def get_requests_by_priority(requests, priority):
    """
    Return all requests matching a given priority level.

    Parameters
    ----------
    requests : list of ServiceRequest objects
    priority : "High", "Medium", or "Low"

    Returns
    -------
    A filtered list of ServiceRequest objects.
    """
    return [sr for sr in requests if sr.priority == priority]
