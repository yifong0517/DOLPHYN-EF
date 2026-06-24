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
function load_carbon_trucks(path::AbstractString, carbon_settings::Dict, inputs::Dict)

    ## Carbon sector inputs dictionary
    carbon_inputs = inputs["CarbonInputs"]
    dfRoute = carbon_inputs["dfRoute"]
    R = carbon_inputs["R"]

    ## Carbon truck type inputs
    truck_path = joinpath(path, carbon_settings["TrucksPath"])
    dfTru = DataFrame(CSV.File(truck_path, header = true), copycols = true)

    ## Filter truck types which are specified by truck types
    if haskey(carbon_settings, "TruckSet") && !in("All", carbon_settings["TruckSet"])
        ## Exclude some truck types from dataframe using "!"
        excluded = filter(x -> startswith(x, "!"), carbon_settings["TruckSet"])
        excluded = map(x -> chop(x, head = 1, tail = 0), excluded)
        if !isempty(excluded)
            print_and_log(carbon_settings, "i", "Excluding Carbon Truck Types: $excluded")
            dfTru = filter(row -> !(row.Truck_Type in excluded), dfTru)
        end
        ## Filter some truck types from dataframe after exclusion
        included = setdiff(carbon_settings["TruckSet"], excluded)
        if !isempty(included)
            print_and_log(carbon_settings, "i", "Including Carbon Truck Types: $included")
            dfTru = filter(row -> row.Truck_Type in included, dfTru)
        end
    else
        print_and_log(carbon_settings, "i", "Including All Carbon Truck Types")
    end

    ## Add truck IDs after reading to prevent user errors
    dfTru[!, :T_ID] = 1:size(collect(skipmissing(dfTru[!, 1])), 1)

    ## Calculate AF for each truck type with trailer
    dfTru[!, :Truck_AF] =
        dfTru[!, :Truck_WACC] ./ (1 .- (1 .+ dfTru[!, :Truck_WACC]) .^ (-dfTru[!, :Truck_Lifetime]))
    dfTru[!, :Trailer_AF] =
        dfTru[!, :Trailer_WACC] ./
        (1 .- (1 .+ dfTru[!, :Trailer_WACC]) .^ (-dfTru[!, :Trailer_Lifetime]))
    dfTru[!, :Comp_AF] =
        dfTru[!, :Comp_WACC] ./ (1 .- (1 .+ dfTru[!, :Comp_WACC]) .^ (-dfTru[!, :Comp_Lifetime]))

    ## Calculate fixed OM costs for each truck type
    dfTru[!, :Fixed_OM_Cost_Truck_per_unit] =
        round.(
            dfTru[!, :Inv_Cost_Truck_per_unit] .* dfTru[!, :Fixed_OM_Cost_Truck_Percentage];
            sigdigits = 6,
        )
    dfTru[!, :Fixed_OM_Cost_Trailer_per_number] =
        round.(
            dfTru[!, :Inv_Cost_Trailer_per_number] .* dfTru[!, :Fixed_OM_Cost_Trailer_Percentage];
            sigdigits = 6,
        )
    dfTru[!, :Fixed_OM_Cost_Comp_per_tonne_per_hr] =
        round.(
            dfTru[!, :Inv_Cost_Comp_per_tonne_per_hr] .* dfTru[!, :Fixed_OM_Cost_Comp_Percentage];
            sigdigits = 6,
        )

    ## Add column for truck unit capacity
    dfTru[:, :Truck_Cap_tonne_per_unit] =
        dfTru[:, :Trailer_Number] .* dfTru[!, :Cap_tonne_per_trailer]

    ## Set of carbon truck types
    carbon_inputs["TRUCK_TYPES"] = dfTru[!, :T_ID]

    ## Travel delay time for each type of truck on each route
    Travel_delay = Dict()
    for j in carbon_inputs["TRUCK_TYPES"]
        Travel_delay[j] = Dict()
        for r in 1:R
            Travel_delay[j][r] =
                ceil(Int64, dfRoute[!, :Distance][r] / dfTru[!, :Avg_Truck_Speed_mile_per_hour][j])
        end
    end

    carbon_inputs["Travel_delay"] = Travel_delay

    ## Store DataFrame of truck input data for use in model
    carbon_inputs["dfTru"] = dfTru

    print_and_log(carbon_settings, "i", "Trucks Data Successfully Read from $truck_path")

    inputs["CarbonInputs"] = carbon_inputs

    return inputs
end
