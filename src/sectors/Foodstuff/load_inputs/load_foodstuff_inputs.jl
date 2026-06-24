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
	load_foodstuff_inputs(settings::Dict, inputs::Dict)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function
"""
function load_foodstuff_inputs(settings::Dict, inputs::Dict)

    ## Read foodstuff sector settings
    if typeof(settings["FoodstuffSettings"]) != String
        foodstuff_settings = settings["FoodstuffSettings"]
    else
        foodstuff_settings = load_foodstuff_settings(settings)
        settings["FoodstuffSettings"] = foodstuff_settings
    end

    ## Read foodstuff sector spatial inputs
    Zones = inputs["Zones"] # List of modeled zones

    ## Read input files
    print_and_log(settings, "i", "Reading Input Files for Foodstuff Sector")

    ## Foodstuff sector data path
    path = joinpath(settings["RootPath"], settings["FoodstuffInputs"])

    ## Foodstuff inputs dictionary
    foodstuff_inputs = Dict()

    ## Foodstuff sector spatial scope
    foodstuff_inputs["Zones"] = Zones
    if length(Zones) == 1 || inputs["OneZone"] == 1
        foodstuff_inputs["OneZone"] = true
        foodstuff_settings["ModelTrucks"] = 0
        foodstuff_settings["CropTransport"] = 0
        foodstuff_settings["FoodTransport"] = 0
        print_and_log(
            foodstuff_settings,
            "i",
            "Disable Foodstuff Sector Truck with One Zone Modeled",
        )
    else
        foodstuff_inputs["OneZone"] = false
    end

    ## Food transport
    if foodstuff_settings["FoodTransport"] == 1
        foodstuff_settings["ModelTrucks"] = 0
        print_and_log(settings, "i", "Disable Foodstuff Sector Truck with Food Transport")
    end

    ## Truck expansion
    if foodstuff_settings["ModelTrucks"] == 0
        foodstuff_settings["TruckExpansion"] = 0
    end

    foodstuff_inputs["AmmoniaRateUrea"] = foodstuff_settings["AmmoniaRateUrea"]
    foodstuff_inputs["CarbonRateUrea"] = foodstuff_settings["CarbonRateUrea"]
    foodstuff_inputs["HydrogenRateAmmonia"] = foodstuff_settings["HydrogenRateAmmonia"]
    foodstuff_inputs["NitrogenRateAmmonia"] = foodstuff_settings["NitrogenRateAmmonia"]

    inputs["FoodstuffInputs"] = foodstuff_inputs

    ## Read in foodstuff sector land data
    inputs = load_foodstuff_land(path, foodstuff_settings, inputs)

    ## Read in foodstuff sector crops related inputs
    inputs = load_foodstuff_crops(path, foodstuff_settings, inputs)

    ## Read in foodstuff sector import data
    if foodstuff_settings["AllowImport"] == 1
        inputs = load_foodstuff_import(path, foodstuff_settings, inputs)
    end

    ## Read in foodstuff sector export data
    if foodstuff_settings["AllowExport"] == 1
        inputs = load_foodstuff_export(path, foodstuff_settings, inputs)
    end

    ## Read in foodstuff sector food related inputs
    inputs = load_foodstuff_food(path, foodstuff_settings, inputs)

    ## Read in foodstuff sector crops time (sowing, growth, harvest) profiles
    inputs = load_foodstuff_crops_time(path, foodstuff_settings, inputs)

    if foodstuff_settings["CropTransport"] == 1 || foodstuff_settings["FoodTransport"] == 1
        ## Read in foodstuff sector crop transport network topology and operating attributes
        inputs = load_foodstuff_routes(path, foodstuff_settings, inputs)
    end

    if foodstuff_settings["ModelTrucks"] == 1
        ## Read in foodstuff sector truck network topology, operating and expansion attributes
        print_and_log(settings, "i", "Loading Foodstuff Truck Topology with Multiple Zones Modeled")
        inputs = load_foodstuff_trucks(path, foodstuff_settings, inputs)
    else
        print_and_log(
            settings,
            "i",
            "Aborting Loading Bioenergy Truck Topology with No Network Modeled",
        )
    end

    ## Read in foodstuff sector warehouse resources
    inputs = load_foodstuff_storage(path, foodstuff_settings, inputs)

    ## Read in foodstuff sector demand data
    inputs = load_foodstuff_demand(path, foodstuff_settings, inputs)

    print_and_log(settings, "i", "Input Files for Foodstuff Sector Successfully Read in from $path")

    return inputs
end
