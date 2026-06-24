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
function modify_carbon_inputs(settings::Dict, inputs::Dict, modification::Dict)

    print_and_log(settings, "i", "Modifying Carbon Inputs According to User's Modification")

    carbon_inputs = inputs["CarbonInputs"]
    carbon_settings = settings["CarbonSettings"]

    ## Modify carbon sector inputs
    ### Modify carbon sector generator maximum capacity
    if haskey(modification, "C_G_Max_Cap")
        carbon_inputs = modify_carbon_generator_max_cap(
            carbon_settings,
            carbon_inputs,
            modification["C_G_Max_Cap"],
        )
    end
    ### Modify carbon sector generator existing capacity
    if haskey(modification, "C_G_Existing_Cap")
        carbon_inputs = modify_carbon_generator_existing_cap(
            carbon_settings,
            carbon_inputs,
            modification["C_G_Existing_Cap"],
        )
        delete!(modification, "C_G_Existing_Cap")
    end
    ### Modify carbon sector generator minimum capacity
    if haskey(modification, "C_G_Min_Cap")
        carbon_inputs = modify_carbon_generator_min_cap(
            carbon_settings,
            carbon_inputs,
            modification["C_G_Min_Cap"],
        )
    end
    carbon_inputs = modify_carbon_generator_cap(carbon_settings, carbon_inputs)

    ### Modify carbon sector generator full load hours
    if haskey(modification, "C_G_FLH")
        carbon_inputs =
            modify_carbon_generator_flh(carbon_settings, carbon_inputs, modification["C_G_FLH"])
    end

    ### Modify carbon sector generators capex
    if haskey(modification, "C_G_CAPEX")
        carbon_inputs =
            modify_carbon_generator_capex(carbon_settings, carbon_inputs, modification["C_G_CAPEX"])
        delete!(modification, "C_G_CAPEX")
    end

    ### Modify carbon sector storage maximum capacity
    if haskey(modification, "C_S_Max_Ene_Cap")
        carbon_inputs = modify_carbon_storage_max_ene_cap(
            carbon_settings,
            carbon_inputs,
            modification["C_S_Max_Ene_Cap"],
        )
    end
    ### Modify carbon sector storage existing capacity
    if haskey(modification, "C_S_Existing_Ene_Cap")
        carbon_inputs = modify_carbon_storage_existing_ene_cap(
            carbon_settings,
            carbon_inputs,
            modification["C_S_Existing_Ene_Cap"],
        )
        delete!(modification, "C_S_Existing_Ene_Cap")
    end
    ### Modify carbon sector storage minimum capacity
    if haskey(modification, "C_S_Min_Ene_Cap")
        carbon_inputs = modify_carbon_storage_min_ene_cap(
            carbon_settings,
            carbon_inputs,
            modification["C_S_Min_Ene_Cap"],
        )
    end

    ### Modify carbon sector storage capex
    if haskey(modification, "C_S_CAPEX")
        carbon_inputs =
            modify_carbon_storage_capex(carbon_settings, carbon_inputs, modification["C_S_CAPEX"])
        delete!(modification, "C_S_CAPEX")
    end

    ### Modify carbon sector demand
    if haskey(modification, "C_Demand")
        carbon_inputs =
            modify_carbon_demand(carbon_settings, carbon_inputs, modification["C_Demand"])
        delete!(modification, "C_Demand")
    end

    ### Modify carbon sector emission policy (global modification)
    if !in(0, settings["CO2Policy"])
        carbon_inputs = modify_carbon_emission_policy(carbon_settings, carbon_inputs, modification)
    end

    inputs["CarbonInputs"] = carbon_inputs

    return inputs, modification
end
