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
function modify_hydrogen_inputs(settings::Dict, inputs::Dict, modification::Dict)

    print_and_log(settings, "i", "Modifying Hydrogen Inputs According to User's Modification")

    hydrogen_inputs = inputs["HydrogenInputs"]
    hydrogen_settings = settings["HydrogenSettings"]

    ## Modify hydrogen sector inputs
    ### Modify hydrogen sector generator maximum capacity
    if haskey(modification, "H_G_Max_Cap")
        hydrogen_inputs = modify_hydrogen_generator_max_cap(
            hydrogen_settings,
            hydrogen_inputs,
            modification["H_G_Max_Cap"],
        )
    end
    ### Modify hydrogen sector generator existing capacity
    if haskey(modification, "H_G_Existing_Cap")
        hydrogen_inputs = modify_hydrogen_generator_existing_cap(
            hydrogen_settings,
            hydrogen_inputs,
            modification["H_G_Existing_Cap"],
        )
        delete!(modification, "H_G_Existing_Cap")
    end
    ### Modify hydrogen sector generator minimum capacity
    if haskey(modification, "H_G_Min_Cap")
        hydrogen_inputs = modify_hydrogen_generator_min_cap(
            hydrogen_settings,
            hydrogen_inputs,
            modification["H_G_Min_Cap"],
        )
    end
    hydrogen_inputs = modify_hydrogen_generator_cap(hydrogen_settings, hydrogen_inputs)

    ### Modify hydrogen sector generator full load hours
    if haskey(modification, "H_G_FLH")
        hydrogen_inputs = modify_hydrogen_generator_flh(
            hydrogen_settings,
            hydrogen_inputs,
            modification["H_G_FLH"],
        )
    end

    ### Modify hydrogen sector generators capex
    if haskey(modification, "H_G_CAPEX")
        hydrogen_inputs = modify_hydrogen_generator_capex(
            hydrogen_settings,
            hydrogen_inputs,
            modification["H_G_CAPEX"],
        )
        delete!(modification, "H_G_CAPEX")
    end
    ### Modify hydrogen sector generators efficiency
    if haskey(modification, "H_G_Efficiency")
        hydrogen_inputs = modify_hydrogen_generator_efficiency(
            hydrogen_settings,
            hydrogen_inputs,
            modification["H_G_Efficiency"],
        )
        delete!(modification, "H_G_Efficiency")
    end

    ### Modify hydrogen sector storage maximum capacity
    if haskey(modification, "H_S_Max_Ene_Cap")
        hydrogen_inputs = modify_hydrogen_storage_max_ene_cap(
            hydrogen_settings,
            hydrogen_inputs,
            modification["H_S_Max_Ene_Cap"],
        )
    end
    ### Modify hydrogen sector storage existing capacity
    if haskey(modification, "H_S_Existing_Ene_Cap")
        hydrogen_inputs = modify_hydrogen_storage_existing_ene_cap(
            hydrogen_settings,
            hydrogen_inputs,
            modification["H_S_Existing_Ene_Cap"],
        )
        delete!(modification, "H_S_Existing_Ene_Cap")
    end
    ### Modify hydrogen sector storage minimum capacity
    if haskey(modification, "H_S_Min_Ene_Cap")
        hydrogen_inputs = modify_hydrogen_storage_min_ene_cap(
            hydrogen_settings,
            hydrogen_inputs,
            modification["H_S_Min_Ene_Cap"],
        )
    end

    ### Modify hydrogen sector storage capex
    if haskey(modification, "H_S_CAPEX")
        hydrogen_inputs = modify_hydrogen_storage_capex(
            hydrogen_settings,
            hydrogen_inputs,
            modification["H_S_CAPEX"],
        )
        delete!(modification, "H_S_CAPEX")
    end

    ### Modify hydrogen sector demand
    if haskey(modification, "H_Demand")
        hydrogen_inputs =
            modify_hydrogen_demand(hydrogen_settings, hydrogen_inputs, modification["H_Demand"])
        delete!(modification, "H_Demand")
    end

    ### Modify hydrogen sector emission policy (global modification)
    if !in(0, settings["CO2Policy"])
        hydrogen_inputs =
            modify_hydrogen_emission_policy(hydrogen_settings, hydrogen_inputs, modification)
    end

    inputs["HydrogenInputs"] = hydrogen_inputs

    return inputs, modification
end
