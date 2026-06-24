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
function write_settings(settings::Dict)

    path = settings["SavePath"]

    dfs = []
    ## Global settings
    dfGlobalSettings = settings["dfGlobalSettings"]
    push!(dfs, dfGlobalSettings)

    ## Resource settings
    dfResourceSettings = settings["ResourceSettings"]["dfResourceSettings"]
    push!(dfs, dfResourceSettings)

    ## Time aggregation settings
    TimeMode = settings["TimeMode"]
    if TimeMode == "PTFE" || TimeMode == "APTTA-1" || TimeMode == "APTTA-2"
        dfClusterSettings = settings["ClusterSettings"]["dfTimeAggregationSettings"]
        push!(dfs, dfClusterSettings)
    end

    ## Power sector settings
    if settings["ModelPower"] == 1
        power_settings = settings["PowerSettings"]
        dfPowerSettings = power_settings["dfPowerSettings"]
        push!(dfs, dfPowerSettings)
    end

    ## Hydrogen sector settings
    if settings["ModelHydrogen"] == 1
        hydrogen_settings = settings["HydrogenSettings"]
        dfHydrogenSettings = hydrogen_settings["dfHydrogenSettings"]
        push!(dfs, dfHydrogenSettings)
    end

    ## Carbon sector settings
    if settings["ModelCarbon"] == 1
        carbon_settings = settings["CarbonSettings"]
        dfCarbonSettings = carbon_settings["dfCarbonSettings"]
        push!(dfs, dfCarbonSettings)
    end

    ## Synfuels sector settings
    if settings["ModelSynfuels"] == 1
        synfuels_settings = settings["SynfuelsSettings"]
        dfSynfuelsSettings = synfuels_settings["dfSynfuelsSettings"]
        push!(dfs, dfSynfuelsSettings)
    end

    ## Bioenergy sector settings
    if settings["ModelBioenergy"] == 1
        bioenergy_settings = settings["BioenergySettings"]
        dfBioenergySettings = bioenergy_settings["dfBioenergySettings"]
        push!(dfs, dfBioenergySettings)
    end

    ## Foodstuff sector settings
    if settings["ModelFoodstuff"] == 1
        foodstuff_settings = settings["FoodstuffSettings"]
        dfFoodstuffSettings = foodstuff_settings["dfFoodstuffSettings"]
        push!(dfs, dfFoodstuffSettings)
    end

    ## Write settings
    df = reduce(vcat, dfs)

    ## Database writing
    if haskey(settings, "DB")
        SQLite.load!(df, settings["DB"], "Settings")
    end

    ## CSV file writing
    CSV.write(joinpath(path, "settings.csv"), df)
end
