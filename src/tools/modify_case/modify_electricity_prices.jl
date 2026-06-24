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
function modify_electricity_prices(
    settings::Dict,
    electricity_costs::Dict,
    modification::Union{Int64, Float64, Vector{Float64}, AbstractArray{Float64}},
    electricity_index::Union{String, Vector{String}, AbstractArray{String}} = nothing,
)

    print_and_log(settings, "i", "Modifying Electricity Prices")

    if electricity_index === nothing
        for (key, value) in electricity_costs
            if typeof(modification) in [Int64, Float64]
                print_and_log(settings, "i", "Modifying All Electricity Costs to $modification")
                electricity_costs[key] .= modification
            elseif typeof(modification) in [Vector{Float64}, AbstractArray{Float64}]
                if size(value) == size(modification)
                    print_and_log(settings, "i", "Modifying All Electricity Costs to Given Series")
                    electricity_costs[key] = modification
                else
                    print_and_log(settings, "i", "Electricity Costs Untouched. Wrong Array Length")
                end
            end
        end
    elseif typeof(electricity_index) == String
        if typeof(modification) in [Int64, Float64]
            print_and_log(
                settings,
                "i",
                "Modifying $electricity_index's Electricity Cost to $modification",
            )
            electricity_costs[electricity_index] .= modification
        elseif typeof(modification) in [Vector{Float64}, AbstractArray{Float64}]
            if size(electricity_costs[electricity_index]) == size(modification)
                print_and_log(
                    settings,
                    "i",
                    "Modifying $electricity_index's Electricity Costs to Given Series",
                )
                electricity_costs[electricity_index] = modification
            else
                print_and_log(settings, "i", "Electricity Costs Untouched Given Wrong Array Length")
            end
        end
    elseif typeof(electricity_index) in [Vector{String}, Array{String}]
        for ei in electricity_index
            if typeof(modification) in [Int64, Float64]
                print_and_log(settings, "i", "Modifying $ei's Electricity Cost to $modification")
                electricity_costs[ei] .= modification
            elseif typeof(modification) in [Vector{Float64}, AbstractArray{Float64}]
                if size(electricity_costs[ei]) == size(modification)
                    print_and_log(settings, "i", "Modifying $ei's Electricity Cost to Given Series")
                    electricity_costs[ei] = modification
                else
                    print_and_log(
                        settings,
                        "i",
                        "Electricity Costs Untouched Given Wrong Array Length",
                    )
                end
            end
        end
    end

    return electricity_costs
end
