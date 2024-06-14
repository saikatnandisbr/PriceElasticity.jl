# model with several product levels

# imports
using Turing
using ReverseDiff

using Distributions
using LinearAlgebra

# exports

# code
"""
# legend

j -> subcategory index
k -> category index

x -> unit price
y -> volume
"""

@model function varying_intercept_slope_2(x, idx_j, idx_k, y)

    n_j = length(unique(idx_j))                            # unique subcats
    n_k = length(unique(idx_k))                            # unique cats

    # specified priors and hyperpriors
    σ ~ Exponential(2)                                     # redidual sd
    
    α ~ Normal(6, 4)                                       # overall intercept
    β ~ Normal(0, 4)                                       # overall slope

    τ_α_k ~ truncated(Normal(0, 4), 0, Inf)                # sd of cat level effect on intercept
    τ_β_k ~ truncated(Normal(0, 4), 0, Inf)                # sd of cat level effect on slope

    α_k ~ filldist(Normal(0, τ_α_k), n_k)                  # cat level effect on intercept
    β_k ~ filldist(Normal(0, τ_β_k), n_k)                  # cat level effect on slope 

    τ_α_j ~ truncated(Normal(0, 4), 0, Inf)                # sd of subcat level effect on intercept
    τ_β_j ~ truncated(Normal(0, 4), 0, Inf)                # sd of subcat level effect on slope

    α_j ~ filldist(Normal(0, τ_α_j), n_j)                   # subcat level effect on intercept
    β_j ~ filldist(Normal(0, τ_β_j), n_j)                   # subcat level effect on slope 
    
    # for each data point
    η = @. (α + α_k[idx_k] + α_j[idx_j]) + (β + β_k[idx_k] + β_j[idx_j]) * x

    # response

    # for i in eachindex(y)
    #     y[i] ~ Normal(η[i], σ)
    # end
    
    y ~ MvNormal(η, σ ^ 2 * I)

    return y
end

