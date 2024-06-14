using CSV
using DataFrames
using StatsPlots

using Turing
using ReverseDiff

# read data with cat, subcat, product
df = CSV.File(joinpath(out_dirname, out_fname)) |> DataFrame

# unique ids
length(unique(df.category_uid))
length(unique(df.sub_category_uid))

# variables to pass to Hierarchical Bayesian model
x = df.unit_price               # independent variable - unit price
x = (x .- mean(x)) ./ std(x)    # standardize

y = df.invoice_quantity         # response - quantity sold
y = log.(y .+ 1)

idx_k = df.category_uid         # indicator for cat
idx_j = df.sub_category_uid     # indicator for subcat

# create model
model = PriceElasticity.varying_intercept_slope_2(x, idx_j, idx_k, y)

# number of threads for mcmc
n_threads = Threads.nthreads()

# generate MCMC samples
@time chain = sample(model, NUTS(adtype=AutoReverseDiff()), MCMCThreads(), 1_000, n_threads);

# examine chain
summaries, quantiles = describe(chain)

summaries

quantiles

# visualize chain
# plot(chain)                   # large output, consider selecting chain components before plotting
