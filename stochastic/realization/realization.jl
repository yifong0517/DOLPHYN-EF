"""
MESS: Macro Energy Synthesis System
Copyright (C) 2022, College of Engineering, Peking University

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"""

@doc raw"""

"""
function realization(uncertainty_type::DataFrameRow, rng::AbstractRNG)

    ## Obtain uncertainty type, parameters and budget
    type = uncertainty_type.Type
    parameters = uncertainty_type.Parameters
    budget = uncertainty_type.Budget

    ## Realize uncertainty
    ### Distributions - discrete
    if type == "Binomial"
        return distrib_binomial(parameters, budget, rng)
    elseif type == "Geometric"
        return distrib_geometric(parameters, budget, rng)
    elseif type == "Hypergeometric"
        return distrib_hypergeometric(parameters, budget, rng)
    elseif type == "Negative Binomial"
        return distrib_negative_binomial(parameters, budget, rng)
    elseif type == "Poisson"
        return distrib_poisson(parameters, budget, rng)
    end

    ### Distributions - continuous
    if type == "Beta"
        return distrib_beta(parameters, budget, rng)
    elseif type == "Exponential"
        return distrib_exponential(parameters, budget, rng)
    elseif type == "Gamma"
        return distrib_gamma(parameters, budget, rng)
    elseif type == "Log-normal"
        return distrib_log_normal(parameters, budget, rng)
    elseif type == "Normal"
        return distrib_normal(parameters, budget, rng)
    elseif type == "Uniform"
        return distrib_uniform(parameters, budget, rng)
    elseif type == "Weibull"
        return distrib_weibull(parameters, budget, rng)
    end

    ### Interval
    if type == "Interval"
        return interval(parameters, budget)
    end

    ### Single
    if type == "Single"
        return single(parameters, budget)
    end
end
