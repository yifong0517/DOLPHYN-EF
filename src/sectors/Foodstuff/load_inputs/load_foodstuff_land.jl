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
function load_foodstuff_land(path::AbstractString, foodstuff_settings::Dict, inputs::Dict)

    ## Set indices for internal use
    GZones = inputs["Zones"] # Global list of modeled zones

    ## Foodstuff sector inputs dictionary
    foodstuff_inputs = inputs["FoodstuffInputs"]
    Zones = foodstuff_inputs["Zones"] # List of modeled zones in foodstuff sector

    ## Land related inputs
    path = joinpath(path, foodstuff_settings["LandPath"])
    dfLand = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter land from reference year
    dfLand = dfLand[!, Symbol.(["Zone", foodstuff_settings["ReferenceYear"]])]

    ## Filter land in modeled zones
    dfLand = filter(row -> (row.Zone in Zones), dfLand)

    ## Add zone index for each row
    dfLand[!, :ZoneIndex] = indexin(dfLand[!, :Zone], GZones)

    ## Calculate total arable land area
    foodstuff_inputs["TotalArableArea"] =
        sum(dfLand[!, Symbol(foodstuff_settings["ReferenceYear"])])

    ## Arable land area in each modeled zone
    foodstuff_inputs["dfLand"] = dfLand

    print_and_log(foodstuff_settings, "i", "Land Data Successfully Read from $path")

    inputs["FoodstuffInputs"] = foodstuff_inputs

    return inputs
end
