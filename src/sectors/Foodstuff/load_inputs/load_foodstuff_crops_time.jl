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
function load_foodstuff_crops_time(path::AbstractString, foodstuff_settings::Dict, inputs::Dict)

    ## Set indices for internal use
    T = inputs["T"]   # Number of time steps (hours)

    ## Foodstuff sector inputs dictionary
    foodstuff_inputs = inputs["FoodstuffInputs"]

    ## Set indices for internal use
    CT = foodstuff_inputs["CT"]

    path = joinpath(path, foodstuff_settings["CropTimePath"])
    dfCropTime = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Reorder DataFrame to C_ID order (order provided in CropPath)
    select!(dfCropTime, [:Time_Index; Symbol.(foodstuff_inputs["Crop_Type"])])

    ## Crop phenology time sequence including sowing, growth and harvest
    foodstuff_inputs["dfCrop_Phenology"] = dfCropTime

    ## Crop land state time length count (sowing = 1; growth = 2; harvest = 3; free = 0)
    foodstuff_inputs["dfCrop_LandState"] = rename!(
        reduce(vcat, [DataFrame(countmap(Symbol.(col))) for col in eachcol(dfCropTime)[2:end]]),
        Dict(Symbol.(["0", "1", "2", "3"]) .=> ["Free", "Sowing", "Growth", "Harvest"]),
    )

    ## Crop land availability time sequence (sowing, growth and harvest as 1 and free as 0)
    foodstuff_inputs["dfCrop_LandAvail"] = hcat(
        dfCropTime[:, [:Time_Index]],
        map.(x -> x >= 1 ? 1 : 0, dfCropTime[:, Not(:Time_Index)]),
    )

    print_and_log(foodstuff_settings, "i", "Crops' Phenology Successfully Read from $path")

    inputs["FoodstuffInputs"] = foodstuff_inputs

    return inputs
end
