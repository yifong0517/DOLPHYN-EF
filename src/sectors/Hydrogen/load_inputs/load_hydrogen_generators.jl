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
	load_hydrogen_generators(path::AbstractString, hydrogen_settings::Dict, inputs::Dict)

Function for reading input parameters related to electricity generators.
"""
function load_hydrogen_generators(path::AbstractString, hydrogen_settings::Dict, inputs::Dict)

    ## Flags
    GenerationExpansion = hydrogen_settings["GenerationExpansion"]
    ScaleEffect = hydrogen_settings["ScaleEffect"]
    GenCommit = hydrogen_settings["GenCommit"]

    ## Set indices for internal use
    T = inputs["T"]   # Number of time steps (hours)
    GZones = inputs["Zones"] # Global list of modeled zones

    ## Hydrogen sector inputs dictionary
    hydrogen_inputs = inputs["HydrogenInputs"]
    Zones = hydrogen_inputs["Zones"] # List of modeled zones in hydrogen sector

    ## Generator related inputs
    path = joinpath(path, hydrogen_settings["GeneratorPath"])
    dfGen = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter resources in modeled zones
    dfGen = filter(row -> (row.Zone in Zones), dfGen)

    ## Filter resources in modeled types
    if haskey(hydrogen_settings, "GeneratorSet") && !in("All", hydrogen_settings["GeneratorSet"])
        ## Exclude some resources from dataframe using "!"
        excluded = filter(x -> startswith(x, "!"), hydrogen_settings["GeneratorSet"])
        ## Filter some resources from dataframe after exclusion
        included = setdiff(hydrogen_settings["GeneratorSet"], excluded)
        excluded = map(x -> chop(x, head = 1, tail = 0), excluded)
        if !isempty(excluded)
            print_and_log(
                hydrogen_settings,
                "i",
                "Excluding Hydrogen Generator Resources: $excluded",
            )
            dfGen = filter(row -> !(row.Resource_Type in excluded), dfGen)
        end
        if !isempty(included)
            print_and_log(
                hydrogen_settings,
                "i",
                "Including Hydrogen Generator Resources: $included",
            )
            dfGen = filter(row -> (row.Resource_Type in included), dfGen)
        end
    else
        print_and_log(hydrogen_settings, "i", "Including All Hydrogen Generator Types")
    end

    ## Filter resources in modeled index
    if haskey(hydrogen_settings, "GeneratorIndex") &&
       !in("All", hydrogen_settings["GeneratorIndex"])
        ## Exclude some resources from dataframe using "!"
        excluded = filter(x -> startswith(x, "!"), hydrogen_settings["GeneratorIndex"])
        ## Filter some resources from dataframe after exclusion
        included = setdiff(hydrogen_settings["GeneratorIndex"], excluded)
        excluded = map(x -> chop(x, head = 1, tail = 0), excluded)
        ## Filter some zones from zone list using wildcard
        wildcard = filter(x -> startswith(x, "*"), hydrogen_settings["GeneratorIndex"])
        included = setdiff(included, wildcard)
        wildcard = chop.(wildcard, head = 1, tail = 0)
        if !isempty(excluded)
            print_and_log(
                hydrogen_settings,
                "i",
                "Excluding Hydrogen Generator Resources: $excluded",
            )
            dfGen = filter(row -> !(row.Resource in excluded), dfGen)
        end
        if !isempty(wildcard)
            print_and_log(power_settings, "i", "Including Hydrogen Generator Resources: *$wildcard")
            dfGen = filter(row -> (any(endswith.(row.Resource, wildcard))), dfGen)
        end
        if !isempty(included)
            print_and_log(
                hydrogen_settings,
                "i",
                "Including Hydrogen Generator Resources: $included",
            )
            dfGen = filter(row -> (row.Resource in included), dfGen)
        end
    else
        print_and_log(hydrogen_settings, "i", "Including All Hydrogen Generator Resources")
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
    hydrogen_inputs["G"] = size(collect(skipmissing(dfGen[!, :R_ID])), 1)

    ## Set indices for internal use
    G = hydrogen_inputs["G"]

    ## Set of hydrogen generators as natural gas processing plants
    hydrogen_inputs["SMR"] = sort(
        union(
            reduce(
                vcat,
                dfGen[occursin.(candidate, dfGen.Fuel), :R_ID] for
                candidate in hydrogen_settings["SMR"]
            ),
        ),
    )

    ## Set of hydrogen generators as coal gasification plants
    hydrogen_inputs["CGF"] = sort(
        union(
            reduce(
                vcat,
                dfGen[occursin.(candidate, dfGen.Fuel), :R_ID] for
                candidate in hydrogen_settings["CGF"]
            ),
        ),
    )

    ## Set of hydrogen generators as biomass gasification plants
    hydrogen_inputs["BMG"] = sort(
        union(
            reduce(
                vcat,
                dfGen[occursin.(candidate, dfGen.Fuel), :R_ID] for
                candidate in hydrogen_settings["BMG"]
            ),
        ),
    )

    ## Set of hydrogen generators with carbon capture capability
    hydrogen_inputs["CCS"] = dfGen[dfGen.CCS .== 1, :R_ID]

    if GenCommit >= 1
        hydrogen_inputs["THERM_COMMIT"] = dfGen[dfGen.THERM .== 1, :R_ID]
        hydrogen_inputs["THERM_NO_COMMIT"] = dfGen[dfGen.THERM .== 2, :R_ID]
        ## Set of hydrogen generators as electrolysers
        hydrogen_inputs["ELE_COMMIT"] = dfGen[dfGen.ELE .== 1, :R_ID]
        hydrogen_inputs["ELE_NO_COMMIT"] = dfGen[dfGen.ELE .== 2, :R_ID]
    else
        hydrogen_inputs["THERM_COMMIT"] = Int64[]
        hydrogen_inputs["THERM_NO_COMMIT"] =
            sort(union(dfGen[dfGen.THERM .== 1, :R_ID], dfGen[dfGen.THERM .== 2, :R_ID]))
        ## Set of hydrogen generators as electrolysers
        hydrogen_inputs["ELE_COMMIT"] = Int64[]
        hydrogen_inputs["ELE_NO_COMMIT"] =
            sort(union(dfGen[dfGen.ELE .== 1, :R_ID], dfGen[dfGen.ELE .== 2, :R_ID]))
    end
    hydrogen_inputs["THERM"] =
        sort(union(hydrogen_inputs["THERM_COMMIT"], hydrogen_inputs["THERM_NO_COMMIT"]))
    hydrogen_inputs["ELE"] =
        sort(union(hydrogen_inputs["ELE_COMMIT"], hydrogen_inputs["ELE_NO_COMMIT"]))
    hydrogen_inputs["GEN"] = sort(union(hydrogen_inputs["THERM"], hydrogen_inputs["ELE"]))

    ## Resources eligible for UC including electrolysers and thermal generators
    hydrogen_inputs["COMMIT"] =
        sort(union(hydrogen_inputs["THERM_COMMIT"], hydrogen_inputs["ELE_COMMIT"]))
    hydrogen_inputs["NO_COMMIT"] =
        sort(union(hydrogen_inputs["THERM_NO_COMMIT"], hydrogen_inputs["ELE_NO_COMMIT"]))

    ## Set of all resources eligible for new capacity
    if GenerationExpansion == -1
        hydrogen_inputs["NEW_GEN_CAP"] = Int64[]
    elseif GenerationExpansion == 0
        hydrogen_inputs["NEW_GEN_CAP"] = dfGen[dfGen.New_Build .== 1, :R_ID]
    elseif GenerationExpansion == 1
        hydrogen_inputs["NEW_GEN_CAP"] = 1:G
    end
    hydrogen_inputs["NEW_GEN_CAP"] = intersect(
        hydrogen_inputs["NEW_GEN_CAP"],
        union(
            dfGen[dfGen.Max_Cap_tonne_per_hr .== -1, :R_ID],
            intersect(
                dfGen[dfGen.Max_Cap_tonne_per_hr .!= -1, :R_ID],
                dfGen[dfGen.Max_Cap_tonne_per_hr .- dfGen.Existing_Cap_tonne_per_hr .> 0, :R_ID],
            ),
        ),
    )
    ## Set of all resources eligible for capacity retirements
    hydrogen_inputs["RET_GEN_CAP"] = intersect(
        dfGen[dfGen.Retirement .== 1, :R_ID],
        dfGen[dfGen.Existing_Cap_tonne_per_hr .> 0, :R_ID],
    )

    if hydrogen_settings["ModelFuels"] == 1
        ## Carbon emission rates of feedstock fuels
        Fuels_Index = inputs["Fuels_Index"]
        fuels_CO2 = inputs["fuels_CO2"]

        ## Fuel consumed on start-up (million BTUs per tonne/hr per start) if unit commitment is modelled
        if GenCommit >= 1
            dfGen = transform(
                dfGen,
                [:R_ID, :Fuel, :Start_Fuel_MMBTU_per_tonne_per_hr, :Cap_Size_tonne_per_hr] =>
                    ByRow(
                        (r, f, s, cap) -> (
                            (r in hydrogen_inputs["COMMIT"] && f in Fuels_Index) ?
                            fuels_CO2[f] * s * cap : 0.0
                        ),
                    ) => :CO2_tonne_per_Start,
            )
        end

        ## Heat rate of all resources (million BTUs/tonne)
        dfGen = transform(
            dfGen,
            [:Heat_Rate_MMBTU_per_tonne, :Fuel] =>
                ByRow((heat_rate, f) -> f in Fuels_Index ? fuels_CO2[f] * heat_rate : 0.0) =>
                    :CO2_tonne_per_tonne,
        )
    else
        dfGen[!, :CO2_tonne_per_Start] = zeros(Float64, G)
        dfGen[!, :CO2_tonne_per_tonne] = zeros(Float64, G)
    end

    ## Generate sub zone mapping to make sure zone information is contained
    if hydrogen_settings["SubZone"] == 1
        dfGen, SubZones = subzone(dfGen, Symbol(hydrogen_settings["SubZoneKey"]))
        hydrogen_inputs["SubZones"] = SubZones
    end

    ## Store DataFrame of generators/resources input data for use in model
    hydrogen_inputs["dfGen"] = dfGen

    ## Names of resources
    hydrogen_inputs["GenResources"] = collect(skipmissing(dfGen[!, :Resource]))

    ## Set of resources
    hydrogen_inputs["GenResourceType"] = unique(dfGen[!, :Resource_Type])

    print_and_log(hydrogen_settings, "i", "Generators Data Successfully Read from $path")

    inputs["HydrogenInputs"] = hydrogen_inputs

    return inputs
end
