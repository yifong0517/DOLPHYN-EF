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
    fake_power_generators(path::AbstractString, zones::Integer, generators::Dict{String, Int64})

This function fakes imaginary power generators (thermal, renewable, storage, etc.) from nowhere.
"""
function fake_power_generators(
    path::AbstractString,
    zones::Integer,
    generators::Dict{String, Int64},
)

    ## Generate zone list
    Zones = string.(1:zones)

    ## Candidate generator list
    THERM_set = ["Coal", "Coal_CCS", "Nuclear", "CCGT", "CCGT_CCS", "OCGT_F"]
    VRE_set = ["PV", "Wind"]
    CCS_set = ["Coal_CCS", "CCGT_CCS"]
    candidates = union(THERM_set, VRE_set, CCS_set)

    ## Construct resources list
    resources = 0
    therm_number = 0
    VRE_number = 0
    ccs_number = 0
    for (key, value) in generators
        if key in candidates
            resources += value
        end
        if key in THERM_set
            therm_number += generators[key]
        end
        if key in VRE_set
            VRE_number += generators[key]
        end
        if key in CCS_set
            ccs_number += generators[key]
        end
    end

    ## Compute the number of all resources
    resources_number = zones * resources

    ## Construct resources dataframe
    df_generators = DataFrame(
        Resource = collect(
            "$(key)_$(i)_$(z)" for (key, value) in generators for i in 1:value for z in Zones
        ),
        Resource_Type = collect(
            "$key" for (key, value) in generators for i in 1:value for z in Zones
        ),
        Zone = repeat(Zones, resources),
    )

    ## Initialize generators' parameters dataframe
    df_parameters = DataFrame(
        THERM = zeros(Int64, resources_number),
        CCS = zeros(Int64, resources_number),
        CCS_Percentage = zeros(resources_number),
        VRE = zeros(Int64, resources_number),
        HYDRO = zeros(Int64, resources_number),
        MUST_RUN = zeros(Int64, resources_number),
        RPS = zeros(Int64, resources_number),
        CES = zeros(Int64, resources_number),
        New_Build = ones(Int64, resources_number),
        Retirement = zeros(Int64, resources_number),
        Existing_Cap_MW = zeros(resources_number),
        Max_Cap_MW = repeat([-1], resources_number),
        Min_Cap_MW = zeros(Int64, resources_number),
        Inv_Cost_per_MW = rand(resources_number) .* 100000,
        Inv_Cost_Base_per_MW = zeros(resources_number),
        Compare_Cap_Size_MW = ones(resources_number),
        Learning_Rate = ones(Int64, resources_number),
        Lifetime = ceil.(rand(resources_number) .* 30) .+ 6,
        WACC = ones(resources_number) .* 0.07,
        Fixed_OM_Cost_Percentage = round.(rand(resources_number) ./ 4, sigdigits = 2),
        Var_OM_Cost_per_MWh = round.(rand(resources_number) ./ 2, sigdigits = 2),
        Cap_Size_MW = ones(resources_number),
        Fuel = repeat(["None"], resources_number),
        Heat_Rate_MMBTU_per_MWh = zeros(resources_number),
        Electricity = repeat(["None"], resources_number),
        Electricity_Rate_MWh_per_MWh = zeros(resources_number),
        Hydrogen = repeat(["None"], resources_number),
        Hydrogen_Rate_tonne_per_MWh = zeros(resources_number),
        Carbon = repeat(["None"], resources_number),
        Carbon_Rate_tonne_per_MWh = zeros(resources_number),
        Bioenergy = repeat(["None"], resources_number),
        Bioenergy_Rate_MMBTU_per_MWh = zeros(resources_number),
        Start_Cost_per_MW = zeros(resources_number),
        Start_Fuel_MMBTU_per_MW = zeros(resources_number),
        Up_Time = zeros(Int64, resources_number),
        Down_Time = zeros(Int64, resources_number),
        Ramp_Up_Percentage = ones(resources_number),
        Ramp_Dn_Percentage = ones(resources_number),
        Min_Power = zeros(resources_number),
        PRSV_Max = round.(rand(resources_number), sigdigits = 2),
        PRSV_Cost = round.(100 * rand(resources_number), sigdigits = 2),
    )

    ## Merge parameters dataframe into resources dataframe
    df_generators = hcat(df_generators, df_parameters)

    ## Justify parameters according to resources type
    ## Costs related parameters
    df_generators[!, :Inv_Cost_Base_per_MW] = df_generators[!, :Inv_Cost_per_MW]
    df_generators[!, :Compare_Cap_Size_MW] = df_generators[!, :Cap_Size_MW]

    ## Thermal resources
    df_generators[in(THERM_set).(df_generators.Resource_Type), :THERM] .= 1
    df_generators[in(THERM_set).(df_generators.Resource_Type), :Var_OM_Cost_per_MWh] .=
        round.(reduce(vcat, repeat([rand()] .* 10, zones) for _ in 1:therm_number))
    df_generators[in(THERM_set).(df_generators.Resource_Type), :Heat_Rate_MMBTU_per_MWh] .=
        round.(reduce(vcat, repeat([rand()] .* 10, zones) for _ in 1:therm_number))
    df_generators[in(["Nuclear"]).(df_generators.Resource_Type), :Fuel] .= "Uranium"
    df_generators[
        in(["CCGT", "CCGT_CCS", "OCGT_F"]).(df_generators.Resource_Type),
        :Fuel,
    ] .= "Natural Gas"
    df_generators[in(["Coal", "Coal_CCS"]).(df_generators.Resource_Type), :Fuel] .= "Coal"
    df_generators[in(THERM_set).(df_generators.Resource_Type), :Cap_Size_MW] .=
        round.(reduce(vcat, repeat([rand() .* 1000], zones) for _ in 1:therm_number))
    df_generators[in(THERM_set).(df_generators.Resource_Type), :Start_Cost_per_MW] .=
        round.(reduce(vcat, repeat([rand() .* 250], zones) for _ in 1:therm_number))
    df_generators[in(THERM_set).(df_generators.Resource_Type), :Start_Fuel_MMBTU_per_MW] .=
        reduce(vcat, repeat([rand() .* 10], zones) for _ in 1:therm_number)
    df_generators[in(THERM_set).(df_generators.Resource_Type), :Up_Time] .=
        ceil.(reduce(vcat, repeat([rand() .* 24], zones) for _ in 1:therm_number))
    df_generators[in(THERM_set).(df_generators.Resource_Type), :Down_Time] .=
        df_generators[in(THERM_set).(df_generators.Resource_Type), :Up_Time]
    df_generators[in(THERM_set).(df_generators.Resource_Type), :Ramp_Up_Percentage] .=
        reduce(vcat, repeat([rand() ./ 2], zones) for _ in 1:therm_number)
    df_generators[in(THERM_set).(df_generators.Resource_Type), :Ramp_Dn_Percentage] .=
        df_generators[in(THERM_set).(df_generators.Resource_Type), :Ramp_Up_Percentage]
    df_generators[in(THERM_set).(df_generators.Resource_Type), :Min_Power] .=
        reduce(vcat, repeat([rand() ./ 2], zones) for _ in 1:therm_number)

    ## VRE resources
    df_generators[in(VRE_set).(df_generators.Resource_Type), :VRE] .= 1
    df_generators[in(VRE_set).(df_generators.Resource_Type), :RPS] .= 1
    df_generators[in(VRE_set).(df_generators.Resource_Type), :CES] .= 1

    ## CCS resources
    df_generators[in(CCS_set).(df_generators.Resource_Type), :CCS] .= 1
    df_generators[in(CCS_set).(df_generators.Resource_Type), :CCS_Percentage] .=
        reduce(vcat, repeat([rand()], zones) for _ in 1:ccs_number)

    CSV.write(joinpath(path, "Generators.csv"), df_generators)
end
