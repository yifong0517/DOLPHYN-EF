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
    fake_bioenergy_storage(path::AbstractString, zones::Integer, storages::Dict{String, Int64})

This function fakes bioenergy storage data from nowhere.
"""
function fake_bioenergy_storage(path::AbstractString, zones::Integer, storages::Dict{String, Int64})

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
        Existing_Volume_Cap_tonne = zeros(resources_number),
        Max_Volume_Cap_tonne = repeat([-1], resources_number),
        Min_Volume_Cap_tonne = zeros(Int64, resources_number),
        Inv_Cost_Volume_per_tonne = zeros(resources_number),
        Inv_Cost_Base_Volume_per_tonne = zeros(resources_number),
        Compare_Volume_tonne = zeros(Int64, resources_number),
        Scale = ones(Int64, resources_number),
        Lifetime = ceil.(rand(resources_number) .* 20) .+ 4,
        WACC = ones(resources_number) .* 0.07,
        Fixed_OM_Cost_Volume_Percentage = round.(rand(resources_number) ./ 4, sigdigits = 2),
        Storage_Min_Level = zeros(resources_number),
        Storage_Max_Level = ones(resources_number),
        Self_Discharge_Percentage = zeros(resources_number),
    )

    ## Merge parameters dataframe into resources dataframe
    df_storages = hcat(df_storages, df_parameters)

    ## Justify parameters according to resources type
    ## Storage resources
    df_storages[in(STO_set).(df_storages.Resource_Type), :STOR] .= 1

    CSV.write(joinpath(path, "Warehouse.csv"), df_storages)
end
