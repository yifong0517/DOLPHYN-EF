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
    fake_power_storage(path::AbstractString, zones::Integer, storages::Dict{String, Int64})

This function fakes power storage data from nowhere.
"""
function fake_power_storage(path::AbstractString, zones::Integer, storages::Dict{String, Int64})

    ## Generate zone list
    Zones = string.(1:zones)

    ## Candidate storage list
    STO_set = ["Storage_bat", "PHS"]

    ## Construct resources list
    storage_number = 0

    for (key, value) in storages
        if key in STO_set
            storage_number += value
        end
    end

    ## Compute the number of all resources
    resources_number = zones * storage_number

    ## Construct resources dataframe
    df_storages = DataFrame(
        Resource = collect(
            "$(key)_$(i)_$(z)" for (key, value) in storages for i in 1:value for z in Zones
        ),
        Resource_Type = collect(
            "$key" for (key, value) in storages for i in 1:value for z in Zones
        ),
        Zone = repeat(Zones, storage_number),
    )

    ## Initialize storages' parameters dataframe
    df_parameters = DataFrame(
        STOR = zeros(Int64, resources_number),
        CES = zeros(Int64, resources_number),
        New_Build = ones(Int64, resources_number),
        Retirement = zeros(Int64, resources_number),
        Existing_Ene_Cap_MWh = zeros(resources_number),
        Existing_Dis_Cap_MW = zeros(resources_number),
        Existing_Cha_Cap_MW = zeros(resources_number),
        Max_Ene_Cap_MWh = repeat([-1], resources_number),
        Max_Dis_Cap_MW = repeat([-1], resources_number),
        Max_Cha_Cap_MW = repeat([-1], resources_number),
        Min_Ene_Cap_MWh = zeros(Int64, resources_number),
        Min_Dis_Cap_MW = zeros(Int64, resources_number),
        Min_Cha_Cap_MW = zeros(Int64, resources_number),
        Inv_Cost_Ene_per_MWh = zeros(resources_number),
        Inv_Cost_Ene_Base_per_MWh = rand(resources_number),
        Compare_Ene_Cap_Size_MWh = ones(Int64, resources_number),
        Ene_Scale = ones(Int64, resources_number),
        Inv_Cost_Dis_per_MW = rand(resources_number) .* 100000,
        Inv_Cost_Dis_Base_per_MW = rand(resources_number),
        Compare_Dis_Cap_Size_MW = ones(Int64, resources_number),
        Dis_Scale = ones(Int64, resources_number),
        Inv_Cost_Cha_per_MW = zeros(resources_number),
        Inv_Cost_Cha_Base_per_MW = zeros(resources_number),
        Compare_Cha_Cap_Size_MW = ones(Int64, resources_number),
        Cha_Scale = ones(Int64, resources_number),
        Lifetime = ceil.(rand(resources_number) .* 20) .+ 4,
        WACC = ones(resources_number) .* 0.07,
        Fixed_OM_Cost_Ene_Percentage = round.(rand(resources_number) ./ 4, sigdigits = 2),
        Fixed_OM_Cost_Dis_Percentage = round.(rand(resources_number) ./ 4, sigdigits = 2),
        Fixed_OM_Cost_Cha_Percentage = zeros(resources_number),
        Var_OM_Cost_Dis_per_MWh = zeros(resources_number),
        Var_OM_Cost_Cha_per_MWh = zeros(resources_number),
        Cap_Size_MW = ones(resources_number),
        Fuel = repeat(["None"], resources_number),
        Heat_Rate_MMBTU_per_MWh = zeros(resources_number),
        Start_Cost_per_MW = zeros(resources_number),
        Start_Fuel_MMBTU_per_MW = zeros(resources_number),
        Up_Time = zeros(Int64, resources_number),
        Down_Time = zeros(Int64, resources_number),
        Ramp_Up_Percentage = ones(resources_number),
        Ramp_Dn_Percentage = ones(resources_number),
        Min_Power = zeros(resources_number),
        PRSV_Max = round.(rand(resources_number), sigdigits = 2),
        PRSV_Cost = round.(100 * rand(resources_number), sigdigits = 2),
        Self_Discharge_Percentage = zeros(resources_number),
        Eff_Charge = zeros(resources_number),
        Eff_Discharge = zeros(resources_number),
        Min_Duration = zeros(resources_number),
        Max_Duration = zeros(resources_number),
    )

    ## Merge parameters dataframe into resources dataframe
    df_storages = hcat(df_storages, df_parameters)

    ## Justify parameters according to resources type
    ## Storage resources
    df_storages[in(STO_set).(df_storages.Resource_Type), :STOR] .= 2
    ## Investment costs
    df_storages[in(STO_set).(df_storages.Resource_Type), :Inv_Cost_Ene_per_MWh] .=
        round.(reduce(vcat, repeat([rand() .* 12000], zones) for _ in 1:storage_number))
    df_storages[!, :Inv_Cost_Ene_Base_per_MWh] = df_storages[!, :Inv_Cost_Ene_per_MWh]

    df_storages[in(STO_set).(df_storages.Resource_Type), :Inv_Cost_Dis_per_MW] .=
        round.(reduce(vcat, repeat([rand() .* 10000], zones) for _ in 1:storage_number))
    df_storages[!, :Inv_Cost_Dis_Base_per_MW] = df_storages[!, :Inv_Cost_Dis_per_MW]

    df_storages[in(STO_set).(df_storages.Resource_Type), :Inv_Cost_Cha_per_MW] .=
        round.(reduce(vcat, repeat([rand() .* 10000], zones) for _ in 1:storage_number))
    df_storages[!, :Inv_Cost_Cha_Base_per_MW] = df_storages[!, :Inv_Cost_Cha_per_MW]

    ## Variable operation and maintenance costs
    df_storages[in(STO_set).(df_storages.Resource_Type), :Var_OM_Cost_Dis_per_MWh] .=
        round.(reduce(vcat, repeat([rand() .* 100], zones) for _ in 1:storage_number))
    df_storages[in(STO_set).(df_storages.Resource_Type), :Var_OM_Cost_Cha_per_MWh] .=
        round.(reduce(vcat, repeat([rand() .* 100], zones) for _ in 1:storage_number))

    ## Efficiency and self-discharge parameters
    df_storages[in(STO_set).(df_storages.Resource_Type), :Self_Discharge_Percentage] .=
        round.(reduce(vcat, repeat([rand() ./ 1000], zones) for _ in 1:storage_number))
    df_storages[in(STO_set).(df_storages.Resource_Type), :Eff_Charge] .=
        round.(reduce(vcat, repeat([rand()], zones) for _ in 1:storage_number); digits = 1)
    df_storages[in(STO_set).(df_storages.Resource_Type), :Eff_Discharge] .=
        round.(reduce(vcat, repeat([rand()], zones) for _ in 1:storage_number); digits = 1)
    df_storages[in(STO_set).(df_storages.Resource_Type), :Min_Duration] .=
        round.(reduce(vcat, repeat([rand()], zones) for _ in 1:storage_number); digits = 1)
    df_storages[in(STO_set).(df_storages.Resource_Type), :Max_Duration] .=
        round.(reduce(vcat, repeat([rand() .* 400], zones) for _ in 1:storage_number))

    CSV.write(joinpath(path, "Storage.csv"), df_storages)
end
