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
function load_bioenergy_residual_types(settings::Dict, inputs::Dict)

    bioenergy_settings = settings["BioenergySettings"]

    bioenergy_inputs = inputs["BioenergyInputs"]

    ## Potential residuals within each sector
    potential_residuals = []

    ## Residuals within power sectors
    if settings["ModelPower"] == 1
        power_inputs = inputs["PowerInputs"]
        dfGen = power_inputs["dfGen"]
        power_residuals = setdiff(collect(dfGen[!, :Bioenergy]), ["None"])
        potential_residuals = union(potential_residuals, power_residuals)
    end

    ## Residuals within hydrogen sector
    if settings["ModelHydrogen"] == 1
        hydrogen_inputs = inputs["HydrogenInputs"]
        dfGen = hydrogen_inputs["dfGen"]
        hydrogen_residuals = setdiff(collect(dfGen[!, :Bioenergy]), ["None"])
        potential_residuals = union(potential_residuals, hydrogen_residuals)
    end

    ## Residuals within carbon sector
    if settings["ModelCarbon"] == 1
        carbon_inputs = inputs["CarbonInputs"]
        dfGen = carbon_inputs["dfGen"]
        carbon_residuals = setdiff(collect(dfGen[!, :Bioenergy]), ["None"])
        potential_residuals = union(potential_residuals, carbon_residuals)
    end

    ## Residuals within synfuels sector
    if settings["ModelSynfuels"] == 1
        synfuels_inputs = inputs["SynfuelsInputs"]
        dfGen = synfuels_inputs["dfGen"]
        synfuels_residuals = setdiff(collect(dfGen[!, :Bioenergy]), ["None"])
        potential_residuals = union(potential_residuals, synfuels_residuals)
    end

    ## Residuals within ammonia sector
    if settings["ModelAmmonia"] == 1
        ammonia_inputs = inputs["AmmoniaInputs"]
        dfGen = ammonia_inputs["dfGen"]
        ammonia_residuals = setdiff(collect(dfGen[!, :Bioenergy]), ["None"])
        potential_residuals = union(potential_residuals, ammonia_residuals)
    end

    potential_residuals = intersect(potential_residuals, bioenergy_settings["Residuals"])

    ## Warning prompt for empty residuals
    if isempty(potential_residuals)
        print_and_log(settings, "w", "No Bioenergy Residual Found to be Modeled in the System")
    end

    ## Bioenergy sector solo takes Residuals from settings
    if isempty(potential_residuals) &&
       !(settings["ModelPower"] == 1) &&
       !(settings["ModelHydrogen"] == 1) &&
       !(settings["ModelCarbon"] == 1) &&
       !(settings["ModelSynfuels"] == 1) &&
       !(settings["ModelAmmonia"] == 1) &&
       !(settings["ModelFoodstuff"] == 1)
        print_and_log(settings, "i", "Bioenergy Sector Solo Takes Residuals from Settings")
        potential_residuals = bioenergy_settings["Residuals"]
    end

    if settings["ModelFoodstuff"] == 1
        ## Residuals with foodstuff sectors
        foodstuff_inputs = inputs["FoodstuffInputs"]
        Straws = foodstuff_inputs["Straws"]
        Agriculture_Production_Residuals = foodstuff_inputs["Agriculture_Production_Residuals"]
        Residuals = intersect(
            bioenergy_settings["Residuals"],
            potential_residuals,
            union(Straws, Agriculture_Production_Residuals),
        )
    else
        Residuals = intersect(bioenergy_settings["Residuals"], potential_residuals)
    end

    bioenergy_inputs["Residuals"] = Residuals
    inputs["BioenergyInputs"] = bioenergy_inputs

    return inputs
end
