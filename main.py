"""
main.py
========
The single entry point for the entire application.

This is the ONLY file you need to run. It:
    1. Generates the CSV data (if it doesn't already exist)
    2. Loads the data into objects and a DataFrame
    3. Generates all reports (text, charts, Excel)
    4. Starts the interactive CLI menu (if --cli flag is passed)

Why keep main.py minimal?
--------------------------
main.py's only job is to wire the other modules together.
It does NOT contain any logic itself — it just calls functions
from the other files in the correct order.

This is called the FACADE pattern — one simple entry point that
hides the complexity of the underlying system.

How to run:
-----------
    # Generate all reports and exit:
    python main.py

    # Generate all reports then open the interactive menu:
    python main.py --cli
"""

import os
import sys

# ── Import from our own modules ────────────────────────────────────────────────
# Each import pulls in a specific function from a specific file.
# This is what makes the modular structure valuable — each file has a clear purpose.

from utils.data_generator  import generate_csv
from analytics.loader      import load_requests, load_dataframe
from reports.text_report   import generate_text_report
from reports.charts        import generate_all_charts
from reports.excel_report  import generate_excel_report
from cli                   import run_cli


# ── Configuration ──────────────────────────────────────────────────────────────
CSV_FILE   = "service_requests.csv"   # Input data file
OUTPUT_DIR = "output"                 # Folder for all generated output files


def main():
    """
    Main function — runs the full pipeline from data to reports.

    Pipeline steps:
        Step 1: Generate CSV if it doesn't exist yet
        Step 2: Load data into ServiceRequest objects and a DataFrame
        Step 3: Generate all outputs (text report, charts, Excel)
        Step 4: Optionally launch the interactive CLI menu
    """

    print("\n" + "=" * 52)
    print("  Service Request Analytics System")
    print("=" * 52)

    # ── Step 1: Data generation ────────────────────────────────────────────────
    # os.path.exists() checks if the file already exists
    # We only generate it if it's missing — avoids overwriting data on re-runs
    if not os.path.exists(CSV_FILE):
        print("\n  [→] Generating sample data...")
        generate_csv(filepath=CSV_FILE, num_records=500)
    else:
        print(f"\n  [→] Using existing data file: {CSV_FILE}")

    # ── Step 2: Load data ──────────────────────────────────────────────────────
    print("\n  [→] Loading data...")
    requests = load_requests(CSV_FILE)    # List of ServiceRequest objects
    df       = load_dataframe(CSV_FILE)   # pandas DataFrame of the same data
    print(f"  [✓] Loaded {len(requests)} service requests.")

    # ── Step 3: Generate all outputs ──────────────────────────────────────────
    print("\n  [→] Generating reports and charts...")
    generate_text_report(requests, df, OUTPUT_DIR)
    generate_all_charts(requests, OUTPUT_DIR)
    generate_excel_report(requests, df, OUTPUT_DIR)

    print(f"\n  [✓] All outputs saved to: {OUTPUT_DIR}/")
    print("      ├── summary_report.txt")
    print("      ├── priority_chart.png")
    print("      ├── status_chart.png")
    print("      ├── failure_chart.png")
    print("      └── analytics_report.xlsx")

    # ── Step 4: CLI menu (optional) ───────────────────────────────────────────
    # sys.argv is a list of command-line arguments.
    # Running "python main.py --cli" makes sys.argv = ["main.py", "--cli"]
    # Checking if "--cli" is in that list lets the user opt into the interactive menu.
    if "--cli" in sys.argv:
        run_cli(requests, df, OUTPUT_DIR)
    else:
        print("\n  Tip: Run with --cli flag for the interactive menu.")
        print("  Example: python main.py --cli\n")


# ── Entry point guard ──────────────────────────────────────────────────────────
# __name__ == "__main__" is True only when this file is executed directly.
# If another file were to import main.py, this block would NOT run.
# This is a Python best practice — it prevents side effects from imports.
if __name__ == "__main__":
    main()
