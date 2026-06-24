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
	load_power_generators(path::AbstractString, power_settings::Dict, inputs::Dict)

Function for reading input parameters related to electricity generators.
"""
function load_power_generators(path::AbstractString, power_settings::Dict, inputs::Dict)

    ## Flags
    GenerationExpansion = power_settings["GenerationExpansion"]
    ScaleEffect = power_settings["ScaleEffect"]
    UCommit = power_settings["UCommit"]

    ## Set indices for internal use
    T = inputs["T"]   # Number of time steps (hours)
    GZones = inputs["Zones"] # Global list of modeled zones

    ## Power sector inputs dictionary
    power_inputs = inputs["PowerInputs"]
    Zones = power_inputs["Zones"] # List of modeled zones in power sector

    ## Generator related inputs
    path = joinpath(path, power_settings["GeneratorPath"])
    dfGen = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter resources in modeled zones
    dfGen = filter(row -> (row.Zone in Zones), dfGen)

    ## Filter resources in modeled type
    if haskey(power_settings, "GeneratorSet") && !in("All", power_settings["GeneratorSet"])
        ## Exclude some resources from dataframe using "!"
        excluded = filter(x -> startswith(x, "!"), power_settings["GeneratorSet"])
        ## Filter some resources from dataframe after exclusion
        included = setdiff(power_settings["GeneratorSet"], excluded)
        excluded = map(x -> chop(x, head = 1, tail = 0), excluded)
        if !isempty(excluded)
            print_and_log(power_settings, "i", "Excluding Power Generator Resources: $excluded")
            dfGen = filter(row -> !(row.Resource_Type in excluded), dfGen)
        end
        if !isempty(included)
            print_and_log(power_settings, "i", "Including Power Generator Resources: $included")
            dfGen = filter(row -> (row.Resource_Type in included), dfGen)
        end
    else
        print_and_log(power_settings, "i", "Including All Power Generator Types")
    end

    ## Filter resources in modeled index
    if haskey(power_settings, "GeneratorIndex") && !in("All", power_settings["GeneratorIndex"])
        ## Exclude some resources from dataframe using "!"
        excluded = filter(x -> startswith(x, "!"), power_settings["GeneratorIndex"])
        ## Filter some resources from dataframe after exclusion
        included = setdiff(power_settings["GeneratorIndex"], excluded)
        excluded = map(x -> chop(x, head = 1, tail = 0), excluded)
        ## Filter some zones from zone list using wildcard
        wildcard = filter(x -> startswith(x, "*"), power_settings["GeneratorIndex"])
        included = setdiff(included, wildcard)
        wildcard = chop.(wildcard, head = 1, tail = 0)
        if !isempty(excluded)
            print_and_log(power_settings, "i", "Excluding Power Generator Resources: $excluded")
            dfGen = filter(row -> !(row.Resource in excluded), dfGen)
        end
        if !isempty(wildcard)
            print_and_log(power_settings, "i", "Including Power Generator Resources: *$wildcard")
            dfGen = filter(row -> (any(endswith.(row.Resource, wildcard))), dfGen)
        end
        if !isempty(included)
            print_and_log(power_settings, "i", "Including Power Generator Resources: $included")
            dfGen = filter(row -> (row.Resource in included), dfGen)
        end
    else
        print_and_log(power_settings, "i", "Including All Power Generator Resources")
    end

    ## Add Resource IDs after reading to prevent user errors
    dfGen[!, :R_ID] = 1:size(collect(skipmissing(dfGen[!, 1])), 1)

    ## Add zone index for each resource
    dfGen[!, :ZoneIndex] = indexin(dfGen[!, :Zone], GZones)

    ## Calculate AF for each generator
    dfGen[!, :AF] = dfGen[!, :WACC] ./ (1 .- (1 .+ dfGen[!, :WACC]) .^ (-dfGen[!, :Lifetime]))

    ## Calculate fixed OM costs for each generator
    dfGen[!, :Fixed_OM_Cost_per_MW] =
        round.(dfGen[!, :Inv_Cost_per_MW] .* dfGen[!, :Fixed_OM_Cost_Percentage]; sigdigits = 6)

    ## Scale effect from learning by doing (LBD)
    if ScaleEffect == 1
        dfGen[!, :Scale_Effect] = log2.(1 .- dfGen[!, :Learning_Rate])
    end

    ## Number of resources
    power_inputs["G"] = size(collect(skipmissing(dfGen[!, :R_ID])), 1)

    ## Set indices for internal use
    G = power_inputs["G"]

    ## Set of controllable variable renewable resources
    power_inputs["VRE"] = dfGen[dfGen.VRE .== 1, :R_ID]

    ## Set of dispatchable hydro electric resources
    power_inputs["HYDRO"] = dfGen[dfGen.HYDRO .== 1, :R_ID]

    ## Set of must run (non-dispatchable) resources
    power_inputs["MUST_RUN"] = dfGen[dfGen.MUST_RUN .== 1, :R_ID]

    ## Set of renewable resources
    power_inputs["Renewable"] =
        union(power_inputs["VRE"], power_inputs["HYDRO"], power_inputs["MUST_RUN"])

    ## Set of coal fired generators
    power_inputs["CFG"] = sort(
        union(
            reduce(
                vcat,
                dfGen[occursin.(candidate, dfGen.Fuel), :R_ID] for
                candidate in power_settings["CFG"]
            ),
        ),
    )

    ## Set of gas fired generators
    power_inputs["GFG"] = sort(
        union(
            reduce(
                vcat,
                dfGen[occursin.(candidate, dfGen.Fuel), :R_ID] for
                candidate in power_settings["GFG"]
            ),
        ),
    )

    ## Set of oil fired generators
    power_inputs["OFG"] = sort(
        union(
            reduce(
                vcat,
                dfGen[occursin.(candidate, dfGen.Fuel), :R_ID] for
                candidate in power_settings["OFG"]
            ),
        ),
    )

    ## Set of nuclear generators
    power_inputs["NFG"] = sort(
        union(
            reduce(
                vcat,
                dfGen[occursin.(candidate, dfGen.Fuel), :R_ID] for
                candidate in power_settings["NFG"]
            ),
        ),
    )

    ## Set of hydrogen fired generators
    power_inputs["HFG"] = sort(
        union(
            reduce(
                vcat,
                dfGen[occursin.(candidate, dfGen.Fuel), :R_ID] for
                candidate in power_settings["HFG"]
            ),
        ),
    )

    ## Set of biomass fired generators
    power_inputs["BFG"] = sort(
        union(
            reduce(
                vcat,
                dfGen[occursin.(candidate, dfGen.Fuel), :R_ID] for
                candidate in power_settings["BFG"]
            ),
        ),
    )

    ## Set of generators with carbon capture capability
    power_inputs["CCS"] = dfGen[dfGen.CCS .== 1, :R_ID]

    ## Set of thermal generator resources
    if UCommit >= 1
        ## Set of thermal resources eligible for unit committment
        power_inputs["THERM_COMMIT"] = dfGen[dfGen.THERM .== 1, :R_ID]
        ## Set of thermal resources not eligible for unit committment
        power_inputs["THERM_NO_COMMIT"] = dfGen[dfGen.THERM .== 2, :R_ID]
    else
        ## When UCommit == 0, no thermal resources are eligible for unit committment
        power_inputs["THERM_COMMIT"] = Int64[]
        power_inputs["THERM_NO_COMMIT"] =
            sort(union(dfGen[dfGen.THERM .== 1, :R_ID], dfGen[dfGen.THERM .== 2, :R_ID]))
    end
    power_inputs["THERM"] =
        sort(union(power_inputs["THERM_COMMIT"], power_inputs["THERM_NO_COMMIT"]))

    ## For now, the only resources eligible for UC are themal resources
    power_inputs["COMMIT"] = power_inputs["THERM_COMMIT"]
    power_inputs["NO_COMMIT"] = power_inputs["THERM_NO_COMMIT"]

    ## Set of all resources eligible for new capacity
    if GenerationExpansion == -1
        power_inputs["NEW_GEN_CAP"] = Int64[]
    elseif GenerationExpansion == 0
        power_inputs["NEW_GEN_CAP"] = dfGen[dfGen.New_Build .== 1, :R_ID]
    elseif GenerationExpansion == 1
        power_inputs["NEW_GEN_CAP"] = 1:G
    end
    power_inputs["NEW_GEN_CAP"] = intersect(
        power_inputs["NEW_GEN_CAP"],
        union(
            dfGen[dfGen.Max_Cap_MW .== -1, :R_ID],
            intersect(
                dfGen[dfGen.Max_Cap_MW .!= -1, :R_ID],
                dfGen[dfGen.Max_Cap_MW .- dfGen.Existing_Cap_MW .> 0, :R_ID],
            ),
        ),
    )
    ## Set of all resources eligible for capacity retirements
    power_inputs["RET_GEN_CAP"] =
        intersect(dfGen[dfGen.Retirement .== 1, :R_ID], dfGen[dfGen.Existing_Cap_MW .> 0, :R_ID])

    if power_settings["ModelFuels"] == 1
        ## Carbon emission rates of feedstock fuels
        Fuels_Index = inputs["Fuels_Index"]
        fuels_CO2 = inputs["fuels_CO2"]

        ## Fuel consumed on start-up (million BTUs per MW per start) if unit commitment is modelled
        if UCommit >= 1
            dfGen = transform(
                dfGen,
                [:R_ID, :Fuel, :Start_Fuel_MMBTU_per_MW, :Cap_Size_MW] =>
                    ByRow(
                        (r, f, s, cap) -> (
                            (r in power_inputs["COMMIT"] && f in Fuels_Index) ?
                            fuels_CO2[f] * s * cap : 0.0
                        ),
                    ) => :CO2_tonne_per_Start,
            )
        end

        ## Heat rate of all resources (million BTUs/MWh) - quadric expression
        if !in(names(dfGen), "Heat_Rate_MMBTU_per_Square_MWh")
            dfGen[!, :Heat_Rate_MMBTU_per_Square_MWh] = zeros(Float64, G)
            dfGen[!, :Heat_Rate_MMBTU_No_Load] = zeros(Float64, G)
        end
        dfGen = transform(
            dfGen,
            [
                :Heat_Rate_MMBTU_per_Square_MWh,
                :Heat_Rate_MMBTU_per_MWh,
                :Heat_Rate_MMBTU_No_Load,
                :Fuel,
            ] =>
                ByRow(
                    (a, b, c, f) -> (
                        CO2_tonne_per_Square_MWh = f in Fuels_Index ? fuels_CO2[f] * a : 0.0,
                        CO2_tonne_per_MWh = f in Fuels_Index ? fuels_CO2[f] * b : 0.0,
                        CO2_tonne_No_Load = f in Fuels_Index ? fuels_CO2[f] * c : 0.0,
                    ),
                ) => AsTable,
        )
    else
        dfGen[!, :CO2_tonne_per_Start] = zeros(Float64, G)
        dfGen[!, :CO2_tonne_per_Square_MWh] = zeros(Float64, G)
        dfGen[!, :CO2_tonne_per_MWh] = zeros(Float64, G)
        dfGen[!, :CO2_tonne_No_Load] = zeros(Float64, G)
    end

    ## Quadric emission expression flag
    if any(dfGen[!, :CO2_tonne_per_Square_MWh] .> 0)
        power_settings["QuadricEmission"] = 1
    else
        power_settings["QuadricEmission"] = 0
    end

    ## Generate sub zone mapping to make sure zone information is contained
    if power_settings["SubZone"] == 1
        dfGen, SubZones = subzone(dfGen, Symbol(power_settings["SubZoneKey"]))
        power_inputs["SubZones"] = SubZones
    end

    ## Store DataFrame of generators/resources input data for use in model
    power_inputs["dfGen"] = dfGen

    ## Names of resources
    power_inputs["GenResources"] = collect(skipmissing(dfGen[!, :Resource]))

    ## Set of resources
    power_inputs["GenResourceType"] = unique(dfGen[!, :Resource_Type])

    print_and_log(power_settings, "i", "Generators Data Successfully Read from $path")

    inputs["PowerInputs"] = power_inputs

    return inputs
end
