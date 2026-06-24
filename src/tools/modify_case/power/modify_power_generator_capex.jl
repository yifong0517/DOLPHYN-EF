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
function modify_power_generator_capex(
    power_settings::Dict,
    power_inputs::Dict,
    modification::Union{Int64, Float64},
)

    dfGen = power_inputs["dfGen"]

    if modification <= 5
        print_and_log(power_settings, "i", "Rescale Power Generators' CAPEX to $(modification)x")
        dfGen[!, :Inv_Cost_per_MW] .*= modification
        dfGen[!, :Fixed_OM_Cost_per_MW] .*= modification
    else
        print_and_log(power_settings, "i", "Reset Power Generators' CAPEX to $modification \$/kW")
        ## With absolute fixed OM input, using this percentage to keep the same fixed OM cost percentage
        ## Typically $/kW is used as unit for costs of power generators
        dfGen[!, :Inv_Cost_per_MW] .= 10e3 * modification
        dfGen[!, :Fixed_OM_Cost_per_MW] .=
            dfGen[!, :Inv_Cost_per_MW] .* dfGen[!, :Fixed_OM_Cost_Percentage]
    end

    power_inputs["dfGen"] = dfGen

    return power_inputs
end
