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
function modify_power_generator_min_cap(
    power_settings::Dict,
    power_inputs::Dict,
    modification::Union{Int64, Float64},
)

    dfGen = power_inputs["dfGen"]

    ## Set minimum capacity limit for each resource in dataframe
    dfGen[!, :Min_Cap_MW] .= modification

    ## Check whether minimum capacity exceeds maximum capacity
    overshooting = dfGen[(dfGen.Max_Cap_MW .!= -1) .& (dfGen.Min_Cap_MW .> dfGen.Max_Cap_MW), :R_ID]

    if !isempty(overshooting)
        print_and_log(
            power_settings,
            "w",
            "Some resources have overshooting minimum capacity than maximum capacity.\n $overshooting",
        )
    end

    power_inputs["dfGen"] = dfGen

    return power_inputs
end
