# Service Request Analytics System

A Python application that simulates a real-world service management system.
It generates realistic service ticket data, analyses it, and produces formatted
reports as a text file, PNG charts, and a styled Excel workbook — all accessible
through an interactive CLI menu.

---

## What the project does

1. **Generates** 500 fake-but-realistic service request records using the Faker library
2. **Loads** them into Python objects and a pandas DataFrame
3. **Analyses** the data: counts, averages, rankings, technician performance
4. **Reports** the results as a `.txt` summary, three `.png` charts, and a `.xlsx` workbook
5. **Provides** an interactive terminal menu to explore the data live

---

## Project structure

```
service_analytics/
│
├── main.py                         ← Entry point. Run this file.
├── cli.py                          ← Interactive CLI menu
│
├── models/
│   ├── __init__.py
│   └── service_request.py          ← ServiceRequest class (one ticket = one object)
│
├── utils/
│   ├── __init__.py
│   └── data_generator.py           ← Generates service_requests.csv using Faker
│
├── analytics/
│   ├── __init__.py
│   ├── loader.py                   ← Reads CSV → ServiceRequest objects + DataFrame
│   ├── filters.py                  ← Filter functions (open, high priority, etc.)
│   └── stats.py                    ← Statistical calculations (averages, groupby, etc.)
│
├── reports/
│   ├── __init__.py
│   ├── text_report.py              ← Writes output/summary_report.txt
│   ├── charts.py                   ← Writes output/priority/status/failure .png charts
│   ├── excel_report.py             ← Writes output/analytics_report.xlsx
│   └── display.py                  ← Prints formatted tables to the terminal
│
├── output/                         ← All generated files go here (auto-created)
│   ├── summary_report.txt
│   ├── priority_chart.png
│   ├── status_chart.png
│   ├── failure_chart.png
│   └── analytics_report.xlsx
│
├── service_requests.csv            ← Auto-generated on first run
└── requirements.txt                ← Python dependencies
```

---

## Setup and installation

### Step 1 — Install Python
This project requires Python 3.8 or higher.
Check your version: `python --version`

### Step 2 — Install dependencies
```bash
pip install -r requirements.txt
```

Or install manually:
```bash
pip install pandas matplotlib openpyxl faker
```

### Step 3 — Run the application
```bash
# Generate all reports and exit:
python main.py

# Generate all reports then open the interactive menu:
python main.py --cli
```

---

## CLI menu options

```
========================================
  Service Request Analytics System
========================================
  1. View Summary
  2. View Open Requests
  3. View High Priority Requests
  4. View Completed Requests
  5. View Technician Performance
  6. Generate Charts
  7. Export to Excel
  8. Generate Full Report (all outputs)
  9. Exit
========================================
```

---

## Output files

| File | Type | Contents |
|---|---|---|
| `summary_report.txt` | Text | Total requests, status/priority breakdown, avg resolution time, top failures |
| `priority_chart.png` | Image | Bar chart — High / Medium / Low priority distribution |
| `status_chart.png` | Image | Pie chart — Open / In Progress / Completed distribution |
| `failure_chart.png` | Image | Horizontal bar chart — top 5 failure categories |
| `analytics_report.xlsx` | Excel | 6 sheets: Summary, All Requests, High Priority, Completed, Technician Performance, Failure Categories |

---

## Libraries used

### Built-in (no installation needed)
| Library | Used for |
|---|---|
| `csv` | Reading and writing CSV files |
| `random` | Weighted random selection for data generation |
| `os` | File system operations (create folders, build paths) |
| `datetime` | Date generation and timestamp formatting |
| `collections.Counter` | Counting occurrences of categorical values |
| `sys` | Reading command-line arguments (`--cli` flag) |

### External (install via pip)
| Library | Used for |
|---|---|
| `faker` | Generating realistic fake names, companies, and dates |
| `pandas` | Data loading, filtering, groupby aggregations |
| `matplotlib` | Creating and saving bar and pie charts as PNG files |
| `openpyxl` | Creating formatted Excel workbooks with colours and styles |

---

## Key concepts used in this project

| Concept | Where it appears |
|---|---|
| **OOP / Classes** | `ServiceRequest` class in `models/service_request.py` |
| **Encapsulation** | All ticket data bundled into one `ServiceRequest` object |
| **Separation of Concerns** | Each folder (models, analytics, reports) has one responsibility |
| **List comprehensions** | All filter functions in `analytics/filters.py` |
| **pandas groupby** | `technician_performance()` in `analytics/stats.py` |
| **Boolean indexing** | `average_resolution_time()` — filtering completed rows only |
| **Counter** | `top_failure_categories()` and breakdowns in `analytics/stats.py` |
| **Context manager** | `with open(...) as f` in loader and report files |
| **Event loop** | `while True` + `break` pattern in `cli.py` |
| **Weighted randomness** | `random.choices(..., weights=[...])` in `data_generator.py` |
| **Faker library** | Realistic company/person names in `data_generator.py` |
| **matplotlib fig/ax** | Two-layer chart model in `reports/charts.py` |
| **openpyxl styling** | Cell colours, fonts, freeze panes in `reports/excel_report.py` |
| **`__name__ == "__main__"`** | Entry point guard in `main.py` |

---

## How to extend this project

- **Add a new filter** → add a function to `analytics/filters.py`
- **Add a new chart** → add a function to `reports/charts.py`
- **Add a new Excel sheet** → add a block inside `generate_excel_report()` in `reports/excel_report.py`
- **Add a new CLI option** → add an `elif` branch in `cli.py`
- **Change the data schema** → edit the column pools in `utils/data_generator.py` and update `models/service_request.py`

---

## Requirements

See `requirements.txt`:
```
faker>=19.0.0
pandas>=1.5.0
matplotlib>=3.6.0
openpyxl>=3.1.0
```
