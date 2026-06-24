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
function modify_foodstuff_settings(settings::Dict, modification::Dict)

    print_and_log(settings, "i", "Modifying Foodstuff Settings According to User's Modification")

    foodstuff_settings = settings["FoodstuffSettings"]
    dfFoodstuffSettings = foodstuff_settings["dfFoodstuffSettings"]
    mkeys = collect(keys(modification))

    ## Foodstuff sector settings
    foodstuff_settings_keys = [
        "F_AllowImport",
        "F_AllowExport",
        "F_CropTransport",
        "F_FoodTransport",
        "F_ModelTrucks",
        "F_TruckExpansion",
        "F_TruckInteger",
        "F_CropRotation",
        "F_InitialCropVolume",
        "F_InitialFoodVolume",
        "F_YearlyBalance",
        "F_ArableAreaDivision",
        "F_AmmoniaRateUrea",
        "F_CarbonRateUrea",
        "F_HydrogenRateAmmonia",
        "F_NitrogenRateAmmonia",
        "F_ImportPath",
        "F_ExportPath",
        "F_LandPath",
        "F_CropPath",
        "F_CropTimePath",
        "F_TrucksPath",
        "F_RoutesPath",
        "F_StoragePath",
        "F_DemandPath",
    ]

    for (key, value) in modification
        if key in foodstuff_settings_keys
            ## Modify foodstuff sector settings according to modification
            foodstuff_settings[split(key, "_")[2]] = value
            delete!(modification, key)
        elseif key in ["F_Crops", "F_Zones"]
            ## Modify foodstuff sector zones according to modification
            foodstuff_settings[split(key, "_")[2]] = value
            delete!(modification, key)
        end
    end

    ## Update foodstuff settings origination dataframe
    dfFoodstuffSettings = transform(
        dfFoodstuffSettings,
        [:Key, :Value, :Origin] =>
            ByRow(
                (k, v, o) -> (
                    Value = k in foodstuff_settings_keys ? foodstuff_settings[k] : v,
                    Origin = k in foodstuff_settings_keys ? "user-modi" : o,
                ),
            ) => AsTable,
    )
    foodstuff_settings["dfFoodstuffSettings"] = dfFoodstuffSettings
    settings["FoodstuffSettings"] = foodstuff_settings

    ## Store modification dict into settings for data modification
    settings["Modification"] = modification

    return settings
end
