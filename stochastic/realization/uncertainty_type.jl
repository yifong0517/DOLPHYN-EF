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
function uncertainty_type(type::AbstractString, parameters::Vector{Float64})

    ## Uncertainty types
    ### Distributions - discrete
    if type == "B" # Binomial distribution
        n = parameters[1] # Number of trials
        p = parameters[2] # Probability of success
        println("Binomial Distribution with n = $n and p = $p")
        uncertainty_name = "Binomial"
    elseif type == "Geo" # Geometric distribution
        p = parameters[1] # Probability of success
        println("Geometric Distribution with p = $p")
        uncertainty_name = "Geometric"
    elseif type == "H" # Hypergeometric distribution
        N = parameters[1] # Population size
        K = parameters[2] # Number of successes
        n = parameters[3] # Number of draws
        println("Hypergeometric Distribution with N = $N, K = $K and n = $n")
        uncertainty_name = "Hypergeometric"
    elseif type == "NB" # Negative binomial distribution
        r = parameters[1] # Number of successes
        p = parameters[2] # Probability of success
        println("Negative Binomial Distribution with r = $r and p = $p")
        uncertainty_name = "Negative Binomial"
    elseif type == "P" # Poisson distribution
        λ = parameters[1] # Mean
        println("Poisson Distribution with λ = $λ")
        uncertainty_name = "Poisson"
    end

    ### Distributions - continuous
    if type == "Beta" # Beta distribution
        α = parameters[1] # Shape parameter
        β = parameters[2] # Shape parameter
        println("Beta Distribution with α = $α and β = $β")
        uncertainty_name = "Beta"
    elseif type == "Exp" # Exponential distribution
        λ = parameters[1] # Rate parameter
        println("Exponential Distribution with λ = $λ")
        uncertainty_name = "Exponential"
    elseif type == "Gamma" # Gamma distribution
        α = parameters[1] # Shape parameter
        β = parameters[2] # Scale parameter
        println("Gamma Distribution with α = $α and β = $β")
        uncertainty_name = "Gamma"
    elseif type == "LN" # Log-normal distribution
        μ = parameters[1] # Mean of the underlying normal distribution
        σ² = parameters[2] # Variance of the underlying normal distribution
        println("Log-normal Distribution with μ = $μ and σ² = $σ²")
        uncertainty_name = "Log-normal"
    elseif type == "L" # Logistic distribution
        μ = parameters[1] # Location parameter
        s = parameters[2] # Scale parameter
        println("Logistic Distribution with μ = $μ and s = $s")
        uncertainty_name = "Logistic"
    elseif type == "N" # Normal distribution
        μ = parameters[1] # Mean
        σ² = parameters[2] # Standard deviation
        println("Normal Distribution with μ = $μ and σ² = $σ²")
        uncertainty_name = "Normal"
    elseif type == "U" # Uniform distribution
        a = parameters[1] # Lower bound
        b = parameters[2] # Upper bound
        println("Uniform Distribution with a = $a and b = $b")
        uncertainty_name = "Uniform"
    elseif type == "W" # Weibull distribution
        α = parameters[1] # Shape parameter
        β = parameters[2] # Scale parameter
        println("Weibull Distribution with α = $α and β = $β")
        uncertainty_name = "Weibull"
    end

    ### Interval
    if type == "I" # Interval
        l = parameters[1] # Lower bound
        u = parameters[2] # Upper bound
        println("Interval with l = $l and u = $u")
        uncertainty_name = "Interval"
    end

    ### Single
    if type == "S" # Single
        x = parameters[1] # Value
        println("Single with x = $x")
        uncertainty_name = "Single"
    end

    return uncertainty_name
end
