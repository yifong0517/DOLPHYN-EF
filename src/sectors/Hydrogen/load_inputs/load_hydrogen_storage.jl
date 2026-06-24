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
    load_hydrogen_storage(path::AbstractString, hydrogen_settings::Dict, inputs::Dict)

"""
function load_hydrogen_storage(path::AbstractString, hydrogen_settings::Dict, inputs::Dict)

    ## Flags
    StorageExpansion = hydrogen_settings["StorageExpansion"]

    ## Set indices for internal use
    T = inputs["T"]   # Number of time steps (hours)
    GZones = inputs["Zones"] # Global list of modeled zones

    ## Hydrogen sector inputs dictionary
    hydrogen_inputs = inputs["HydrogenInputs"]
    Zones = hydrogen_inputs["Zones"] # List of modeled zones in hydrogen sector

    ## Storage related inputs
    path = joinpath(path, hydrogen_settings["StoragePath"])
    dfSto = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter resources in modeled zones
    dfSto = filter(row -> (row.Zone in Zones), dfSto)

    ## Filter resources in modeled types
    if haskey(hydrogen_settings, "StorageSet") && !in("All", hydrogen_settings["StorageSet"])
        ## Exclude some resources from dataframe using "!"
        excluded = filter(x -> startswith(x, "!"), hydrogen_settings["StorageSet"])
        ## Filter some resources from dataframe after exclusion
        included = setdiff(hydrogen_settings["StorageSet"], excluded)
        excluded = map(x -> chop(x, head = 1, tail = 0), excluded)
        if !isempty(excluded)
            print_and_log(hydrogen_settings, "i", "Excluding Hydrogen Storage Resources: $excluded")
            dfSto = filter(row -> !(row.Resource_Type in excluded), dfSto)
        end
        if !isempty(included)
            print_and_log(hydrogen_settings, "i", "Including Hydrogen Storage Resources: $included")
            dfSto = filter(row -> (row.Resource_Type in included), dfSto)
        end
    else
        print_and_log(hydrogen_settings, "i", "Including All Hydrogen Storage Types")
    end

    ## Filter resources in modeled types
    if haskey(hydrogen_settings, "StorageIndex") && !in("All", hydrogen_settings["StorageIndex"])
        ## Exclude some resources from dataframe using "!"
        excluded = filter(x -> startswith(x, "!"), hydrogen_settings["StorageIndex"])
        ## Filter some resources from dataframe after exclusion
        included = setdiff(hydrogen_settings["StorageIndex"], excluded)
        excluded = map(x -> chop(x, head = 1, tail = 0), excluded)
        ## Filter some zones from zone list using wildcard
        wildcard = filter(x -> startswith(x, "*"), hydrogen_settings["StorageIndex"])
        included = setdiff(included, wildcard)
        wildcard = chop.(wildcard, head = 1, tail = 0)
        if !isempty(excluded)
            print_and_log(hydrogen_settings, "i", "Excluding Hydrogen Storage Resources: $excluded")
            dfSto = filter(row -> !(row.Resource in excluded), dfSto)
        end
        if !isempty(wildcard)
            print_and_log(
                hydrogen_settings,
                "i",
                "Including Hydrogen Storage Resources: *$wildcard",
            )
            dfSto = filter(row -> (any(endswith.(row.Resource, wildcard))), dfSto)
        end
        if !isempty(included)
            print_and_log(hydrogen_settings, "i", "Including Hydrogen Storage Resources: $included")
            dfSto = filter(row -> (row.Resource in included), dfSto)
        end
    else
        print_and_log(hydrogen_settings, "i", "Including All Hydrogen Storage Resources")
    end

    ## Add Resource IDs after reading to prevent user errors
    dfSto[!, :R_ID] = 1:size(collect(skipmissing(dfSto[!, 1])), 1)

    ## Add zone index for each resource
    dfSto[!, :ZoneIndex] = indexin(dfSto[!, :Zone], GZones)

    ## Calculate AF for each storage resource
    dfSto[!, :AF] = dfSto[!, :WACC] ./ (1 .- (1 .+ dfSto[!, :WACC]) .^ (-dfSto[!, :Lifetime]))

    ## Calculate fixed OM costs for each storage resource
    dfSto[!, :Fixed_OM_Cost_Ene_per_tonne] =
        round.(
            dfSto[!, :Inv_Cost_Ene_per_tonne] .* dfSto[!, :Fixed_OM_Cost_Ene_Percentage];
            sigdigits = 6,
        )
    dfSto[!, :Fixed_OM_Cost_Dis_per_tonne_per_hr] =
        round.(
            dfSto[!, :Inv_Cost_Dis_per_tonne_per_hr] .* dfSto[!, :Fixed_OM_Cost_Dis_Percentage];
            sigdigits = 6,
        )
    dfSto[!, :Fixed_OM_Cost_Cha_per_tonne_per_hr] =
        round.(
            dfSto[!, :Inv_Cost_Cha_per_tonne_per_hr] .* dfSto[!, :Fixed_OM_Cost_Cha_Percentage];
            sigdigits = 6,
        )
    ## Number of resources
    hydrogen_inputs["S"] = size(collect(skipmissing(dfSto[!, :R_ID])), 1)

    S = hydrogen_inputs["S"]

    ## Store DataFrame of generators/resources input data for use in model
    hydrogen_inputs["dfSto"] = dfSto

    ## Defining sets of generation and storage resources
    ## Set of storage resources with energy and charge (compression) capacity
    hydrogen_inputs["STO_GASEOUS"] = dfSto[dfSto.STOR .== 1, :R_ID]
    ## Set of storage resources with energy, charge (liquefaction) and discharge (vaporizer) capacity
    hydrogen_inputs["STO_LIQUID"] = dfSto[dfSto.STOR .== 2, :R_ID]
    ## Set of storage resources with energy and charge (hydrogenation) capacity and discharge (dehydrogenation) capacity
    hydrogen_inputs["STO_SOLID"] = dfSto[dfSto.STOR .== 3, :R_ID]
    ## Set of all storage resources

    ## Set of all storage resources eligible for new energy capacity
    if StorageExpansion == -1
        hydrogen_inputs["NEW_STO_CAP"] = Int64[]
    elseif StorageExpansion == 0
        hydrogen_inputs["NEW_STO_CAP"] = dfSto[dfSto.New_Build .== 1, :R_ID]
    elseif StorageExpansion == 1
        hydrogen_inputs["NEW_STO_CAP"] = 1:S
    end
    hydrogen_inputs["NEW_STO_CAP"] = intersect(
        hydrogen_inputs["NEW_STO_CAP"],
        union(
            dfSto[dfSto.Max_Ene_Cap_tonne .== -1, :R_ID],
            intersect(
                dfSto[dfSto.Max_Ene_Cap_tonne .!= -1, :R_ID],
                dfSto[dfSto.Max_Ene_Cap_tonne .- dfSto.Existing_Ene_Cap_tonne .> 0, :R_ID],
            ),
        ),
    )
    ## Set of all storage resources eligible for energy capacity retirements
    hydrogen_inputs["RET_STO_CAP"] = intersect(
        dfSto[dfSto.Retirement .== 1, :R_ID],
        dfSto[dfSto.Existing_Ene_Cap_tonne .> 0, :R_ID],
    )
    print_and_log(hydrogen_settings, "i", "Storage Data Successfully Read from $path")

    ## Names of storage resources
    hydrogen_inputs["StoResources"] = collect(skipmissing(dfSto[!, :Resource]))

    ## Set of storage resources
    hydrogen_inputs["StoResourceType"] = unique(dfSto[!, :Resource_Type])

    inputs["HydrogenInputs"] = hydrogen_inputs

    return inputs
end
