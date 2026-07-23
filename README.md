# 🎫 Service Request Analytics System

![Python](https://img.shields.io/badge/Python-3.8+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Pandas](https://img.shields.io/badge/Pandas-150458?style=for-the-badge&logo=pandas&logoColor=white)
![Matplotlib](https://img.shields.io/badge/Matplotlib-11557C?style=for-the-badge)
![OpenPyXL](https://img.shields.io/badge/OpenPyXL-217346?style=for-the-badge)
![Faker](https://img.shields.io/badge/Faker-FF69B4?style=for-the-badge)

A **Python application** built with **pandas**, **Faker**, **Matplotlib**, and **OpenPyXL** that simulates a real-world service management system — generating realistic ticket data, analyzing it, and producing formatted reports through an interactive CLI menu.

---

## 📑 Table of Contents

- Overview
- Features
- Tech Stack
- Project Structure
- Getting Started
- Running the Application
- CLI Menu
- Output Files
- Example Output
- How It Works
- Key Concepts Demonstrated
- Extending the Project
- Future Improvements
- Author

---

# 📖 Overview

Service Request Analytics System is a self-contained Python application that models an IT/service helpdesk end-to-end.

Instead of manually digging through spreadsheets, the app generates synthetic ticket data, analyzes it with pandas, and automatically produces text, chart, and Excel reports — all explorable live through a terminal menu.

This project demonstrates:

- Object-Oriented Programming
- Data Analysis with Pandas
- Synthetic Data Generation with Faker
- Chart Generation with Matplotlib
- Excel Report Automation with OpenPyXL
- Interactive CLI Design

---

# ✨ Features

- 🚀 Generates 500 realistic, randomized service ticket records using Faker
- 📊 Loads data into both custom Python objects and a pandas DataFrame
- 🔍 Calculates counts, averages, technician rankings, and top failure categories
- 📄 Produces a `.txt` summary report
- 🖼️ Produces three `.png` charts
- 📈 Produces a multi-sheet, styled `.xlsx` workbook
- 💻 Interactive terminal menu for exploring data live

---

# 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| Python | Core application logic |
| Pandas | Data loading, filtering, groupby aggregations |
| Faker | Generating realistic fake names, companies, and dates |
| Matplotlib | Creating and saving bar and pie charts as PNG files |
| OpenPyXL | Creating formatted Excel workbooks with colors and styles |
| CSV / os / datetime / Counter / sys | Built-in file handling, data generation, and CLI argument parsing |

---

# 📂 Project Structure

```
service_analytics/
│
├── main.py                         # Entry point. Run this file.
├── cli.py                          # Interactive CLI menu
│
├── models/
│   ├── __init__.py
│   └── service_request.py          # ServiceRequest class (one ticket = one object)
│
├── utils/
│   ├── __init__.py
│   └── data_generator.py           # Generates service_requests.csv using Faker
│
├── analytics/
│   ├── __init__.py
│   ├── loader.py                   # Reads CSV → ServiceRequest objects + DataFrame
│   ├── filters.py                  # Filter functions (open, high priority, etc.)
│   └── stats.py                    # Statistical calculations (averages, groupby, etc.)
│
├── reports/
│   ├── __init__.py
│   ├── text_report.py              # Writes output/summary_report.txt
│   ├── charts.py                   # Writes output/priority/status/failure .png charts
│   ├── excel_report.py             # Writes output/analytics_report.xlsx
│   └── display.py                  # Prints formatted tables to the terminal
│
├── output/                         # All generated files go here (auto-created)
│   ├── summary_report.txt
│   ├── priority_chart.png
│   ├── status_chart.png
│   ├── failure_chart.png
│   └── analytics_report.xlsx
│
├── service_requests.csv            # Auto-generated on first run
└── requirements.txt                # Python dependencies
```

---

# 🚀 Getting Started

## Prerequisites

Install the following before running the project:

- Python 3.8+
- pip
- Visual Studio Code (Recommended)

---

## Clone the Repository

```bash
git clone https://github.com/pramatiiii/service-request-analytics.git

cd service-request-analytics
```

---

## Create Virtual Environment

### Windows

```bash
python -m venv .venv

.venv\Scripts\activate
```

### macOS/Linux

```bash
python3 -m venv .venv

source .venv/bin/activate
```

---

## Install Dependencies

```bash
pip install -r requirements.txt
```

Or install manually:

```bash
pip install pandas matplotlib openpyxl faker
```

---

# ▶️ Running the Application

Generate all reports and exit:

```bash
python main.py
```

Generate all reports, then open the interactive menu:

```bash
python main.py --cli
```

---

# 📋 CLI Menu

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

# 📁 Output Files

| File | Type | Contents |
|---|---|---|
| `summary_report.txt` | Text | Total requests, status/priority breakdown, avg resolution time, top failures |
| `priority_chart.png` | Image | Bar chart — High / Medium / Low priority distribution |
| `status_chart.png` | Image | Pie chart — Open / In Progress / Completed distribution |
| `failure_chart.png` | Image | Horizontal bar chart — top 5 failure categories |
| `analytics_report.xlsx` | Excel | 6 sheets: Summary, All Requests, High Priority, Completed, Technician Performance, Failure Categories |

---

# 📤 Example Output

```
====== SUMMARY ======
Total Requests: 500
Open: 142   In Progress: 118   Completed: 240
Avg Resolution Time: 3.4 days

Top Failure Categories:
1. Network Connectivity   (58)
2. Software Crash         (47)
3. Hardware Failure       (39)
```

---

# ⚙️ How It Works

```
Run main.py
      │
      ▼
Generate 500 tickets with Faker
      │
      ▼
Load CSV into Objects + DataFrame
      │
      ▼
Run Analytics (pandas groupby, filters, Counter)
      │
      ▼
Generate Reports (.txt, .png, .xlsx)
      │
      ▼
Open Interactive CLI Menu (optional)
```

---

# 🧠 Key Concepts Demonstrated

| Concept | Where it appears |
|---|---|
| OOP / Classes | `ServiceRequest` class in `models/service_request.py` |
| Encapsulation | All ticket data bundled into one `ServiceRequest` object |
| Separation of Concerns | Each folder (models, analytics, reports) has one responsibility |
| List Comprehensions | All filter functions in `analytics/filters.py` |
| pandas groupby | `technician_performance()` in `analytics/stats.py` |
| Boolean Indexing | `average_resolution_time()` — filtering completed rows only |
| Counter | `top_failure_categories()` and breakdowns in `analytics/stats.py` |
| Context Manager | `with open(...) as f` in loader and report files |
| Event Loop | `while True` + `break` pattern in `cli.py` |
| Weighted Randomness | `random.choices(..., weights=[...])` in `data_generator.py` |
| Faker Library | Realistic company/person names in `data_generator.py` |
| matplotlib fig/ax | Two-layer chart model in `reports/charts.py` |
| openpyxl Styling | Cell colors, fonts, freeze panes in `reports/excel_report.py` |
| `__name__ == "__main__"` | Entry point guard in `main.py` |

---

# 🔧 Extending the Project

| To do this... | ...do this |
|---|---|
| Add a new filter | Add a function to `analytics/filters.py` |
| Add a new chart | Add a function to `reports/charts.py` |
| Add a new Excel sheet | Add a block inside `generate_excel_report()` in `reports/excel_report.py` |
| Add a new CLI option | Add an `elif` branch in `cli.py` |
| Change the data schema | Edit the column pools in `utils/data_generator.py` and update `models/service_request.py` |

---

# 📦 Dependencies

See `requirements.txt`:

```
faker>=19.0.0
pandas>=1.5.0
matplotlib>=3.6.0
openpyxl>=3.1.0
```

Install all packages using:

```bash
pip install -r requirements.txt
```

---

# 🔮 Future Improvements

- Web dashboard (Streamlit or Flask)
- SQL database backend instead of CSV
- Configurable ticket volume and date ranges
- Additional chart types (trend lines, heatmaps)
- Unit testing
- Docker support
- CI/CD with GitHub Actions

---

# 👨‍💻 Author

**Pramati Gupta**

GitHub: https://github.com/pramatiiii

LinkedIn: https://www.linkedin.com/in/pramati-gupta-5b0b26321/

---

## ⭐ Support

If you found this project helpful, consider giving it a **⭐ Star** on GitHub.
