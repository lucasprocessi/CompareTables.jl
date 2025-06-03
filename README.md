# CompareTables.jl

📊 **CompareTables.jl** is a Julia package to compare two versions of a tabular Excel report. It groups, sums, and compares values by key columns, highlighting differences, new/missing entries, and exporting results with a log file and annotated Excel table.

---

## ✨ Features

- Compare two Excel sheets grouped by one or more columns.
- Support for **multiple value columns**.
- Automatic calculation of **absolute** and **relative differences**.
- Threshold-based **warnings** for large deviations.
- Detects **new** and **missing** entries between reports.
- Outputs:
  - Clean Excel file with comparison
  - Human-readable log file with all results

---

## 📦 Installation

```julia
pkg> add CompareTables
```

---

## 🚀 Usage

```julia
using CompareTables

compare(
    "old_report.xlsx", "Sheet1",
    "new_report.xlsx", "Sheet1",
    ["Region", "Product"],           # group columns
    ["Revenue", "Cost"],             # value columns
    "log.txt",                       # path to log output
    "comparison.xlsx";              # path to Excel output
    abs_threshold=100.0,
    rel_threshold=0.05
)
```

This will generate:

- A file `comparison.xlsx` with all groupings and their:
  - Original values (`<col>_1`)
  - New values (`<col>_2`)
  - `abs_diff_<col>` and `rel_diff_<col>` columns
- A `log.txt` file with:
  - Total absolute difference
  - Warnings for large differences
  - Lists of new or missing entries

---

## 📄 Output Example (Excel and Log)

| Region | Product | Revenue_1 | Revenue_2 | abs_diff_Revenue | rel_diff_Revenue | ... |
|--------|---------|-----------|-----------|------------------|------------------|-----|
| North  | A       | 1200.0    | 1250.0    | 50.0             | 0.0417           |     |
| South  | B       | 800.0     | missing   | 800.0            | 1.0              |     |

And in `log.txt`:

```
CompareTables.jl Log - 2025-06-03T18:45:12
Total Absolute Difference (all columns): 205.0

[Entries with absolute diff > 100.0]
...

[Entries with relative diff > 0.05]
...

[New Entries in Report 2]
...

[Entries Missing from Report 2]
...
```

---

## ⚙️ Options

| Parameter       | Description                               | Default |
|----------------|-------------------------------------------|---------|
| `abs_threshold` | Absolute diff threshold to warn           | `1e-2`  |
| `rel_threshold` | Relative diff threshold to warn (0–1)     | `0.01`  |

---

## 🧪 Testing

```julia
using Pkg
Pkg.test("CompareTables")
```

---

## 📬 Contributions

PRs and issues welcome! Let’s make report validation easier for everyone.

---

## 📜 License

MIT
