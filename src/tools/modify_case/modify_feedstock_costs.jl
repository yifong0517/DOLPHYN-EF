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
function modify_feedstock_costs(
    settings::Dict,
    inputs::Dict,
    modification::Union{Int64, Float64, AbstractArray{Float64}},
    feedstock::AbstractString,
)

    print_and_log(settings, "i", "Modifying Feedstock Costs")

    T = inputs["T"]

    Feedstock_Index = inputs["Feedstock_Index"]
    feedstock_costs = inputs["feedstock_costs"]

    if typeof(modification) in [Int64, Float64]
        if feedstock in Feedstock_Index
            print_and_log(settings, "i", "Modifying $feedstock's Costs with Scalar $modification")
            feedstock_costs[feedstock] *= modification
        else
            print_and_log(
                settings,
                "i",
                "Adding New Feedstock $feedstock Costs with Scalar $modification",
            )
            feedstock_costs[feedstock] = modification .* ones(T)
            push!(Feedstock_Index, feedstock)
        end
    elseif typeof(modification) == AbstractArray{Float64}
        if feedstock in Feedstock_Index
            print_and_log(settings, "i", "Modifying $feedstock's Costs with Array")
            feedstock_costs[feedstock] = modification
        elseif length(modification) == T
            print_and_log(settings, "i", "Adding New Feedstock $feedstock Costs with Array")
            feedstock_costs[feedstock] = modification
            push!(Feedstock_Index, feedstock)
        else
            print_and_log(settings, "i", "Feedstock Costs Untouched, wrong array length")
        end
    end

    inputs["Feedstock_Index"] = Feedstock_Index
    inputs["feedstock_costs"] = feedstock_costs

    return inputs
end
