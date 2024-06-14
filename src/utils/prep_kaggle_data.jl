# prepare data for hierchical bayesian model

# imports
using CSV
using DataFrames
using Dates
using Pipe

# exports

# code
"""
    function prep_kaggle_data(in_fname::String, in_dirname::String, out_fname::String, out_dirname::String)

Aggregate invoice data to weekly level.

in_fname:       Input CSV file name
in_dirname:     Input directory name
out_fname:      Output CSV file name
out_dirname:    Output directory name
"""

function prep_kaggle_data(in_fname::String, in_dirname::String, out_fname::String, out_dirname::String)

    # read data
    try

        df = CSV.File(
            joinpath(in_dirname, in_fname), 
            select = ["Invoice ID", "Product line", "Unit price", "Quantity", "Date"],
        ) |> DataFrame;

    catch

        println("PriceElasticity.prep_data_weekly:: File read error")
        error(err)

    end

    # rename columns
    rename!(df, [:invpice_id, :category_id, :unit_price, :invoice_quantity, :invoice_date])

    # convert string to date
    try

        df.invoice_date = Date.(df.invoice_date, "mm/dd/yyyy")

    catch err

        println("PriceElasticity.prep_data_weekly: Cannot convert data to date")
        error(err)

    end

    # invoice amount
    df.invoice_amount = @. round(df.invoice_quantity * df.unit_price, digits=2)

    # aggregate weekly
    df = @pipe df |>
            DataFrames.transform!(_, :invoice_date => ByRow(dt ->  string(year(dt)) * lpad(string(week(dt)), 2, "0")) => :invoice_week) |>
            groupby(_, [:invoice_week, :category_id]) |>
            combine(_, :invoice_amount => sum, :invoice_quantity => sum, renamecols=false) |>
            filter!(:invoice_quantity => (qty -> qty != 0), _) |>
            DataFrames.transform!(_, [:invoice_amount, :invoice_quantity] => ByRow((amt, qty) -> round(amt/qty, digits=2)) => :unit_price)

            
    # create numeric id columns
    df.category_uid = groupindices(groupby(df, :category_id))

    # write aggregated data
    try

        CSV.write(joinpath(out_dirname, out_fname), df)
        
    catch err

        print("PriceElasticity.prep_data_weekly:: File write error")
        error(err)

    end

    return nothing
end