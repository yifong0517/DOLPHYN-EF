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
function load_auxiliary_inputs(settings::Dict, inputs::Dict)

    print_and_log(settings, "i", "Loading and Store Auxiliary Flags in Inputs")

    ## Convert Zones to string for writing outputs
    inputs["Zones"] = string.(inputs["Zones"])

    ## Model type flag
    LinearModel = true

    ## Power sector flags
    if settings["ModelPower"] == 1
        power_settings = settings["PowerSettings"]
        LinearModel &= !(power_settings["UCommit"] == 1)
        LinearModel &= !(power_settings["ScaleEffect"] == 1)
    end

    ## Hydrogen sector flags
    if settings["ModelHydrogen"] == 1
        hydrogen_settings = settings["HydrogenSettings"]
        LinearModel &= !(hydrogen_settings["GenCommit"] == 1)
        LinearModel &= !(hydrogen_settings["ScaleEffect"] == 1)
        if hydrogen_settings["ModelPipelines"] == 1
            LinearModel &= !(hydrogen_settings["PipeInteger"] == 1)
        end
        if hydrogen_settings["ModelTrucks"] == 1
            LinearModel &= !(hydrogen_settings["TruckInteger"] == 1)
        end
    end

    ## Carbon sector flags
    if settings["ModelCarbon"] == 1
        carbon_settings = settings["CarbonSettings"]
        LinearModel &= !(carbon_settings["CapCommit"] == 1)
        LinearModel &= !(carbon_settings["ScaleEffect"] == 1)
        if carbon_settings["ModelPipelines"] == 1
            LinearModel &= !(carbon_settings["PipeInteger"] == 1)
        end
        if carbon_settings["ModelTrucks"] == 1
            LinearModel &= !(carbon_settings["TruckInteger"] == 1)
        end
    end

    ## Synfuels sector flags
    if settings["ModelSynfuels"] == 1
        synfuels_settings = settings["SynfuelsSettings"]
        LinearModel &= !(synfuels_settings["GenCommit"] == 1)
        LinearModel &= !(synfuels_settings["ScaleEffect"] == 1)
        if synfuels_settings["ModelPipelines"] == 1
            LinearModel &= !(synfuels_settings["PipeInteger"] == 1)
        end
        if synfuels_settings["ModelTrucks"] == 1
            LinearModel &= !(synfuels_settings["TruckInteger"] == 1)
        end
    end

    ## Ammonia sector flags
    if settings["ModelAmmonia"] == 1
        ammonia_settings = settings["AmmoniaSettings"]
        LinearModel &= !(ammonia_settings["GenCommit"] == 1)
        LinearModel &= !(ammonia_settings["ScaleEffect"] == 1)
        if ammonia_settings["ModelTrucks"] == 1
            LinearModel &= !(ammonia_settings["TruckInteger"] == 1)
        end
    end

    ## Foodstuff sector flags
    if settings["ModelFoodstuff"] == 1
        foodstuff_settings = settings["FoodstuffSettings"]
        if foodstuff_settings["ModelTrucks"] == 1
            LinearModel &= !(foodstuff_settings["TruckInteger"] == 1)
        end
    end

    ## Bioenergy sector flags
    if settings["ModelBioenergy"] == 1
        bioenergy_settings = settings["BioenergySettings"]
        if bioenergy_settings["ModelTrucks"] == 1
            LinearModel &= !(bioenergy_settings["TruckInteger"] == 1)
        end
    end

    ## Store model type flag in inputs
    inputs["LinearModel"] = LinearModel

    return inputs
end
