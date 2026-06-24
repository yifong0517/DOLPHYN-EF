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
    load_foodstuff_import(path::AbstractString, foodstuff_settings::Dict, inputs::Dict)

"""
function load_foodstuff_import(path::AbstractString, foodstuff_settings::Dict, inputs::Dict)

    ## Set indices for internal use
    GZones = inputs["Zones"] # Global list of modeled zones
    Crops = foodstuff_settings["Crops"] # List of modeled crop types

    ## Foodstuff sector inputs dictionary
    foodstuff_inputs = inputs["FoodstuffInputs"]

    Zones = foodstuff_inputs["Zones"] # List of modeled zones in foodstuff sector

    ## Crop import related inputs
    path = joinpath(path, foodstuff_settings["ImportPath"])
    dfImport = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter crops in modeled zones
    dfImport = filter(row -> (row.Zone in Zones), dfImport)

    ## Filter crops in modeled crop types
    dfImport = filter(row -> (row.Crop in Crops), dfImport)

    ## Ensure that zone and crop combination is complete
    combination_complete = collect(product(Zones, Crops))
    combination_existing = Tuple.(eachrow(dfImport[!, [:Zone, :Crop]]))

    for comb in setdiff(combination_complete, combination_existing)
        zone, crop = comb
        push!(
            dfImport,
            Dict(
                :Zone => zone,
                :Crop => crop,
                :Raw_Grain_Rate => 1,
                :Trade_Price_tonne => 0,
                :Trade_Limit_Percentage => 0,
            ),
        )
    end

    ## Add crop IDs after reading to prevent user errors
    dfImport[!, :CT_ID] = 1:size(collect(skipmissing(dfImport[!, 1])), 1)

    ## Add zone index for each resource
    dfImport[!, :ZoneIndex] = indexin(dfImport[!, :Zone], GZones)

    ## Store DataFrame of crops import data for use in model
    foodstuff_inputs["dfImport"] = dfImport

    print_and_log(foodstuff_settings, "i", "Crop Import Data Successfully Read from $path")

    inputs["FoodstuffInputs"] = foodstuff_inputs

    return inputs
end
