using CSV
using DataFrames
using StatsPlots

using Turing
using ReverseDiff

# read data with cat, subcat, product
df = CSV.File(joinpath(out_dirname, out_fname)) |> DataFrame

# unique ids
length(unique(df.category_uid))

# variables to pass to Hierarchical Bayesian model
x = df.unit_price           # independent variable - unit price
y = df.invoice_quantity     # response - quantity sold

idx_k = df.category_uid     # indicator for cat

# create model
model = PriceElasticity.varying_intercept_slope_1(x, idx_k, y);

# number of threads for mcmc
n_threads = Threads.nthreads()

# generate MCMC samples
@time chain = sample(model, NUTS(adtype=AutoReverseDiff()), MCMCThreads(), 1_000, n_threads);

# examine chain
summaries, quantiles = describe(chain)

summaries

quantiles

# visualize chain
plot(chain)
