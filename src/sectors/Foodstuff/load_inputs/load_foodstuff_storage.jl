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
    load_foodstuff_storage(path::AbstractString, foodstuff_settings::Dict, inputs::Dict)

"""
function load_foodstuff_storage(path::AbstractString, foodstuff_settings::Dict, inputs::Dict)

    ## Set indices for internal use
    T = inputs["T"]   # Number of time steps (hours)
    GZones = inputs["Zones"] # Global list of modeled zones

    ## Foodstuff sector inputs dictionary
    foodstuff_inputs = inputs["FoodstuffInputs"]
    Zones = foodstuff_inputs["Zones"] # List of modeled zones in foodstuff sector
    Foods = foodstuff_inputs["Foods"]

    ## Storage related inputs
    path = joinpath(path, foodstuff_settings["StoragePath"])
    dfSto = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter resources in modeled zones
    dfSto = filter(row -> (row.Zone in Zones), dfSto)

    ## Filter resources in modeled crops
    dfSto = filter(row -> (row.Food in Foods), dfSto)

    ## Add Resource IDs after reading to prevent user errors
    dfSto[!, :R_ID] = 1:size(collect(skipmissing(dfSto[!, 1])), 1)

    ## Add zone index for each resource
    dfSto[!, :ZoneIndex] = indexin(dfSto[!, :Zone], GZones)

    ## Calculate AF for each storage resource
    dfSto[!, :AF] = dfSto[!, :WACC] ./ (1 .- (1 .+ dfSto[!, :WACC]) .^ (-dfSto[!, :Lifetime]))

    ## Number of resources
    foodstuff_inputs["S"] = size(collect(skipmissing(dfSto[!, :R_ID])), 1)

    ## Store DataFrame of generators/resources input data for use in model
    foodstuff_inputs["dfSto"] = dfSto

    ## Defining sets of generation and storage resources
    ## Set of all storage resources eligible for new energy capacity
    foodstuff_inputs["NEW_STO_CAP"] = dfSto[dfSto.New_Build .== 1, :R_ID]

    ## Set of all storage resources eligible for energy capacity retirements
    foodstuff_inputs["RET_STO_CAP"] = dfSto[dfSto.New_Build .!= -1, :R_ID]

    print_and_log(foodstuff_settings, "i", "Storage Data Successfully Read from $path")

    inputs["FoodstuffInputs"] = foodstuff_inputs

    return inputs
end
