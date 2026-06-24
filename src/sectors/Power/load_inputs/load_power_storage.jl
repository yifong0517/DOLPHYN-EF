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
    load_power_storage(path::AbstractString, power_settings::Dict, inputs::Dict)

"""
function load_power_storage(path::AbstractString, power_settings::Dict, inputs::Dict)

    ## Flags
    StorageExpansion = power_settings["StorageExpansion"]

    ## Set indices for internal use
    T = inputs["T"]   # Number of time steps (hours)
    GZones = inputs["Zones"] # Global list of modeled zones

    ## Power sector inputs dictionary
    power_inputs = inputs["PowerInputs"]
    Zones = power_inputs["Zones"] # List of modeled zones in power sector

    ## Storage related inputs
    path = joinpath(path, power_settings["StoragePath"])
    dfSto = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter resources in modeled zones
    dfSto = filter(row -> (row.Zone in Zones), dfSto)

    ## Filter resources in modeled types
    if haskey(power_settings, "StorageSet") && !in("All", power_settings["StorageSet"])
        ## Exclude some resources from dataframe using "!"
        excluded = filter(x -> startswith(x, "!"), power_settings["StorageSet"])
        ## Filter some resources from dataframe after exclusion
        included = setdiff(power_settings["StorageSet"], excluded)
        excluded = map(x -> chop(x, head = 1, tail = 0), excluded)
        if !isempty(excluded)
            print_and_log(power_settings, "i", "Excluding Power Storage Resources: $excluded")
            dfSto = filter(row -> !(row.Resource_Type in excluded), dfSto)
        end
        if !isempty(included)
            print_and_log(power_settings, "i", "Including Power Storage Resources: $included")
            dfSto = filter(row -> (row.Resource_Type in included), dfSto)
        end
    else
        print_and_log(power_settings, "i", "Including All Power Storage Types")
    end

    ## Filter resources in modeled types
    if haskey(power_settings, "StorageIndex") && !in("All", power_settings["StorageIndex"])
        ## Exclude some resources from dataframe using "!"
        excluded = filter(x -> startswith(x, "!"), power_settings["StorageIndex"])
        ## Filter some resources from dataframe after exclusion
        included = setdiff(power_settings["StorageIndex"], excluded)
        excluded = map(x -> chop(x, head = 1, tail = 0), excluded)
        ## Filter some zones from zone list using wildcard
        wildcard = filter(x -> startswith(x, "*"), power_settings["StorageIndex"])
        included = setdiff(included, wildcard)
        wildcard = chop.(wildcard, head = 1, tail = 0)
        if !isempty(excluded)
            print_and_log(power_settings, "i", "Excluding Power Storage Resources: $excluded")
            dfSto = filter(row -> !(row.Resource in excluded), dfSto)
        end
        if !isempty(wildcard)
            print_and_log(power_settings, "i", "Including Power Storage Resources: *$wildcard")
            dfSto = filter(row -> (any(endswith.(row.Resource, wildcard))), dfSto)
        end
        if !isempty(included)
            print_and_log(power_settings, "i", "Including Power Storage Resources: $included")
            dfSto = filter(row -> (row.Resource in included), dfSto)
        end
    else
        print_and_log(power_settings, "i", "Including All Power Storage Resources")
    end

    ## Add Resource IDs after reading to prevent user errors
    dfSto[!, :R_ID] = 1:size(collect(skipmissing(dfSto[!, 1])), 1)

    ## Add zone index for each resource
    dfSto[!, :ZoneIndex] = indexin(dfSto[!, :Zone], GZones)

    ## Calculate AF for each storage resource
    dfSto[!, :AF] = dfSto[!, :WACC] ./ (1 .- (1 .+ dfSto[!, :WACC]) .^ (-dfSto[!, :Lifetime]))

    ## Calculate fixed OM costs for each storage resource
    dfSto[!, :Fixed_OM_Cost_Ene_per_MWh] =
        round.(
            dfSto[!, :Inv_Cost_Ene_per_MWh] .* dfSto[!, :Fixed_OM_Cost_Ene_Percentage];
            sigdigits = 6,
        )
    dfSto[!, :Fixed_OM_Cost_Dis_per_MW] =
        round.(
            dfSto[!, :Inv_Cost_Dis_per_MW] .* dfSto[!, :Fixed_OM_Cost_Dis_Percentage];
            sigdigits = 6,
        )
    dfSto[!, :Fixed_OM_Cost_Cha_per_MW] =
        round.(
            dfSto[!, :Inv_Cost_Cha_per_MW] .* dfSto[!, :Fixed_OM_Cost_Cha_Percentage];
            sigdigits = 6,
        )
    ## Number of resources
    power_inputs["S"] = size(collect(skipmissing(dfSto[!, :R_ID])), 1)
    S = power_inputs["S"]

    ## Defining sets of generation and storage resources
    ## Set of storage resources with symmetric charge/discharge capacity
    power_inputs["STO_SYMMETRIC"] = dfSto[dfSto.STOR .== 1, :R_ID]
    ## Set of storage resources with asymmetric (separte) charge/discharge capacity components
    power_inputs["STO_ASYMMETRIC"] = dfSto[dfSto.STOR .== 2, :R_ID]

    ## Set of all storage resources eligible for new energy capacity
    if StorageExpansion == -1
        power_inputs["NEW_STO_CAP"] = Int64[]
    elseif StorageExpansion == 0
        power_inputs["NEW_STO_CAP"] = dfSto[dfSto.New_Build .== 1, :R_ID]
    elseif StorageExpansion == 1
        power_inputs["NEW_STO_CAP"] = 1:S
    end
    power_inputs["NEW_STO_CAP"] = intersect(
        power_inputs["NEW_STO_CAP"],
        union(
            dfSto[dfSto.Max_Ene_Cap_MWh .== -1, :R_ID],
            intersect(
                dfSto[dfSto.Max_Ene_Cap_MWh .!= 1, :R_ID],
                dfSto[dfSto.Max_Ene_Cap_MWh .- dfSto.Existing_Ene_Cap_MWh .> 0, :R_ID],
            ),
        ),
    )
    ## Set of all storage resources eligible for energy capacity retirements
    power_inputs["RET_STO_CAP"] = intersect(
        dfSto[dfSto.Retirement .== 1, :R_ID],
        dfSto[dfSto.Existing_Ene_Cap_MWh .> 0, :R_ID],
    )

    ## Set of all storage resources with modeling of aging
    if power_settings["BatteryAging"] == 1
        power_inputs["AGING_STO"] = dfSto[dfSto.Aging .>= 1, :R_ID]
    else
        power_inputs["AGING_STO"] = Int64[]
    end

    ## Store DataFrame of generators/resources input data for use in model
    power_inputs["dfSto"] = dfSto

    ## Names of storage resources
    power_inputs["StoResources"] = collect(skipmissing(dfSto[!, :Resource]))

    ## Set of storage resources
    power_inputs["StoResourceType"] = unique(dfSto[!, :Resource_Type])

    print_and_log(power_settings, "i", "Storage Data Successfully Read from $path")

    inputs["PowerInputs"] = power_inputs

    return inputs
end
