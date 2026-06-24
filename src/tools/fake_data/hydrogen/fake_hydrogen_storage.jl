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
    fake_hydrogen_storage(path::AbstractString, zones::Integer, storages::Dict{String, Int64})

This function fakes hydrogen storage data from nowhere.
"""
function fake_hydrogen_storage(path::AbstractString, zones::Integer, storages::Dict{String, Int64})

    ## Generate zone list
    Zones = string.(1:zones)

    ## Candidate storage list
    STO_set = ["Above_ground_storage", "Underground_storage"]

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
        New_Build = ones(Int64, resources_number),
        Retirement = zeros(Int64, resources_number),
        Existing_Ene_Cap_tonne = zeros(resources_number),
        Existing_Dis_Cap_tonne_per_hr = zeros(resources_number),
        Existing_Cha_Cap_tonne_per_hr = zeros(resources_number),
        Max_Ene_Cap_MWh = repeat([-1], resources_number),
        Max_Dis_Cap_MW = repeat([-1], resources_number),
        Max_Cha_Cap_MW = repeat([-1], resources_number),
        Min_Ene_Cap_MWh = zeros(Int64, resources_number),
        Min_Dis_Cap_MW = zeros(Int64, resources_number),
        Min_Cha_Cap_MW = zeros(Int64, resources_number),
        Inv_Cost_Ene_per_tonne = zeros(resources_number),
        Inv_Cost_Ene_Base_per_tonne = zeros(resources_number),
        Compare_Ene_Cap_Size_tonne = zeros(Int64, resources_number),
        Ene_Scale = ones(Int64, resources_number),
        Inv_Cost_Dis_per_tonne_per_hr = zeros(resources_number),
        Inv_Cost_Dis_Base_per_tonne_per_hr = zeros(resources_number),
        Compare_Dis_Cap_Size_tonne_per_hr = zeros(Int64, resources_number),
        Dis_Scale = ones(Int64, resources_number),
        Inv_Cost_Cha_per_tonne_per_hr = rand(resources_number) .* 100000,
        Inv_Cost_Cha_Base_per_tonne_per_hr = zeros(resources_number),
        Compare_Cha_Cap_Size_tonne_per_hr = zeros(Int64, resources_number),
        Cha_Scale = ones(Int64, resources_number),
        Lifetime = ceil.(rand(resources_number) .* 20) .+ 4,
        WACC = ones(resources_number) .* 0.07,
        Fixed_OM_Cost_Ene_Percentage = round.(rand(resources_number) ./ 4, sigdigits = 2),
        Fixed_OM_Cost_Dis_Percentage = round.(rand(resources_number) ./ 4, sigdigits = 2),
        Fixed_OM_Cost_Cha_Percentage = round.(rand(resources_number) ./ 4, sigdigits = 2),
        Var_OM_Cost_Dis_per_tonne = zeros(resources_number),
        Var_OM_Cost_Cha_per_tonne = zeros(resources_number),
        Fuel = repeat(["None"], resources_number),
        Stor_Charge_MMBtu_per_tonne = zeros(resources_number),
        Electricity = repeat(["None"], resources_number),
        Stor_Charge_MWh_per_tonne = zeros(resources_number),
        Up_Time = zeros(Int64, resources_number),
        Down_Time = zeros(Int64, resources_number),
        Ramp_Up_Percentage = ones(resources_number),
        Ramp_Dn_Percentage = ones(resources_number),
        Storage_Min_Level = zeros(resources_number),
        Storage_Max_Level = ones(resources_number),
        Self_Discharge_Percentage = zeros(resources_number),
        Eff_Charge = zeros(resources_number),
        Eff_Discharge = zeros(resources_number),
    )

    ## Merge parameters dataframe into resources dataframe
    df_storages = hcat(df_storages, df_parameters)

    ## Justify parameters according to resources type
    ## Storage resources
    df_storages[in(STO_set).(df_storages.Resource_Type), :STOR] .= 2
    df_storages[in(STO_set).(df_storages.Resource_Type), :Inv_Cost_Ene_per_tonne] .=
        round.(reduce(vcat, repeat([rand() .* 12000], zones) for _ in 1:storage_number))
    df_storages[!, :Inv_Cost_Ene_Base_per_tonne] = df_storages[!, :Inv_Cost_Ene_per_tonne]

    df_storages[!, :Inv_Cost_Dis_Base_per_tonne_per_hr] =
        df_storages[!, :Inv_Cost_Dis_per_tonne_per_hr]

    df_storages[in(STO_set).(df_storages.Resource_Type), :Self_Discharge_Percentage] .=
        round.(reduce(vcat, repeat([rand() ./ 1000], zones) for _ in 1:storage_number))
    df_storages[!, :Inv_Cost_Cha_Base_per_tonne_per_hr] =
        df_storages[!, :Inv_Cost_Cha_per_tonne_per_hr]

    df_storages[in(STO_set).(df_storages.Resource_Type), :Eff_Charge] .=
        round.(reduce(vcat, repeat([rand()], zones) for _ in 1:storage_number); digits = 1)
    df_storages[in(STO_set).(df_storages.Resource_Type), :Eff_Discharge] .=
        round.(reduce(vcat, repeat([rand()], zones) for _ in 1:storage_number); digits = 1)

    CSV.write(joinpath(path, "Storage.csv"), df_storages)
end
