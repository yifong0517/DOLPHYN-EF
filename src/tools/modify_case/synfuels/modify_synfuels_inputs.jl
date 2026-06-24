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
function modify_synfuels_inputs(settings::Dict, inputs::Dict, modification::Dict)

    print_and_log(settings, "i", "Modifying Synfuels Inputs According to User's Modification")

    synfuels_inputs = inputs["SynfuelsInputs"]
    synfuels_settings = settings["SynfuelsSettings"]

    ## Modify synfuels sector inputs
    ### Modify synfuels sector generator maximum capacity
    if haskey(modification, "S_G_Max_Cap")
        synfuels_inputs = modify_synfuels_generator_max_cap(
            synfuels_settings,
            synfuels_inputs,
            modification["S_G_Max_Cap"],
        )
    end
    ### Modify synfuels sector generator existing capacity
    if haskey(modification, "S_G_Existing_Cap")
        synfuels_inputs = modify_synfuels_generator_existing_cap(
            synfuels_settings,
            synfuels_inputs,
            modification["S_G_Existing_Cap"],
        )
        delete!(modification, "S_G_Existing_Cap")
    end
    ### Modify synfuels sector generator minimum capacity
    if haskey(modification, "S_G_Min_Cap")
        synfuels_inputs = modify_synfuels_generator_min_cap(
            synfuels_settings,
            synfuels_inputs,
            modification["S_G_Min_Cap"],
        )
    end
    synfuels_inputs = modify_synfuels_generator_cap(synfuels_settings, synfuels_inputs)

    ### Modify synfuels sector generator full load hours
    if haskey(modification, "S_G_FLH")
        synfuels_inputs = modify_synfuels_generator_flh(
            synfuels_settings,
            synfuels_inputs,
            modification["S_G_FLH"],
        )
    end

    ### Modify synfuels sector generator capex
    if haskey(modification, "S_G_CAPEX")
        synfuels_inputs = modify_synfuels_generator_capex(
            synfuels_settings,
            synfuels_inputs,
            modification["S_G_CAPEX"],
        )
        delete!(modification, "S_G_CAPEX")
    end

    ### Modify synfuels sector storage maximum capacity
    if haskey(modification, "S_S_Max_Ene_Cap")
        synfuels_inputs = modify_synfuels_storage_max_ene_cap(
            synfuels_settings,
            synfuels_inputs,
            modification["S_S_Max_Ene_Cap"],
        )
    end
    ### Modify synfuels sector storage existing capacity
    if haskey(modification, "S_S_Existing_Ene_Cap")
        synfuels_inputs = modify_synfuels_storage_existing_ene_cap(
            synfuels_settings,
            synfuels_inputs,
            modification["S_S_Existing_Ene_Cap"],
        )
        delete!(modification, "S_S_Existing_Ene_Cap")
    end
    ### Modify synfuels sector storage minimum capacity
    if haskey(modification, "S_S_Min_Ene_Cap")
        synfuels_inputs = modify_synfuels_storage_min_ene_cap(
            synfuels_settings,
            synfuels_inputs,
            modification["S_S_Min_Ene_Cap"],
        )
    end

    ### Modify synfuels sector storage capex
    if haskey(modification, "S_S_CAPEX")
        synfuels_inputs = modify_synfuels_storage_capex(
            synfuels_settings,
            synfuels_inputs,
            modification["S_S_CAPEX"],
        )
        delete!(modification, "S_S_CAPEX")
    end

    ### Modify synfuels sector demand
    if haskey(modification, "S_Demand")
        synfuels_inputs =
            modify_synfuels_demand(synfuels_settings, synfuels_inputs, modification["S_Demand"])
        delete!(modification, "S_Demand")
    end

    ### Modify synfuels sector emission policy (global modification)
    if !in(0, settings["CO2Policy"])
        synfuels_inputs =
            modify_synfuels_emission_policy(synfuels_settings, synfuels_inputs, modification)
    end

    inputs["SynfuelsInputs"] = synfuels_inputs

    return inputs, modification
end
