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
function load_foodstuff_trucks(path::AbstractString, foodstuff_settings::Dict, inputs::Dict)

    ## Set indices for internal use
    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Foodstuff sector inputs dictionary
    foodstuff_inputs = inputs["FoodstuffInputs"]

    ## Foodstuff truck type inputs
    truck_path = joinpath(path, foodstuff_settings["TrucksPath"])
    dfTru = DataFrame(CSV.File(truck_path, header = true), copycols = true)

    ## Add truck IDs after reading to prevent user errors
    dfTru[!, :T_ID] = 1:size(collect(skipmissing(dfTru[!, 1])), 1)

    ## Calculate AF for each truck type with trailer
    dfTru[!, :AF] = dfTru[!, :WACC] ./ (1 .- (1 .+ dfTru[!, :WACC]) .^ (-dfTru[!, :Lifetime]))
    ## Calculate fixed OM costs for each truck type

    dfTru[!, :Fixed_OM_Cost_Truck_per_unit] =
        round.(
            dfTru[!, :Inv_Cost_Truck_per_unit] .* dfTru[!, :Fixed_OM_Cost_Truck_Percentage];
            sigdigits = 6,
        )

    ## Add truck route IDs after reading to prevent user errors
    dfRoute[!, :R_ID] = 1:size(collect(skipmissing(dfRoute[!, 1])), 1)

    ## Add truck route name denoting the direction
    dfRoute[!, "-1"] = string.(dfRoute[!, :End_Zone], " -> ", dfRoute[!, :Start_Zone])
    dfRoute[!, "1"] = string.(dfRoute[!, :Start_Zone], " -> ", dfRoute[!, :End_Zone])

    ## Number of routes in the network
    foodstuff_inputs["R"] = size(collect(skipmissing(dfRoute[!, :R_ID])), 1)
    R = foodstuff_inputs["R"]

    ## Set of foodstuff truck types
    foodstuff_inputs["TRUCK_TYPES"] = dfTru[!, :T_ID]
    foodstuff_inputs["TRUCK_ZONES"] =
        union(unique(dfRoute[!, :Start_Zone]), unique(dfRoute[!, :End_Zone]))

    ## Topology of the truck network source-sink matrix
    Truck_map = zeros(Int64, R, Z)

    for r in 1:R
        z_start = indexin([dfRoute[!, :Start_Zone][r]], Zones)[1]
        z_end = indexin([dfRoute[!, :End_Zone][r]], Zones)[1]
        Truck_map[r, z_start] = 1
        Truck_map[r, z_end] = -1
    end

    Truck_map = DataFrame(Truck_map, Symbol.(Zones))

    ## Create route number column
    Truck_map[!, :route_no] = 1:size(Truck_map, 1)

    ## Pivot table
    Truck_map = stack(Truck_map, Zones)

    ## Remove redundant rows
    Truck_map = Truck_map[Truck_map[!, :value] .!= 0, :]

    ## Rename column
    colnames_pipe_map = ["route_no", "Zone", "d"]
    rename!(Truck_map, Symbol.(colnames_pipe_map))

    foodstuff_inputs["Truck_map"] = Truck_map

    ## Travel delay time for each type of truck on each route
    Travel_delay = Dict()
    for j in foodstuff_inputs["TRUCK_TYPES"]
        Travel_delay[j] = Dict()
        for r in 1:R
            Travel_delay[j][r] =
                ceil(Int64, dfRoute[!, :Distance][r] / dfTru[!, :Avg_Truck_Speed_mile_per_hour][j])
        end
    end

    foodstuff_inputs["Travel_delay"] = Travel_delay

    ## Store DataFrame of truck input data for use in model
    foodstuff_inputs["dfTru"] = dfTru
    foodstuff_inputs["dfRoute"] = dfRoute

    print_and_log(foodstuff_settings, "i", "Trucks Data Successfully Read from $truck_path")
    print_and_log(foodstuff_settings, "i", "Routes Data Successfully Read from $route_path")

    inputs["FoodstuffInputs"] = foodstuff_inputs

    return inputs
end
