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

"""
function fake_foodstuff_crops(
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

    ## Crop type list
    Crop_Type = ["$(z)_$(c)" for z in Zones for c in CropType]

    ## Crop dataframe
    dfCrops = DataFrame(
        Crop_Type = Crop_Type,
        Zone = repeat(Zones, length(CropType)),
        Crop = [Crop_mapping[c] for z in Zones for c in CropType],
        Arableland_Area_Percentage = rand(length(Crop_Type)),
        Electricity = repeat(["Electricity_solar_1"], length(Crop_Type)),
        Electricity_Rate_MWh_per_hm2 = rand(length(Crop_Type)),
        Methane_Emission_Factor = zeros(length(Crop_Type)),
        Carbon_Uptake_Rate_Of_Crop = rand(length(Crop_Type)),
        Hydrogen = repeat(["Hydrogen_1"], length(Crop_Type)),
        Urea_Rate_tonne_per_hm2 = rand(length(Crop_Type)),
        Carbon = repeat(["Carbon_1"], length(Crop_Type)),
        N2O_Rate_tonne_per_Urea = rand(length(Crop_Type)),
        Economic_Coefcient_Of_The_Crop = rand(length(Crop_Type)),
        Water_Content_Of_The_Economic_Yield_Crop = rand(length(Crop_Type)),
        Yield_tonne_per_hm2 = rand(length(Crop_Type)) .* 45,
        Straw_Type = repeat(["None"], length(Crop_Type)),
        Collectable_Straw_Coefficient = zeros(length(Crop_Type)),
        Production_Food_Type = [Food_mapping[c] for z in Zones for c in CropType],
        Production_Food_Percentage = zeros(length(Crop_Type)),
        Production_Food_Rate = rand(length(Crop_Type)),
        Production_Biomass_Type = repeat(["None"], length(Crop_Type)),
        Production_Biomass_Percentage = zeros(length(Crop_Type)),
        Production_Biomass_Rate = zeros(length(Crop_Type)),
        Crop_Rotation_Type = [Crop_mapping[c] for z in Zones for c in CropType],
        Crop_Rotation_Rate = rand(length(Crop_Type)),
    )

    CSV.write(joinpath(path, "Crops.csv"), dfCrops)
end
