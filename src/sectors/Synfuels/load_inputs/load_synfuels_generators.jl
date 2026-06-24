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
	load_synfuels_generators(path::AbstractString, synfuels_settings::Dict, inputs::Dict)

Function for reading input parameters related to electricity generators.
"""
function load_synfuels_generators(path::AbstractString, synfuels_settings::Dict, inputs::Dict)

    ## Flags
    GenerationExpansion = synfuels_settings["GenerationExpansion"]
    ScaleEffect = synfuels_settings["ScaleEffect"]
    GenCommit = synfuels_settings["GenCommit"]

    ## Set indices for internal use
    T = inputs["T"]   # Number of time steps (hours)
    GZones = inputs["Zones"] # Global list of modeled zones

    ## Synfuels sector inputs dictionary
    synfuels_inputs = inputs["SynfuelsInputs"]
    Zones = synfuels_inputs["Zones"] # List of modeled zones in synfuels sector

    ## Generator related inputs
    path = joinpath(path, synfuels_settings["GeneratorPath"])
    dfGen = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter resources in modeled zones
    dfGen = filter(row -> (row.Zone in Zones), dfGen)

    ## Filter resources in modeled types
    if haskey(synfuels_settings, "GeneratorSet") && !in("All", synfuels_settings["GeneratorSet"])
        ## Exclude some resources from dataframe using "!"
        excluded = filter(x -> startswith(x, "!"), synfuels_settings["GeneratorSet"])
        ## Filter some resources from dataframe after exclusion
        included = setdiff(synfuels_settings["GeneratorSet"], excluded)
        excluded = map(x -> chop(x, head = 1, tail = 0), excluded)
        if !isempty(excluded)
            print_and_log(
                synfuels_settings,
                "i",
                "Excluding Synfuels Generator Resources: $excluded",
            )
            dfGen = filter(row -> !(row.Resource_Type in excluded), dfGen)
        end
        if !isempty(included)
            print_and_log(
                synfuels_settings,
                "i",
                "Including Synfuels Generator Resources: $included",
            )
            dfGen = filter(row -> (row.Resource_Type in included), dfGen)
        end
    else
        print_and_log(synfuels_settings, "i", "Including All Synfuels Generator Types")
    end

    ## Filter resources in modeled index
    if haskey(synfuels_settings, "GeneratorIndex") &&
       !in("All", synfuels_settings["GeneratorIndex"])
        ## Exclude some resources from dataframe using "!"
        excluded = filter(x -> startswith(x, "!"), synfuels_settings["GeneratorIndex"])
        ## Filter some resources from dataframe after exclusion
        included = setdiff(synfuels_settings["GeneratorIndex"], excluded)
        excluded = map(x -> chop(x, head = 1, tail = 0), excluded)
        ## Filter some zones from zone list using wildcard
        wildcard = filter(x -> startswith(x, "*"), synfuels_settings["GeneratorIndex"])
        included = setdiff(included, wildcard)
        wildcard = chop.(wildcard, head = 1, tail = 0)
        if !isempty(excluded)
            print_and_log(
                synfuels_settings,
                "i",
                "Excluding Synfuels Generator Resources: $excluded",
            )
            dfGen = filter(row -> !(row.Resource in excluded), dfGen)
        end
        if !isempty(wildcard)
            print_and_log(
                synfuels_settings,
                "i",
                "Including Synfuels Generator Resources: *$wildcard",
            )
            dfGen = filter(row -> (any(endswith.(row.Resource, wildcard))), dfGen)
        end
        if !isempty(included)
            print_and_log(
                synfuels_settings,
                "i",
                "Including Synfuels Generator Resources: $included",
            )
            dfGen = filter(row -> (row.Resource in included), dfGen)
        end
    else
        print_and_log(synfuels_settings, "i", "Including All Synfuels Generator Resources")
    end

    ## Add Resource IDs after reading to prevent user errors
    dfGen[!, :R_ID] = 1:size(collect(skipmissing(dfGen[!, 1])), 1)

    ## Add zone index for each resource
    dfGen[!, :ZoneIndex] = indexin(dfGen[!, :Zone], GZones)

    ## Calculate AF for each generator
    dfGen[!, :AF] = dfGen[!, :WACC] ./ (1 .- (1 .+ dfGen[!, :WACC]) .^ (-dfGen[!, :Lifetime]))

    ## Calculate fixed OM costs for each generator
    dfGen[!, :Fixed_OM_Cost_per_tonne_per_hr] =
        round.(
            dfGen[!, :Inv_Cost_per_tonne_per_hr] .* dfGen[!, :Fixed_OM_Cost_Percentage];
            sigdigits = 6,
        )

    ## Scale effect from learning by doing (LBD)
    if ScaleEffect == 1
        dfGen[!, :Scale_Effect] = log2.(1 .- dfGen[!, :Learning_Rate])
    end

    ## Number of resources
    synfuels_inputs["G"] = size(collect(skipmissing(dfGen[!, :R_ID])), 1)

    ## Set indices for internal use
    G = synfuels_inputs["G"]

    ## Set of synfuels generators with coal as feedstock
    synfuels_inputs["CLG"] = sort(
        union(
            reduce(
                vcat,
                dfGen[occursin.(candidate, dfGen.Fuel), :R_ID] for
                candidate in synfuels_settings["CLG"]
            ),
        ),
    )

    ## Set of synfuels generators with natural gas as feedstock
    synfuels_inputs["GLG"] = sort(
        union(
            reduce(
                vcat,
                dfGen[occursin.(candidate, dfGen.Fuel), :R_ID] for
                candidate in synfuels_settings["GLG"]
            ),
        ),
    )

    ## Set of synfuels generators with biomass liquefaction as feedstock
    synfuels_inputs["BLG"] = sort(
        union(
            reduce(
                vcat,
                dfGen[occursin.(candidate, dfGen.Fuel), :R_ID] for
                candidate in synfuels_settings["BLG"]
            ),
        ),
    )

    ## Set of synfuels generators with carbon capture capability
    synfuels_inputs["CCS"] = dfGen[dfGen.CCS .== 1, :R_ID]

    if GenCommit >= 1
        synfuels_inputs["THERM_COMMIT"] = dfGen[dfGen.THERM .== 1, :R_ID]
        synfuels_inputs["THERM_NO_COMMIT"] = dfGen[dfGen.THERM .== 2, :R_ID]
        ## Set of synfuels generators as electrolysers as hydrogen source
        synfuels_inputs["ELE_COMMIT"] = dfGen[dfGen.ELE .== 1, :R_ID]
        synfuels_inputs["ELE_NO_COMMIT"] = dfGen[dfGen.ELE .== 2, :R_ID]
    else
        synfuels_inputs["THERM_COMMIT"] = Int64[]
        synfuels_inputs["THERM_NO_COMMIT"] =
            sort(union(dfGen[dfGen.THERM .== 1, :R_ID], dfGen[dfGen.THERM .== 2, :R_ID]))
        ## Set of synfuels generators as electrolysers as hydrogen source
        synfuels_inputs["ELE_COMMIT"] = Int64[]
        synfuels_inputs["ELE_NO_COMMIT"] =
            sort(union(dfGen[dfGen.ELE .== 1, :R_ID], dfGen[dfGen.ELE .== 2, :R_ID]))
    end
    synfuels_inputs["THERM"] =
        sort(union(synfuels_inputs["THERM_COMMIT"], synfuels_inputs["THERM_NO_COMMIT"]))
    synfuels_inputs["ELE"] =
        sort(union(synfuels_inputs["ELE_COMMIT"], synfuels_inputs["ELE_NO_COMMIT"]))

    ## For now, the only resources eligible for UC are themal resources
    synfuels_inputs["COMMIT"] =
        sort(union(synfuels_inputs["THERM_COMMIT"], synfuels_inputs["ELE_COMMIT"]))
    synfuels_inputs["NO_COMMIT"] =
        sort(union(synfuels_inputs["THERM_NO_COMMIT"], synfuels_inputs["ELE_NO_COMMIT"]))

    ## Set of all resources eligible for new capacity
    if GenerationExpansion == -1
        synfuels_inputs["NEW_GEN_CAP"] = Int64[]
    elseif GenerationExpansion == 0
        synfuels_inputs["NEW_GEN_CAP"] = dfGen[dfGen.New_Build .== 1, :R_ID]
    elseif GenerationExpansion == 1
        synfuels_inputs["NEW_GEN_CAP"] = 1:G
    end
    synfuels_inputs["NEW_GEN_CAP"] = intersect(
        synfuels_inputs["NEW_GEN_CAP"],
        union(
            dfGen[dfGen.Max_Cap_tonne_per_hr .== -1, :R_ID],
            intersect(
                dfGen[dfGen.Max_Cap_tonne_per_hr .!= -1, :R_ID],
                dfGen[dfGen.Max_Cap_tonne_per_hr .- dfGen.Existing_Cap_tonne_per_hr .> 0, :R_ID],
            ),
        ),
    )
    ## Set of all resources eligible for capacity retirements
    synfuels_inputs["RET_GEN_CAP"] = intersect(
        dfGen[dfGen.Retirement .== 1, :R_ID],
        dfGen[dfGen.Existing_Cap_tonne_per_hr .> 0, :R_ID],
    )

    ## Fuel consumed on start-up (million BTUs per tonne/hr per start) if unit commitment is modelled
    if synfuels_settings["ModelFuels"] == 1
        ## Carbon emission rates of feedstock fuels
        Fuels_Index = inputs["Fuels_Index"]
        fuels_CO2 = inputs["fuels_CO2"]
        if GenCommit >= 1
            dfGen = transform(
                dfGen,
                [:R_ID, :Fuel, :Start_Fuel_MMBTU_per_tonne_per_hr, :Cap_Size_tonne_per_hr] =>
                    ByRow(
                        (r, f, s, cap) -> (
                            (r in synfuels_inputs["COMMIT"] && f in Fuels_Index) ?
                            fuels_CO2[f] * s * cap : 0.0
                        ),
                    ) => :CO2_tonne_per_Start,
            )
        end

        ## Heat rate of all resources (million BTUs/tonne)
        dfGen = transform(
            dfGen,
            [
                :Heat_Rate_MMBTU_per_tonne,
                :Product_Emission_Uptake_tonne_per_tonne,
                :Energy_Fuel_Emission_tonne_per_tonne,
                :Fuel,
            ] =>
                ByRow(
                    (heat_rate, emission_uptake, energy_emission, f) ->
                        f in Fuels_Index ?
                        fuels_CO2[f] * heat_rate - emission_uptake + energy_emission : 0.0,
                ) => :CO2_tonne_per_tonne,
        )
    else
        dfGen[!, :CO2_tonne_per_Start] = zeros(Float64, G)
        dfGen[!, :CO2_tonne_per_tonne] = zeros(Float64, G)
    end

    ## Generate sub zone mapping to make sure zone information is contained
    if synfuels_settings["SubZone"] == 1
        dfGen, SubZones = subzone(dfGen, Symbol(synfuels_settings["SubZoneKey"]))
        synfuels_inputs["SubZones"] = SubZones
    end

    ## Store DataFrame of generators/resources input data for use in model
    synfuels_inputs["dfGen"] = dfGen

    ## Names of resources
    synfuels_inputs["GenResources"] = collect(skipmissing(dfGen[!, :Resource]))

    ## Set of resources
    synfuels_inputs["GenResourceType"] = unique(dfGen[!, :Resource_Type])

    print_and_log(synfuels_settings, "i", "Generators Data Successfully Read from $path")

    inputs["SynfuelsInputs"] = synfuels_inputs

    return inputs
end
