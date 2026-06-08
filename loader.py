"""
analytics/loader.py
====================
Responsible for reading the CSV file and converting each row into
a ServiceRequest object and a pandas DataFrame.

Why a separate loader?
The loading logic (reading files, handling errors, building objects) is
distinct from the analysis logic (calculating averages, grouping, filtering).
Keeping them separate means if the CSV format ever changes, you only edit
this one file — not the entire analytics system.
"""

import csv
import pandas as pd
from models.service_request import ServiceRequest


def load_requests(csv_path):
    """
    Read a CSV file and return a list of ServiceRequest objects.

    Parameters
    ----------
    csv_path : path to the CSV file to read

    Returns
    -------
    requests : list of ServiceRequest objects (one per row)

    How it works
    ------------
    csv.DictReader reads the CSV and uses the first row (headers) as
    dictionary keys. So each row becomes a dict like:
        {"SR_ID": "SR001", "Priority": "High", "Status": "Open", ...}

    We then create a ServiceRequest object from each dict, mapping the
    uppercase CSV column names to the lowercase attribute names expected
    by the ServiceRequest constructor.
    """

    requests = []  # Will hold all ServiceRequest objects

    # 'with open(...)' is a context manager
    # It guarantees the file is closed when the block ends — even on error
    with open(csv_path, newline="", encoding="utf-8") as f:

        # DictReader automatically uses the header row as dictionary keys
        reader = csv.DictReader(f)

        for row in reader:
            # Create a ServiceRequest for each row
            # We map CSV column names (uppercase) to constructor parameters (lowercase)
            # This handles the naming mismatch: CSV uses "SR_ID", class uses "sr_id"
            sr = ServiceRequest(
                sr_id                 = row["SR_ID"],
                asset_id              = row["Asset_ID"],
                customer_name         = row["Customer_Name"],
                machine_type          = row["Machine_Type"],
                reported_date         = row["Reported_Date"],
                priority              = row["Priority"],
                status                = row["Status"],
                technician            = row["Technician"],
                resolution_time_hours = row["Resolution_Time_Hours"],
                failure_category      = row["Failure_Category"],
            )
            requests.append(sr)

    return requests


def load_dataframe(csv_path):
    """
    Read the same CSV into a pandas DataFrame.

    Parameters
    ----------
    csv_path : path to the CSV file

    Returns
    -------
    df : pandas DataFrame

    Why a DataFrame in addition to objects?
    ----------------------------------------
    ServiceRequest objects are great for clean OOP access (sr.priority).
    But for math operations — averages, grouping, filtering — pandas is
    far more powerful and concise. We keep both representations and use
    whichever is more appropriate for each task.

    pd.to_numeric + fillna(0):
        Converts the Resolution_Time_Hours column to numbers safely.
        If any value is missing or non-numeric, it becomes 0 instead of crashing.
    """

    df = pd.read_csv(csv_path)

    # Ensure resolution time is treated as a number, not a string
    df["Resolution_Time_Hours"] = pd.to_numeric(
        df["Resolution_Time_Hours"], errors="coerce"
    ).fillna(0)

    return df
