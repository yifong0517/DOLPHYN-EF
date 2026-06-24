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
    load_bioenergy_storage(path::AbstractString, bioenergy_settings::Dict, inputs::Dict)

"""
function load_bioenergy_storage(path::AbstractString, bioenergy_settings::Dict, inputs::Dict)

    ## Flags
    StorageExpansion = bioenergy_settings["StorageExpansion"]

    Residuals = bioenergy_settings["Residuals"]

    ## Set indices for internal use
    T = inputs["T"]   # Number of time steps (hours)
    GZones = inputs["Zones"] # Global list of modeled zones

    ## Bioenergy sector inputs dictionary
    bioenergy_inputs = inputs["BioenergyInputs"]
    Zones = bioenergy_inputs["Zones"] # List of modeled zones in bioenergy sector

    ## Storage related inputs
    path = joinpath(path, bioenergy_settings["StoragePath"])
    dfSto = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter resources in modeled zones
    dfSto = filter(row -> (row.Zone in Zones), dfSto)

    ## Filter resources in modeled residual types
    dfSto = filter(row -> (row.Residual in Residuals), dfSto)

    ## Filter resources in modeled types
    if haskey(bioenergy_settings, "StorageSet") && !in("All", bioenergy_settings["StorageSet"])
        ## Exclude some resources from dataframe using "!"
        excluded = filter(x -> startswith(x, "!"), bioenergy_settings["StorageSet"])
        dfSto = filter(row -> !(row.Resource_Type in chop.(excluded, head = 1, tail = 0)), dfSto)
        ## Filter some resources from dataframe after exclusion
        included = setdiff(bioenergy_settings["StorageSet"], excluded)
        if !isempty(included)
            dfSto = filter(row -> (row.Resource_Type in included), dfSto)
        end
    end

    ## Add Resource IDs after reading to prevent user errors
    dfSto[!, :R_ID] = 1:size(collect(skipmissing(dfSto[!, 1])), 1)

    ## Add zone index for each resource
    dfSto[!, :ZoneIndex] = indexin(dfSto[!, :Zone], GZones)

    ## Calculate AF for each storage resource
    dfSto[!, :AF] = dfSto[!, :WACC] ./ (1 .- (1 .+ dfSto[!, :WACC]) .^ (-dfSto[!, :Lifetime]))

    ## Calculate fixed OM costs for each storage resource
    dfSto[!, :Fixed_OM_Cost_Volume_per_tonne] =
        round.(
            dfSto[!, :Inv_Cost_Volume_per_tonne] .* dfSto[!, :Fixed_OM_Cost_Volume_Percentage];
            sigdigits = 6,
        )
    ## Number of resources
    bioenergy_inputs["S"] = size(collect(skipmissing(dfSto[!, :R_ID])), 1)

    S = bioenergy_inputs["S"]

    ## Store DataFrame of generators/resources input data for use in model
    bioenergy_inputs["dfSto"] = dfSto

    ## Defining sets of generation and storage resources
    ## Set of all storage resources eligible for new energy capacity
    if StorageExpansion == -1
        bioenergy_inputs["NEW_STO_CAP"] = Int64[]
    elseif StorageExpansion == 0
        bioenergy_inputs["NEW_STO_CAP"] = dfSto[dfSto.New_Build .== 1, :R_ID]
    elseif StorageExpansion == 1
        bioenergy_inputs["NEW_STO_CAP"] = 1:S
    end
    bioenergy_inputs["NEW_STO_CAP"] = intersect(
        bioenergy_inputs["NEW_STO_CAP"],
        union(
            dfSto[dfSto.Max_Volume_Cap_tonne .== -1, :R_ID],
            intersect(
                dfSto[dfSto.Max_Volume_Cap_tonne .!= -1, :R_ID],
                dfSto[dfSto.Max_Volume_Cap_tonne .- dfSto.Existing_Volume_Cap_tonne .> 0, :R_ID],
            ),
        ),
    )
    ## Set of all storage resources eligible for energy capacity retirements
    bioenergy_inputs["RET_STO_CAP"] = intersect(
        dfSto[dfSto.Retirement .== 1, :R_ID],
        dfSto[dfSto.Existing_Volume_Cap_tonne .> 0, :R_ID],
    )
    print_and_log(bioenergy_settings, "i", "Storage Data Successfully Read from $path")

    inputs["BioenergyInputs"] = bioenergy_inputs

    return inputs
end
