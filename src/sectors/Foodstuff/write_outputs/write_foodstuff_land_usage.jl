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
function write_foodstuff_land_usage(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        foodstuff_settings = settings["FoodstuffSettings"]
        path = foodstuff_settings["SavePath"]

        Zones = inputs["Zones"]
        foodstuff_inputs = inputs["FoodstuffInputs"]

        Crops = foodstuff_inputs["Crops"]
        dfCrop = foodstuff_inputs["dfCrop"]
        Crop_Type = foodstuff_inputs["Crop_Type"]

        ## Land usage for each type of crop
        dfCropLand = DataFrame(
            Crop_Type = string.(Crop_Type),
            Zone = string.(dfCrop[!, :Zone]),
            Reference_Year = foodstuff_settings["ReferenceYear"],
        )

        if foodstuff_settings["ArableAreaDivision"] == "mannual"
            dfCropLand = hcat(
                dfCropLand,
                DataFrame(
                    Division = "mannual",
                    Land_Area = round.(value.(MESS[:eFCropArableArea]); sigdigits = 6),
                    Yield_Rate = round.(dfCrop[!, :Yield_tonne_per_hm2]; sigdigits = 6),
                    Yield = round.(value.(MESS[:eFCropYieldTotal]); sigdigits = 6),
                ),
            )
        elseif foodstuff_settings["ArableAreaDivision"] == "automatic"
            dfCropLand = hcat(
                dfCropLand,
                DataFrame(
                    Division = "automatic",
                    Land_Area = round.(value.(MESS[:eFCropArableArea]); sigdigits = 6),
                    Yield_Rate = round.(dfCrop[!, :Yield_tonne_per_hm2]; sigdigits = 6),
                    Yield = round.(value.(MESS[:eFCropYieldTotal]); sigdigits = 4),
                    Percentage = round.(value.(MESS[:vFCropArableAreaPercentage]); digits = 4),
                    Total_Area = foodstuff_inputs["TotalArableArea"],
                ),
            )
        end

        CSV.write(joinpath(path, "foodstuff_land_usage.csv"), dfCropLand)

        ## Land usage for each zone and crop type
        dfZonalLand = DataFrame(
            Zone = Zones,
            Reference_Year = foodstuff_settings["ReferenceYear"],
            Division = foodstuff_settings["ArableAreaDivision"],
        )

        dfZonalLand = hcat(
            dfZonalLand,
            DataFrame(
                Dict(
                    Crops[cs] =>
                        round.(value.(MESS[:eFCropArableZonalArea][:, cs]); sigdigits = 6) for
                    cs in eachindex(Crops)
                ),
            ),
        )

        CSV.write(joinpath(path, "foodstuff_zonal_land_usage.csv"), dfZonalLand)
    end
end
