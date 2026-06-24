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
function load_hydrogen_routes(path::AbstractString, hydrogen_settings::Dict, inputs::Dict)

    ## Set indices for internal use
    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Hydrogen sector inputs dictionary
    hydrogen_inputs = inputs["HydrogenInputs"]

    ## Hydrogen truck route inputs
    route_path = joinpath(path, hydrogen_settings["RoutesPath"])
    dfRoute = DataFrame(CSV.File(route_path, header = true), copycols = true)

    ## Filter truck route which links zones not modelled and drop those having same start and end
    dfRoute = filter(
        row -> (row.Start_Zone in Zones && row.End_Zone in Zones && row.Start_Zone != row.End_Zone),
        dfRoute,
    )

    ## Add truck route IDs after reading to prevent user errors
    dfRoute[!, :R_ID] = 1:size(collect(skipmissing(dfRoute[!, 1])), 1)

    ## Add truck route name denoting the direction
    dfRoute[!, "-1"] = string.(dfRoute[!, :End_Zone], " -> ", dfRoute[!, :Start_Zone])
    dfRoute[!, "1"] = string.(dfRoute[!, :Start_Zone], " -> ", dfRoute[!, :End_Zone])

    ## Number of routes in the network
    hydrogen_inputs["R"] = size(collect(skipmissing(dfRoute[!, :R_ID])), 1)
    R = hydrogen_inputs["R"]

    hydrogen_inputs["TRANSPORT_ZONES"] =
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

    hydrogen_inputs["Transport_map"] = Transport_map

    hydrogen_inputs["dfRoute"] = dfRoute

    inputs["HydrogenInputs"] = hydrogen_inputs

    print_and_log(hydrogen_settings, "i", "Routes Data Successfully Read from $route_path")

    return inputs
end
