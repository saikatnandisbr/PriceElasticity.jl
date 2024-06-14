# model with one product level

# imports
using Turing
using ReverseDiff

using Distributions
using LinearAlgebra

# exports

# code
"""
# legend

k -> product line index

x -> unit price
y -> volume
"""

@model function varying_intercept_slope_1(x, idx_k, y)

    n_k = length(unique(idx_k))                             # unique cats

    # specified priors and hyperpriors
    σ ~ Exponential(5)                                      # redidual sd
    
    α ~ Normal(70, 50)                                      # overall intercept
    β ~ Normal(0, 1)                                        # overall slope

    τ_α_k ~ truncated(Normal(0, 50), 0, Inf)                # sd of cat level effect on intercept
    τ_β_k ~ truncated(Normal(0, 1), 0, Inf)                 # sd of cat level effect on slope

    α_k ~ filldist(Normal(0, τ_α_k), n_k)                   # cat level effect on intercept
    β_k ~ filldist(Normal(0, τ_β_k), n_k)                   # cat level effect on slope 

    # for each data point
    η = @. (α + α_k[idx_k]) + (β + β_k[idx_k]) * x

    # response

    # for i in eachindex(y)
    #     y[i] ~ Normal(η[i], σ)
    # end

    y ~ MvNormal(η, σ ^ 2 * I)

    return y
end

