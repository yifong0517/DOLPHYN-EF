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
function modify_hydrogen_generator_capex(
    hydrogen_settings::Dict,
    hydrogen_inputs::Dict,
    modification::Union{Int64, Float64},
)

    dfGen = hydrogen_inputs["dfGen"]

    if modification <= 5
        print_and_log(
            hydrogen_settings,
            "i",
            "Rescale Hydrogen Generators' CAPEX to $(modification)x",
        )
        dfGen[!, :Inv_Cost_per_tonne_per_hr] .*= modification
        dfGen[!, :Fixed_OM_Cost_per_tonne_per_hr] .*= modification
    else
        print_and_log(
            hydrogen_settings,
            "i",
            "Reset Hydrogen Generators' CAPEX to $modification \$/kW",
        )
        ## With absolute fixed OM input, using this percentage to keep the same fixed OM cost percentage
        ## 10e5/3 is used to scale the unit of cost from $/kW to $/(tonne/hr)
        ELE = hydrogen_inputs["ELE"]
        dfGen = transform(
            dfGen,
            [:R_ID, :Inv_Cost_per_tonne_per_hr, :Electricity_Rate_MWh_per_tonne],
            ByRow(
                (R, INV, ER) ->
                    Inv_Cost_per_tonne_per_hr = (R in ELE) ? 1000 * ER * modification : INV,
            ),
        )
        dfGen[dfGen.R_ID .== ELE, :Inv_Cost_per_tonne_per_hr] .=
            10e5 / 3 * modification / dfGen[!, :Fixed_OM_Cost_per_tonne_per_hr] .=
                dfGen[!, :Inv_Cost_per_tonne_per_hr] .* dfGen[!, :Fixed_OM_Cost_Percentage]
    end

    hydrogen_inputs["dfGen"] = dfGen

    return hydrogen_inputs
end
