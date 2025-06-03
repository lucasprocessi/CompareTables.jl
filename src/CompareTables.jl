module CompareTables

using XLSX
using DataFrames
using Dates
using Logging
using LoggingExtras

export compare

const _logfile_io = Ref{Union{IO, Nothing}}(nothing)

function setup_logger(logfile_path::String)
    # Close previous log file if any
    if _logfile_io[] !== nothing
        close(_logfile_io[])
    end

    _logfile_io[] = open(logfile_path, "a")
    file_logger = SimpleLogger(_logfile_io[], Logging.Info)
    console_logger = ConsoleLogger(stderr, Logging.Info)
    tee_logger = TeeLogger(file_logger, console_logger)
    global_logger(tee_logger)
end

function close_logger()
    if _logfile_io[] !== nothing
        close(_logfile_io[])
        _logfile_io[] = nothing
    end
    # Optionally reset global logger to default (console only)
    global_logger(ConsoleLogger(stderr, Logging.Info))
end

function compare(
    file1::String, sheet1::String,
    file2::String, sheet2::String,
    group_cols::Vector{String},
    value_cols::Vector{String},
    log_path::String,
    output_excel::String;
    abs_threshold::Real=1e-2,
    rel_threshold::Real=0.01
)

    setup_logger(log_path)  # Enable logging to both file and screen

    @info "Reading Excel files: $file1 (sheet: $sheet1) and $file2 (sheet: $sheet2)"
    df1 = DataFrame(XLSX.readtable(file1, sheet1))
    df2 = DataFrame(XLSX.readtable(file2, sheet2))

    # Check columns equality and presence of group_cols and value_cols
    for (name, df) in zip(["first file", "second file"], [df1, df2])
        missing_groups = setdiff(group_cols, names(df))
        missing_values = setdiff(value_cols, names(df))

        if !isempty(missing_groups)
            error("The following group columns are missing in the $name: $(collect(missing_groups))")
        end
        if !isempty(missing_values)
            error("The following value columns are missing in the $name: $(collect(missing_values))")
        end
    end

    # Check for exact column name sets equality
    cols1 = names(df1)
    cols2 = names(df2)
    if !issubset(Set(cols1), Set(cols2)) || !issubset(Set(cols2), Set(cols1))
        missing_in_1 = setdiff(Set(cols2), Set(cols1))
        missing_in_2 = setdiff(Set(cols1), Set(cols2))
        msg = "Column mismatch detected.\n"
        if !isempty(missing_in_1)
            msg *= "Columns missing in first file: $(collect(missing_in_1))\n"
        end
        if !isempty(missing_in_2)
            msg *= "Columns missing in second file: $(collect(missing_in_2))\n"
        end
        error(msg)
    end

    close_logger()

    compare(
        df1, df2, group_cols, value_cols,
        log_path, output_excel;
        abs_threshold=abs_threshold, rel_threshold=rel_threshold
    )
end


function compare(df1::DataFrame, df2::DataFrame,
                 group_cols::Vector{String},
                 value_cols::Vector{String},
                 log_path::String,
                 output_excel::String;
                 abs_threshold::Real=1e-2,
                 rel_threshold::Real=0.01)

    setup_logger(log_path)

    @info "Aggregating data by: $(join(group_cols, ", "))"
    agg1 = combine(groupby(df1, group_cols),
                   [col => sum => Symbol(col, "_1") for col in value_cols]...)
    agg2 = combine(groupby(df2, group_cols),
                   [col => sum => Symbol(col, "_2") for col in value_cols]...)

    @info "Joining datasets for comparison"
    df_combined = outerjoin(agg1, agg2, on=group_cols)

    # Collect row indices where thresholds exceeded for any value column
    abs_rows = Int[]
    rel_rows = Int[]

    for col in value_cols
        col1 = Symbol(col, "_1")
        col2 = Symbol(col, "_2")
        abs_col = Symbol("abs_diff_", col)
        rel_col = Symbol("rel_diff_", col)

        df_combined[!, abs_col] = abs.(coalesce.(df_combined[!, col2], 0) .- coalesce.(df_combined[!, col1], 0))
        df_combined[!, rel_col] = abs.(df_combined[!, abs_col] ./ max.(abs.(coalesce.(df_combined[!, col1], 1)), 1e-6))

        over_abs = findall(>(abs_threshold), df_combined[!, abs_col])
        over_rel = findall(>(rel_threshold), df_combined[!, rel_col])

        if !isempty(over_abs)
            @warn "Column '$col': $(length(over_abs)) rows exceed abs threshold $abs_threshold"
        end
        if !isempty(over_rel)
            @warn "Column '$col': $(length(over_rel)) rows exceed rel threshold $rel_threshold"
        end

        append!(abs_rows, over_abs)
        append!(rel_rows, over_rel)
    end

    abs_rows = unique(abs_rows)
    rel_rows = unique(rel_rows)

    over_abs_all = df_combined[abs_rows, :]
    over_rel_all = df_combined[rel_rows, :]

    cols1 = select(df_combined, r"_1$")
    cols2 = select(df_combined, r"_2$")

    mask_1 = reduce((a,b) -> a .| b, [ismissing.(col) for col in eachcol(cols1)])
    mask_2 = reduce((a,b) -> a .| b, [ismissing.(col) for col in eachcol(cols2)])

    new_entries = df_combined[mask_1, :]
    missing_entries = df_combined[mask_2, :]

    total_diff = sum(skipmissing(sum([df_combined[!, Symbol("abs_diff_", col)] for col in value_cols])))

    # Sort results before output
    sort!(df_combined, group_cols)
    sort!(over_abs_all, group_cols)
    sort!(over_rel_all, group_cols)
    sort!(new_entries, group_cols)
    sort!(missing_entries, group_cols)

    @info("CompareTables.jl Log - $(Dates.now())")
    @info("Total Absolute Difference (all columns): $total_diff\n")

    print_or_none("Entries with absolute diff > $abs_threshold", over_abs_all)
    print_or_none("Entries with relative diff > $rel_threshold", over_rel_all)
    print_or_none("New Entries in Report 2", new_entries)
    print_or_none("Entries Missing from Report 2", missing_entries)

    @info "Saving result to $output_excel"
    XLSX.writetable(output_excel, df_combined; overwrite=true)

    close_logger()

    return df_combined
end

function print_or_none(label, df)
    @info "\n[$label]"
    if nrow(df) == 0
        @info "None"
    else
        @info df
    end
end

end # module
