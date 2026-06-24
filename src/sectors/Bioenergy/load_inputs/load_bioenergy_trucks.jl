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
function load_bioenergy_trucks(path::AbstractString, bioenergy_settings::Dict, inputs::Dict)

    ## Set indices for internal use
    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Bioenergy sector inputs dictionary
    bioenergy_inputs = inputs["BioenergyInputs"]

    ## Bioenergy truck type inputs
    truck_path = joinpath(path, bioenergy_settings["TrucksPath"])
    dfTru = DataFrame(CSV.File(truck_path, header = true), copycols = true)

    ## Filter truck types which are specified by truck types
    if haskey(bioenergy_settings, "TruckSet") && !in("All", bioenergy_settings["TruckSet"])
        ## Exclude some truck types from dataframe using "!"
        excluded = filter(x -> startswith(x, "!"), bioenergy_settings["TruckSet"])
        dfTru = filter(row -> !(row.Truck_Type in chop.(excluded, head = 1, tail = 0)), dfTru)
        ## Filter some truck types from dataframe after exclusion
        included = setdiff(bioenergy_settings["TruckSet"], excluded)
        if !isempty(included)
            dfTru = filter(row -> row.Truck_Type in included, dfTru)
        end
    end

    ## Bioenergy truck route inputs
    route_path = joinpath(path, bioenergy_settings["RoutesPath"])
    dfRoute = DataFrame(CSV.File(route_path, header = true), copycols = true)

    ## Filter truck route which links zones not modelled and drop those having same start and end
    dfRoute = filter(
        row -> (row.Start_Zone in Zones && row.End_Zone in Zones && row.Start_Zone != row.End_Zone),
        dfRoute,
    )

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
    bioenergy_inputs["R"] = size(collect(skipmissing(dfRoute[!, :R_ID])), 1)
    R = bioenergy_inputs["R"]

    ## Set of bioenergy truck types
    bioenergy_inputs["TRUCK_TYPES"] = dfTru[!, :T_ID]
    bioenergy_inputs["TRUCK_ZONES"] =
        sort(union(unique(dfRoute[!, :Start_Zone]), unique(dfRoute[!, :End_Zone])))

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
    colnames_truck_map = ["route_no", "Zone", "d"]
    rename!(Truck_map, Symbol.(colnames_truck_map))

    bioenergy_inputs["Truck_map"] = Truck_map

    ## Travel delay time for each type of truck on each route
    Travel_delay = Dict()
    for j in bioenergy_inputs["TRUCK_TYPES"]
        Travel_delay[j] = Dict()
        for r in 1:R
            Travel_delay[j][r] =
                ceil(Int64, dfRoute[!, :Distance][r] / dfTru[!, :Avg_Truck_Speed_mile_per_hour][j])
        end
    end

    bioenergy_inputs["Travel_delay"] = Travel_delay

    ## Store DataFrame of truck input data for use in model
    bioenergy_inputs["dfTru"] = dfTru
    bioenergy_inputs["dfRoute"] = dfRoute

    print_and_log(bioenergy_settings, "i", "Trucks Data Successfully Read from $truck_path")
    print_and_log(bioenergy_settings, "i", "Routes Data Successfully Read from $route_path")

    inputs["BioenergyInputs"] = bioenergy_inputs

    return inputs
end
