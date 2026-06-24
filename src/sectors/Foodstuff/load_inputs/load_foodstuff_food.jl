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
function load_foodstuff_food(path::AbstractString, foodstuff_settings::Dict, inputs::Dict)

    ## Food related inputs
    path = joinpath(path, foodstuff_settings["CropPath"])

    ## Foodstuff sector inputs dictionary
    foodstuff_inputs = inputs["FoodstuffInputs"]

    dfCrop = foodstuff_inputs["dfCrop"]

    ## Extract food dataframe from crop dataframe
    use_cols = [
        "Zone",
        "Crop",
        "Production_Biomass_Type",
        "Production_Biomass_Percentage",
        "Production_Biomass_Rate",
        "Production_Food_Type",
        "Production_Food_Percentage",
        "Production_Food_Rate",
        "Production_Food_Cost",
    ]
    dfFood = unique(dfCrop[!, Symbol.(use_cols)])

    ## Store food list into foodstuff inputs from food dataframe
    foodstuff_inputs["Foods"] =
        setdiff(unique(collect(skipmissing(dfFood[!, :Production_Food_Type]))), ["None"])

    ## Store residuals list into foodstuff inputs from food dataframe
    foodstuff_inputs["Agriculture_Production_Residuals"] =
        setdiff(unique(collect(skipmissing(dfFood[!, :Production_Biomass_Type]))), ["None"])

    ## Add food type to identify each food with zone
    dfFood[!, :Food_Type] = dfFood[!, :Zone] .* dfFood[!, :Production_Food_Type]

    ## Add food IDs after reading to prevent user errors
    dfFood[!, :FT_ID] = 1:size(collect(skipmissing(dfFood[!, 1])), 1)

    ## Store DataFrame of crops input data for use in model
    foodstuff_inputs["dfFood"] = dfFood

    ## Number of crops
    foodstuff_inputs["FT"] = size(collect(skipmissing(dfFood[!, :FT_ID])), 1)

    ## Names of crops
    foodstuff_inputs["Food_Type"] = collect(skipmissing(dfFood[!, :Food_Type]))

    print_and_log(foodstuff_settings, "i", "Food Data Successfully Read from $path")

    inputs["FoodstuffInputs"] = foodstuff_inputs

    return inputs
end
