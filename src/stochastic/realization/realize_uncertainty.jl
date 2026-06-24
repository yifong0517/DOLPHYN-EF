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
function realize_uncertainty(
    uncertainty::AbstractDict{Any, Any},
    total_budget::Integer,
    rng::AbstractRNG,
)

    ## Parse uncertainty sources
    uncertainty_sources = collect(keys(uncertainty))

    println("System Uncertainty Sources: $uncertainty_sources")

    ## Parse uncertainty types
    uncertainty_types = DataFrame(Type = [], Parameters = [], Budget = [])
    for (key, value) in uncertainty
        type, parameters, budget = parse_uncertainty(value)
        println("$(uppercase(key))'s Uncertainty Type: ")
        uncertainty_name = uncertainty_type(type, parameters)
        push!(uncertainty_types, [uncertainty_name, parameters, budget])
    end

    ##TODO: Budget manipulation

    ## Realize uncertainty
    realizations = [realization(row, rng) for row in eachrow(uncertainty_types)]

    products = vec(collect(product(realizations...)))

    ## Generate modification from uncertainty block
    modification_uncertainty =
        reduce(vcat, [DataFrame(Dict(uncertainty_sources .=> product)) for product in products])

    return modification_uncertainty
end
