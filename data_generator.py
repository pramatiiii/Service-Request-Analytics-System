"""
utils/data_generator.py
========================
Responsible for generating realistic fake service request data and saving it as a CSV.

Why a separate file for this?
Data generation is a utility task — it only runs once to create the dataset.
Keeping it separate means the rest of the program never needs to know HOW
the data was made. This is called SEPARATION OF CONCERNS.

Library used: Faker
-------------------
Faker is a Python library that generates realistic fake data — names, addresses,
company names, dates, and more. It is much more realistic than random strings.

Install: pip install faker
Docs:    https://faker.readthedocs.io
"""

import csv
import random
from faker import Faker

# Create a Faker instance set to English (India locale for realistic names)
# Faker uses this locale to generate names, companies, etc. appropriate for the region
fake = Faker("en_IN")


# ── Pool values ────────────────────────────────────────────────────────────────
# These are the fixed lists of valid values for certain columns.
# We pick randomly from these pools so the data looks realistic and consistent.

MACHINE_TYPES = [
    "CNC Machine",
    "Lathe Machine",
    "Hydraulic Press",
    "Conveyor Belt",
    "Robotic Arm",
    "Welding Machine",
    "Milling Machine",
    "Drilling Machine",
]

FAILURE_CATEGORIES = [
    "Electrical",
    "Hydraulic",
    "Mechanical",
    "Sensor",
    "Software",
    "Pneumatic",
    "Lubrication",
    "Structural",
]

PRIORITIES = ["High", "Medium", "Low"]
STATUSES   = ["Open", "In Progress", "Completed"]

# Weighted probability distributions
# These make the data realistic — in real service systems, most tickets are
# eventually Completed, and Medium priority is most common.
#
# Format: weights must match the order of the list above
#   Status  → Open 24%, In Progress 16%, Completed 60%
#   Priority→ High 30%, Medium 44%, Low 26%
STATUS_WEIGHTS   = [0.24, 0.16, 0.60]
PRIORITY_WEIGHTS = [0.30, 0.44, 0.26]


def generate_csv(filepath="service_requests.csv", num_records=500):
    """
    Generate a CSV file with realistic fake service request data.

    Parameters
    ----------
    filepath    : where to save the CSV file (default: service_requests.csv)
    num_records : how many rows to generate (default: 500)

    How it works
    ------------
    1. For each record, Faker generates a realistic company name and technician name
    2. Status and Priority are randomly chosen using weighted probabilities
    3. Resolution time is only set for Completed tickets (0 for Open/In Progress)
    4. High-priority tickets resolve faster than Low-priority ones (realistic behaviour)
    5. All rows are written to the CSV using csv.DictWriter
    """

    rows = []  # This list will hold all 500 row dictionaries before writing

    for i in range(1, num_records + 1):

        # Zero-padded IDs: i=1 → "SR001", i=42 → "SR042", i=500 → "SR500"
        # The :03d format means: integer, minimum 3 digits, pad with zeros
        sr_id    = f"SR{i:03d}"
        asset_id = f"AST{random.randint(1, 100):03d}"

        # Faker generates realistic Indian company names and person names
        customer_name = fake.company()
        technician    = fake.name()
        machine_type  = random.choice(MACHINE_TYPES)

        # Faker generates a date between two dates (within year 2024)
        # date_between returns a datetime.date object; strftime converts it to a string
        reported_date = fake.date_between(
            start_date="-1y",   # one year ago
            end_date="today"    # up to today
        ).strftime("%Y-%m-%d")

        # random.choices with weights: picks one value based on probability
        # The [0] at the end extracts the single chosen item from the returned list
        status   = random.choices(STATUSES,   weights=STATUS_WEIGHTS)[0]
        priority = random.choices(PRIORITIES, weights=PRIORITY_WEIGHTS)[0]

        failure_category = random.choice(FAILURE_CATEGORIES)

        # Resolution time logic:
        # - Completed tickets: time depends on priority (High = faster, Low = slower)
        # - Open / In Progress tickets: 0 hours (not yet resolved)
        # This is called REFERENTIAL INTEGRITY — one column's value makes sense
        # relative to another column's value
        if status == "Completed":
            if priority == "High":
                resolution_time = random.randint(2, 16)    # Fast resolution
            elif priority == "Medium":
                resolution_time = random.randint(8, 36)    # Moderate resolution
            else:
                resolution_time = random.randint(16, 72)   # Slower resolution
        else:
            resolution_time = 0  # Not yet resolved — no time to record

        # Each row is stored as a dictionary {column_name: value}
        rows.append({
            "SR_ID":                 sr_id,
            "Asset_ID":              asset_id,
            "Customer_Name":         customer_name,
            "Machine_Type":          machine_type,
            "Reported_Date":         reported_date,
            "Priority":              priority,
            "Status":                status,
            "Technician":            technician,
            "Resolution_Time_Hours": resolution_time,
            "Failure_Category":      failure_category,
        })

    # Write all rows to CSV
    # fieldnames defines the column order in the output file
    fieldnames = list(rows[0].keys())

    # 'with open(...)' is a context manager — it automatically closes the file
    # even if an error occurs, preventing resource leaks
    # newline="" is required for csv.writer to avoid blank lines on Windows
    with open(filepath, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()   # writes the column names as the first line
        writer.writerows(rows) # writes all 500 data rows

    print(f"[✓] Generated {num_records} records → {filepath}")
    return filepath
