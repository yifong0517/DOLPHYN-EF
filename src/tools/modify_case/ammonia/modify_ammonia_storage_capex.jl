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
function modify_ammonia_storage_capex(
    ammonia_settings::Dict,
    ammonia_inputs::Dict,
    modification::Union{Int64, Float64},
)

    dfSto = ammonia_inputs["dfSto"]

    if modification <= 5
        print_and_log(ammonia_settings, "i", "Rescale Ammonia Storages' CAPEX to $(modification)x")
        dfSto[!, :Inv_Cost_Ene_per_tonne] .*= modification
        dfSto[!, :Fixed_OM_Cost_Ene_per_tonne] .*= modification
        dfSto[!, :Inv_Cost_Dis_per_tonne_per_hr] .*= modification
        dfSto[!, :Fixed_OM_Cost_Dis_per_tonne_per_hr] .*= modification
        dfSto[!, :Inv_Cost_Cha_per_tonne_per_hr] .*= modification
        dfSto[!, :Fixed_OM_Cost_Cha_per_tonne_per_hr] .*= modification
    else
        print_and_log(
            ammonia_settings,
            "i",
            "Reset Ammonia Storages' CAPEX to $modification \$/kg. Note Charge and Discharge Costs Are Untouched.",
        )
        ## With absolute fixed OM input, using this percentage to keep the same fixed OM cost percentage
        ## 10e3 is used to scale the unit of cost from $/kg to $/tonne
        dfSto[!, :Inv_Cost_Ene_per_tonne] .= 10e3 * modification
        dfSto[!, :Fixed_OM_Cost_Ene_per_tonne] .=
            dfSto[!, :Inv_Cost_Ene_per_tonne] .* dfSto[!, :Fixed_OM_Cost_Ene_Percentage]
    end

    ammonia_inputs["dfSto"] = dfSto

    return ammonia_inputs
end
