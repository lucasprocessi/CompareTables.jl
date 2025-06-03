module CompareTables

using XLSX
using DataFrames
using Dates

export compare


function compare(
    file1::String, sheet1::String, 
    file2::String, sheet2::String,
    group_cols::Vector{String},
    value_col::String,
    log_path::String,
    output_excel::String;
    abs_threshold::Real=1e-2,
    rel_threshold::Real=0.01
)

    df1 = DataFrame(XLSX.readtable(file1, sheet1)...)
    df2 = DataFrame(XLSX.readtable(file2, sheet2)...)

    compare(
        df1, df2, group_cols, value_col, log_path, output_excel;
        abs_threshold=abs_threshold, rel_threshold=rel_threshold
    )

end


function compare(df1::DataFrame, df2::DataFrame,
                 group_cols::Vector{String},
                 value_col::String,
                 log_path::String,
                 output_excel::String;
                 abs_threshold::Real=1e-2,
                 rel_threshold::Real=0.01)

    agg1 = combine(groupby(df1, group_cols), value_col => sum => :value1)
    agg2 = combine(groupby(df2, group_cols), value_col => sum => :value2)

    df_combined = outerjoin(agg1, agg2, on=group_cols)

    df_combined.:abs_diff = abs.(coalesce.(df_combined.value2, 0) .- coalesce.(df_combined.value1, 0))
    df_combined.:rel_diff = abs.(df_combined.abs_diff ./ max.(abs.(coalesce.(df_combined.value1, 1)), 1e-6))

    over_abs = df_combined[df_combined.abs_diff .> abs_threshold, :]
    over_rel = df_combined[df_combined.rel_diff .> rel_threshold, :]

    new_entries = df_combined[ismissing.(df_combined.value1), :]
    missing_entries = df_combined[ismissing.(df_combined.value2), :]

    total_diff = sum(skipmissing(df_combined.abs_diff))

    open(log_path, "w") do io
        println(io, "CompareTables.jl Log - $(Dates.now())")
        println(io, "Total Absolute Difference: $total_diff")
        println(io, "\n\n[Entries with absolute diff > $abs_threshold]")
        show(io, over_abs; allcols=true)
        println(io, "\n\n[Entries with relative diff > $rel_threshold]")
        show(io, over_rel; allcols=true)
        println(io, "\n\n[New Entries in Report 2]")
        show(io, new_entries; allcols=true)
        println(io, "\n\n[Entries Missing from Report 2]")
        show(io, missing_entries; allcols=true)
    end

    XLSX.writetable(output_excel, df_combined; overwrite=true)
    
    return df_combined
end

end # module
