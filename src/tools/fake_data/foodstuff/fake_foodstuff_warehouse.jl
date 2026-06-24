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
    fake_foodstuff_warehouse(path::AbstractString, zones::Integer)

This function fakes foodstuff warehouse data from nowhere.
"""
function fake_foodstuff_warehouse(
    path::AbstractString,
    zones::Integer,
    CropType::AbstractVector{String},
)

    ## Generate zone list
    Zones = string.(1:zones)

    ## Crop mapping function
    Crop_mapping = Dict("Rice" => "Rice", "SpringWheat" => "Wheat", "WinterWheat" => "Wheat")
    ## Food mapping function
    Food_mapping =
        Dict("Rice" => "Rice", "SpringWheat" => "Wheat flour", "WinterWheat" => "Wheat flour")

    unique_crop = unique([Crop_mapping[c] for c in CropType])
    unique_food = unique([Food_mapping[c] for c in CropType])

    ## Construct resources dataframe
    df_warehouse = DataFrame(
        Resource = collect("$(z)_$(c)" for z in Zones for c in unique_crop),
        Zone = repeat(Zones, length(unique_crop)),
        Food = [c for z in Zones for c in unique_food],
    )

    resources_number = zones * length(unique_crop)

    ## Initialize storages' parameters dataframe
    df_parameters = DataFrame(
        STOR = ones(Int64, resources_number),
        LDS = zeros(Int64, resources_number),
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
    df_warehouse = hcat(df_warehouse, df_parameters)

    CSV.write(joinpath(path, "Warehouse.csv"), df_warehouse)

    return df_warehouse
end
