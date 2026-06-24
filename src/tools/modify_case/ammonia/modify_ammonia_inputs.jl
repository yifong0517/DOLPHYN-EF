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
function modify_ammonia_inputs(settings::Dict, inputs::Dict, modification::Dict)

    print_and_log(settings, "i", "Modifying Ammonia Inputs According to User's Modification")

    ammonia_inputs = inputs["AmmoniaInputs"]
    ammonia_settings = settings["AmmoniaSettings"]

    ## Modify ammonia sector inputs
    ### Modify ammonia sector generator maximum capacity
    if haskey(modification, "A_G_Max_Cap")
        ammonia_inputs = modify_ammonia_generator_max_cap(
            ammonia_settings,
            ammonia_inputs,
            modification["A_G_Max_Cap"],
        )
    end
    ### Modify ammonia sector generator existing capacity
    if haskey(modification, "A_G_Existing_Cap")
        ammonia_inputs = modify_ammonia_generator_existing_cap(
            ammonia_settings,
            ammonia_inputs,
            modification["A_G_Existing_Cap"],
        )
        delete!(modification, "A_G_Existing_Cap")
    end
    ### Modify ammonia sector generator minimum capacity
    if haskey(modification, "A_G_Min_Cap")
        ammonia_inputs = modify_ammonia_generator_min_cap(
            ammonia_settings,
            ammonia_inputs,
            modification["A_G_Min_Cap"],
        )
    end
    ammonia_inputs = modify_ammonia_generator_cap(ammonia_settings, ammonia_inputs)

    ### Modify ammonia sector generator full load hours
    if haskey(modification, "A_G_FLH")
        ammonia_inputs =
            modify_ammonia_generator_flh(ammonia_settings, ammonia_inputs, modification["A_G_FLH"])
    end

    ### Modify ammonia sector generator capex
    if haskey(modification, "A_G_CAPEX")
        ammonia_inputs = modify_ammonia_generator_capex(
            ammonia_settings,
            ammonia_inputs,
            modification["A_G_CAPEX"],
        )
        delete!(modification, "A_G_CAPEX")
    end

    ### Modify ammonia sector storage maximum capacity
    if haskey(modification, "A_S_Max_Ene_Cap")
        ammonia_inputs = modify_ammonia_storage_max_ene_cap(
            ammonia_settings,
            ammonia_inputs,
            modification["A_S_Max_Ene_Cap"],
        )
    end
    ### Modify ammonia sector storage existing capacity
    if haskey(modification, "A_S_Existing_Ene_Cap")
        ammonia_inputs = modify_ammonia_storage_existing_ene_cap(
            ammonia_settings,
            ammonia_inputs,
            modification["A_S_Existing_Ene_Cap"],
        )
        delete!(modification, "A_S_Existing_Ene_Cap")
    end
    ### Modify ammonia sector storage minimum capacity
    if haskey(modification, "A_S_Min_Ene_Cap")
        ammonia_inputs = modify_ammonia_storage_min_ene_cap(
            ammonia_settings,
            ammonia_inputs,
            modification["A_S_Min_Ene_Cap"],
        )
    end

    ### Modify ammonia sector storage capex
    if haskey(modification, "A_S_CAPEX")
        ammonia_inputs = modify_ammonia_storage_capex(
            ammonia_settings,
            ammonia_inputs,
            modification["A_S_CAPEX"],
        )
        delete!(modification, "A_S_CAPEX")
    end

    ### Modify ammonia sector demand
    if haskey(modification, "A_Demand")
        ammonia_inputs =
            modify_ammonia_demand(ammonia_settings, ammonia_inputs, modification["A_Demand"])
        delete!(modification, "A_Demand")
    end

    ### Modify ammonia sector emission policy (global modification)
    if !in(0, settings["CO2Policy"])
        ammonia_inputs =
            modify_ammonia_emission_policy(ammonia_settings, ammonia_inputs, modification)
    end

    inputs["AmmoniaInputs"] = ammonia_inputs

    return inputs, modification
end
