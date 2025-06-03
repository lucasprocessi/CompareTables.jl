using Test
using CompareTables
using DataFrames
using XLSX

@testset "CompareTables.jl" begin
    # Sample data mimicking two report versions
    df1 = DataFrame(Region=["East", "West"], Product=["A", "B"], Amount=[100, 200])
    df2 = DataFrame(Region=["East", "West", "North"], Product=["A", "B", "C"], Amount=[110, 180, 90])

    group_cols = ["Region", "Product"]
    value_col = "Amount"
    log_path = "test_log.txt"
    output_excel = "test_output.xlsx"

    # Run the comparison
    result = compare(df1, df2, group_cols, value_col, log_path, output_excel;
                     abs_threshold=5, rel_threshold=0.05)

    @info "RESULTS TABLE PRODUCED"
    display(result)

    @test isa(result, DataFrame)
    @test "value1" in names(result)
    @test "value2" in names(result)
    @test "abs_diff" in names(result)
    @test "rel_diff" in names(result)

    # Test known differences
    row_east = result[result.Region .== "East", :]
    @test row_east.abs_diff[1] == 10
    @test isapprox(row_east.rel_diff[1], 0.10; atol=1e-6)

    # Test new entry
    @test any(ismissing.(result.value1))
    # Test missing entry
    @test any(ismissing.(result.value2)) == false  # None in this example

    # Check if files were created
    @test isfile(log_path)
    @test isfile(output_excel)

    @info "LOG PRODUCED"
    for line in readlines(log_path)
        println(line)
    end

    # Clean up test artifacts
    rm(log_path, force=true)
    rm(output_excel, force=true)
end
