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
function load_foodstuff_routes(path::AbstractString, foodstuff_settings::Dict, inputs::Dict)

    ## Set indices for internal use
    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Foodstuff sector inputs dictionary
    foodstuff_inputs = inputs["FoodstuffInputs"]

    ## Foodstuff truck route inputs
    route_path = joinpath(path, foodstuff_settings["RoutesPath"])
    dfRoute = DataFrame(CSV.File(route_path, header = true), copycols = true)

    ## Filter truck route which links zones not modelled and drop those having same start and end
    dfRoute = filter(
        row -> (row.Start_Zone in Zones && row.End_Zone in Zones && row.Start_Zone != row.End_Zone),
        dfRoute,
    )

    ## Add truck route IDs after reading to prevent user errors
    dfRoute[!, :R_ID] = 1:size(collect(skipmissing(dfRoute[!, 1])), 1)

    ## Add ship route name denoting the direction
    dfRoute[!, "-1"] = string.(dfRoute[!, :End_Zone], " -> ", dfRoute[!, :Start_Zone])
    dfRoute[!, "1"] = string.(dfRoute[!, :Start_Zone], " -> ", dfRoute[!, :End_Zone])

    ## Number of routes in the network
    foodstuff_inputs["R"] = size(collect(skipmissing(dfRoute[!, :R_ID])), 1)
    R = foodstuff_inputs["R"]

    foodstuff_inputs["TRANSPORT_ZONES"] =
        sort(union(unique(dfRoute[!, :Start_Zone]), unique(dfRoute[!, :End_Zone])))

    ## Topology of the ship network source-sink matrix
    Transport_map = zeros(Int64, R, Z)

    for r in 1:R
        z_start = indexin([dfRoute[!, :Start_Zone][r]], Zones)[1]
        z_end = indexin([dfRoute[!, :End_Zone][r]], Zones)[1]
        Transport_map[r, z_start] = 1
        Transport_map[r, z_end] = -1
    end

    Transport_map = DataFrame(Transport_map, Symbol.(Zones))

    ## Create route number column
    Transport_map[!, :route_no] = 1:size(Transport_map, 1)

    ## Pivot table
    Transport_map = stack(Transport_map, Zones)

    ## Remove redundant rows
    Transport_map = Transport_map[Transport_map[!, :value] .!= 0, :]

    ## Rename column
    colnames_truck_map = ["route_no", "Zone", "d"]
    rename!(Transport_map, Symbol.(colnames_truck_map))

    foodstuff_inputs["Transport_map"] = Transport_map

    foodstuff_inputs["dfRoute"] = dfRoute

    inputs["FoodstuffInputs"] = foodstuff_inputs

    return inputs
end
