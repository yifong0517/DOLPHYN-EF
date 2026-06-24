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
function modify_power_inputs(settings::Dict, inputs::Dict, modification::Dict)

    print_and_log(settings, "i", "Modifying Power Inputs According to User's Modification")

    power_inputs = inputs["PowerInputs"]
    power_settings = settings["PowerSettings"]

    ## Modify power sector inputs
    ### Modify power sector generator maximum capacity
    if haskey(modification, "P_G_Max_Cap")
        power_inputs = modify_power_generator_max_cap(
            power_settings,
            power_inputs,
            modification["P_G_Max_Cap"],
        )
        delete!(modification, "P_G_Max_Cap")
    end
    ### Modify power sector generator existing capacity
    if haskey(modification, "P_G_Existing_Cap")
        power_inputs = modify_power_generator_existing_cap(
            power_settings,
            power_inputs,
            modification["P_G_Existing_Cap"],
        )
        delete!(modification, "P_G_Existing_Cap")
    end
    ### Modify power sector generator minimum capacity
    if haskey(modification, "P_G_Min_Cap")
        power_inputs = modify_power_generator_min_cap(
            power_settings,
            power_inputs,
            modification["P_G_Min_Cap"],
        )
        delete!(modification, "P_G_Min_Cap")
    end
    power_inputs = modify_power_generator_cap(power_settings, power_inputs)

    ### Modify power sector generators capex
    if haskey(modification, "P_G_CAPEX")
        power_inputs =
            modify_power_generator_capex(power_settings, power_inputs, modification["P_G_CAPEX"])
        delete!(modification, "P_G_CAPEX")
    end

    ### Modify power sector storage maximum capacity
    if haskey(modification, "P_S_Max_Ene_Cap")
        power_inputs = modify_power_storage_max_ene_cap(
            power_settings,
            power_inputs,
            modification["P_S_Max_Ene_Cap"],
        )
        delete!(modification, "P_S_Max_Ene_Cap")
    end
    ### Modify power sector storage existing capacity
    if haskey(modification, "P_S_Existing_Ene_Cap")
        power_inputs = modify_power_storage_existing_ene_cap(
            power_settings,
            power_inputs,
            modification["P_S_Existing_Ene_Cap"],
        )
        delete!(modification, "P_S_Existing_Ene_Cap")
    end
    ### Modify power sector storage minimum capacity
    if haskey(modification, "P_S_Min_Ene_Cap")
        power_inputs = modify_power_storage_min_ene_cap(
            power_settings,
            power_inputs,
            modification["P_S_Min_Ene_Cap"],
        )
        delete!(modification, "P_S_Min_Ene_Cap")
    end
    ### Modify power sector storage capex
    if haskey(modification, "P_S_CAPEX")
        power_inputs =
            modify_power_storage_capex(power_settings, power_inputs, modification["P_S_CAPEX"])
        delete!(modification, "P_S_CAPEX")
    end

    ### Modify power sector demand
    if haskey(modification, "P_Demand")
        power_inputs = modify_power_demand(power_settings, power_inputs, modification["P_Demand"])
        delete!(modification, "P_Demand")
    end

    ### Modify power sector emission policy (global modification)
    if !in(0, settings["CO2Policy"])
        power_inputs = modify_power_emission_policy(power_settings, power_inputs, modification)
    end

    inputs["PowerInputs"] = power_inputs

    return inputs, modification
end
