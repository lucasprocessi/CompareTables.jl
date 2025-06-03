# CompareTables.jl

Compare two versions of a tabular Excel report or two DataFrames with aggregation, difference analysis, and change tracking.

## 📦 Features

- Accepts either two Excel files **or** two `DataFrame`s directly
- Group by key columns and sum a value column
- Side-by-side comparison of old vs. new values
- Compute **absolute** and **relative** differences
- Highlight:
  - Entries with large differences
  - New entries in the updated report
  - Entries missing from the updated report
- Save:
  - Detailed difference table to Excel
  - Log file with summary and warnings

## 🛠 Installation

To use locally during development:

```julia
using Pkg
Pkg.develop(path="path/to/CompareTables")
```

Install dependencies if needed:

```julia
Pkg.add(["XLSX", "DataFrames"])
```

## 🚀 Usage

### Option 1: Compare from Excel Files

```julia
using CompareTables

compare("report_v1.xlsx", "Sheet1",
        "report_v2.xlsx", "Sheet1",
        ["Region", "Product"], "Amount",
        "log.txt", "comparison.xlsx";
        abs_threshold=10, rel_threshold=0.05)
```

### Option 2: Compare DataFrames

```julia
df1 = DataFrame(XLSX.readtable("report_v1.xlsx", "Sheet1")...)
df2 = DataFrame(XLSX.readtable("report_v2.xlsx", "Sheet1")...)

compare(df1, df2, ["Region", "Product"], "Amount",
        "log.txt", "comparison.xlsx";
        abs_threshold=10, rel_threshold=0.05)
```

## 🧮 Example

Given reports:

**report_v1.xlsx**
| Region | Product | Amount |
|--------|---------|--------|
| East   | A       | 100    |
| West   | B       | 200    |

**report_v2.xlsx**
| Region | Product | Amount |
|--------|---------|--------|
| East   | A       | 110    |
| West   | B       | 180    |
| North  | C       | 90     |

Output:
- `A` in `East`: ↑ +10 (+10%)
- `B` in `West`: ↓ −20 (−10%)
- `C` in `North`: new entry

## 📁 Output

- **comparison.xlsx**: Full table with values, diffs
- **log.txt**: Summary log with threshold exceedances, new/missing entries, and total difference

## ⚙️ Parameters

| Parameter        | Description                                     | Default        |
|------------------|--------------------------------------------------|----------------|
| `abs_threshold`  | Minimum absolute difference to report            | `1e-2`         |
| `rel_threshold`  | Minimum relative difference to report (fraction) | `0.01`         |

## 🔬 Testing

Add tests in `test/runtests.jl` to validate basic behavior:

```julia
using CompareTables
using Test

@testset "CompareTables.jl" begin
    @test isdefined(CompareTables, :compare)
end
```

---

**CompareTables.jl** simplifies table version control, audit reporting, and Excel-based analysis workflows.
