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
function load_foodstuff_default_settings(foodstuff_settings::Dict)

    ## Foodstuff sector settings origination dataframe
    dfFoodstuffSettings =
        DataFrame(Scope = String[], Key = String[], Value = Any[], Origin = String[])
    foodstuff_settings["dfFoodstuffSettings"] = dfFoodstuffSettings

    # Foodstuff Model Option
    ## Whether to allow crop import; 0 = not active; 1 = active
    set_default_value!(foodstuff_settings, "AllowImport", 1)
    ## Whether to allow crop export; 0 = not active; 1 = active
    set_default_value!(foodstuff_settings, "AllowExport", 1)

    ## Whether to model crop transport; 0 = not active; 1 = active
    set_default_value!(foodstuff_settings, "CropTransport", 1)
    ## Whether to model food transport; 0 = not active; 1 = active
    set_default_value!(foodstuff_settings, "FoodTransport", 1)

    ## Whether to model truck in hydrogen supply chain - 0 - not included, 1 - included
    set_default_value!(foodstuff_settings, "ModelTrucks", 1)
    ## Transmission network expansional; 0 = not active; 1 = active systemwide
    set_default_value!(foodstuff_settings, "TruckExpansion", 1)    ## Whether to model truck capacity as discrete or integer - 0 - continuous capacity, 1- discrete capacity
    set_default_value!(foodstuff_settings, "TruckInteger", 0)

    ## Whether to model crop rotation in warehouse - 0 - not included, 1 - included
    set_default_value!(foodstuff_settings, "CropRotation", 1)

    ## Initial crop volume in warehouse
    set_default_value!(foodstuff_settings, "InitialCropVolume", 0)

    ## Initial food volume in warehouse
    set_default_value!(foodstuff_settings, "InitialFoodVolume", 0)

    ## Yearly balance of foodstuff sector
    set_default_value!(foodstuff_settings, "YearlyBalance", 1)

    ## List of modeled crops
    set_default_value!(foodstuff_settings, "Crops", ["Corn", "Rice", "Wheat", "Beet", "Sorghum"])

    ## Reference year for the model
    set_default_value!(foodstuff_settings, "ReferenceYear", "2020")
    ## Arable area division; "mannual" = mannual division; "automatic" = automatic division
    set_default_value!(foodstuff_settings, "ArableAreaDivision", "mannual")

    ## Ammonia consumption rate per tonne of urea
    set_default_value!(foodstuff_settings, "AmmoniaRateUrea", 0.57)
    ## Carbon consumption rate per tonne of urea
    set_default_value!(foodstuff_settings, "CarbonRateUrea", 0.75)
    ## Hydrogen consumption rate per tonne of ammonia
    set_default_value!(foodstuff_settings, "HydrogenRateAmmonia", 0.18)
    ## Nitrogen consumption rate per tonne of ammonia
    set_default_value!(foodstuff_settings, "NitrogenRateAmmonia", 0.82)

    # Data file name
    ## File name which stores data of crop import
    set_default_value!(foodstuff_settings, "ImportPath", "Import.csv")
    ## File name which stores data of crop export
    set_default_value!(foodstuff_settings, "ExportPath", "Export.csv")
    ## File name which stores data of land
    set_default_value!(foodstuff_settings, "LandPath", "Land.csv")
    ## File name which stores data of crops
    set_default_value!(foodstuff_settings, "CropPath", "Crops.csv")
    ## File name which stores data of crops' phenology
    set_default_value!(foodstuff_settings, "CropTimePath", "Crop_Time.csv")
    ## File name which stores data of trucks
    set_default_value!(foodstuff_settings, "TrucksPath", "Trucks.csv")
    ## File name which stores data of routes
    set_default_value!(foodstuff_settings, "RoutesPath", "Routes.csv")
    ## File name which stores data of storage
    set_default_value!(foodstuff_settings, "StoragePath", "Warehouse.csv")
    ## File name which stores data of demand
    set_default_value!(foodstuff_settings, "DemandPath", "Demand.csv")

    return foodstuff_settings
end

@doc raw"""

"""
function set_default_value!(foodstuff_settings::Dict, key::String, default_value::Any)

    dfFoodstuffSettings = foodstuff_settings["dfFoodstuffSettings"]
    if !haskey(foodstuff_settings, key)
        foodstuff_settings[key] = default_value
    else
        push!(dfFoodstuffSettings, ["Foodstuff", key, foodstuff_settings[key], "user-file"])
    end
end
