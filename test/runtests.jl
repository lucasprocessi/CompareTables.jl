using Test
using CompareTables
using DataFrames
using XLSX

# Sample data with string column names
df1 = DataFrame("Region" => ["North", "South"], "Product" => ["A", "B"],
                "Revenue" => [100.0, 200.0], "Cost" => [40.0, 80.0])
df2 = DataFrame("Region" => ["North", "South", "East"], "Product" => ["A", "B", "C"],
                "Revenue" => [110.0, 190.0, 300.0], "Cost" => [45.0, 75.0, 120.0])

# Paths
f1, f2 = "test1.xlsx", "test2.xlsx"
logf, outf = "test_log.txt", "test_output.xlsx"

# Write to temporary Excel files
XLSX.writetable(f1, df1; sheetname="Sheet1", overwrite=true)
XLSX.writetable(f2, df2; sheetname="Sheet1", overwrite=true)

# Run comparison
result = compare(
    f1, "Sheet1",
    f2, "Sheet1",
    ["Region", "Product"],
    ["Revenue", "Cost"],
    logf,
    outf;
    abs_threshold=5.0,
    rel_threshold=0.05
)

# Basic tests
@test isa(result, DataFrame)
@test "Revenue_1" in names(result)
@test "Revenue_2" in names(result)
@test "abs_diff_Revenue" in names(result)
@test "rel_diff_Cost" in names(result)

@info "Result"
display(result)

# Cleanup temp files
for f in (f1, f2, logf, outf)
    isfile(f) && rm(f)
end
