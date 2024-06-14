# prepare data for hierchical bayesian model

# imports
using CSV
using DataFrames
using Dates
using Pipe

# exports

# code
"""
    function prep_retailer_data(in_fname::String, in_dirname::String, out_fname::String, out_dirname::String)

Aggregate invoice data to weekly level.

in_fname:       Input CSV file name
in_dirname:     Input directory name
out_fname:      Output CSV file name
out_dirname:    Output directory name
"""

function prep_retailer_data(in_fname::String, in_dirname::String, out_fname::String, out_dirname::String)

    # read data
    try

        df = CSV.File(
            joinpath(in_dirname, in_fname), 
            select = [:invoice_number, :invoice_date, :product_id, :category_id, :sub_category_id, :invoice_quantity, :invoice_amount],
        ) |> DataFrame;

    catch

        println("PriceElasticity.prep_data_weekly:: File read error")
        error(err)

    end

    # handle non-numeric character in numeric column
    try

        df.invoice_quantity = @. tryparse(Float64, replace(df.invoice_quantity, "," => ""))

    catch err

        println("PriceElasticity.prep_data_weekly: Cannot convert data to numeric")
        error(err)

    end

    # aggregate weekly
    df = @pipe df |>
            DataFrames.transform!(_, :invoice_date => ByRow(dt ->  string(year(dt)) * lpad(string(week(dt)), 2, "0")) => :invoice_week) |>
            groupby(_, [:invoice_week, :category_id, :sub_category_id]) |>
            combine(_, :invoice_amount => sum, :invoice_quantity => sum, renamecols=false) |>
            filter!(:invoice_quantity => (qty -> qty != 0), _) |>
            DataFrames.transform!(_, [:invoice_amount, :invoice_quantity] => ByRow((amt, qty) -> round(amt/qty, digits=2)) => :unit_price)

            
    # remove weeks with low quantity
    df = df[df.invoice_quantity .>= 10, :]

    # remove small unit price
    df = df[df.unit_price .>= 10, :]

    # items purchased frequently
    n_weeks = length(unique(df.invoice_week))
    df = filter(x -> nrow(x) == n_weeks, groupby(df, [:category_id, :sub_category_id]), ungroup=true)

    # create numeric id columns
    df.category_uid = groupindices(groupby(df, :category_id))
    df.sub_category_uid = groupindices(groupby(df, [:category_id, :sub_category_id]))

    # write aggregated data
    try

        CSV.write(joinpath(out_dirname, out_fname), df)
        
    catch err

        print("PriceElasticity.prep_data_weekly:: File write error")
        error(err)

    end

    return nothing
end