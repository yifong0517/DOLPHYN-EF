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
function load_foodstuff_crops(path::AbstractString, foodstuff_settings::Dict, inputs::Dict)

    ## Set indices for internal use
    GZones = inputs["Zones"] # Global list of modeled zones
    Crops = foodstuff_settings["Crops"] # List of modeled crop types

    ## Foodstuff sector inputs dictionary
    foodstuff_inputs = inputs["FoodstuffInputs"]

    ## Store Crops list into foodstuff inputs from settings
    foodstuff_inputs["Crops"] = Crops
    Zones = foodstuff_inputs["Zones"] # List of modeled zones in foodstuff sector

    ## Crops related inputs
    path = joinpath(path, foodstuff_settings["CropPath"])
    dfCrop = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter crops in modeled zones
    dfCrop = filter(row -> (row.Zone in Zones), dfCrop)

    ## Filter crops in modeled crop types
    dfCrop = filter(row -> (row.Crop in Crops), dfCrop)

    ## Add crop IDs after reading to prevent user errors
    dfCrop[!, :CT_ID] = 1:size(collect(skipmissing(dfCrop[!, 1])), 1)

    ## Add zone index for each resource
    dfCrop[!, :ZoneIndex] = indexin(dfCrop[!, :Zone], GZones)

    ## Store DataFrame of crops input data for use in model
    foodstuff_inputs["dfCrop"] = dfCrop

    ## Number of crops
    foodstuff_inputs["CT"] = size(collect(skipmissing(dfCrop[!, :CT_ID])), 1)

    ## Names of crops
    foodstuff_inputs["Crop_Type"] = collect(skipmissing(dfCrop[!, :Crop_Type]))

    ## Straw type list
    foodstuff_inputs["Straws"] =
        setdiff(unique(collect(skipmissing(dfCrop[!, :Straw_Type]))), ["None"])

    ## Extract food dataframe from crop dataframe
    use_cols = [
        "Zone",
        "Crop",
        "Crop_Rotation_Type",
        "Crop_Rotation_Rate",
        "Production_Food_Percentage",
        "Production_Food_Rate",
    ]
    dfRotation = unique(dfCrop[!, Symbol.(use_cols)])

    ## Store DataFrame of crop rotation input data for use in model
    foodstuff_inputs["dfRotation"] = dfRotation

    print_and_log(foodstuff_settings, "i", "Crops Data Successfully Read from $path")

    inputs["FoodstuffInputs"] = foodstuff_inputs

    return inputs
end
