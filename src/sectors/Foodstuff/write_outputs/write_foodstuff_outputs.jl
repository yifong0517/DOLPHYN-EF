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
function write_foodstuff_outputs(settings::Dict, inputs::Dict, MESS::Model)

    foodstuff_settings = settings["FoodstuffSettings"]
    path = foodstuff_settings["SavePath"]

    ## Flags
    AllowImport = foodstuff_settings["AllowImport"]
    AllowExport = foodstuff_settings["AllowExport"]
    CropTransport = foodstuff_settings["CropTransport"]
    ModelTrucks = foodstuff_settings["ModelTrucks"]
    FoodTransport = foodstuff_settings["FoodTransport"]

    foodstuff_inputs = inputs["FoodstuffInputs"]

    ## Check whether save path exists, if not, create it
    if !ispath(path)
        mkdir(path)
    end

    print_and_log(settings, "i", "Writing Outputs for Foodstuff Sector to $path")

    ## Write fuels consumption
    if settings["ModelFuels"] == 1
        write_foodstuff_fuels_consumption(settings, inputs, MESS)
    end

    ## Write electricity consumption
    if !(settings["ModelPower"] == 1)
        write_foodstuff_electricity_consumption(settings, inputs, MESS)
    end

    ## Write hydrogen consumption
    if !(settings["ModelHydrogen"] == 1)
        write_foodstuff_hydrogen_consumption(settings, inputs, MESS)
    end

    ## Write carbon consumption
    if !(settings["ModelCarbon"] == 1)
        write_foodstuff_carbon_consumption(settings, inputs, MESS)
    end

    ## Write expenses for purchasing feedstocks from markets
    write_foodstuff_expenses(settings, inputs, MESS)

    ## Write foodstuff sector costs
    write_foodstuff_costs(settings, inputs, MESS)

    ## Write foodstuff sector import
    if AllowImport == 1
        write_foodstuff_crop_import(settings, inputs, MESS)
    end

    ## Write foodstuff sector export
    if AllowExport == 1
        write_foodstuff_crop_export(settings, inputs, MESS)
    end

    ## Write foodstuff sector land usage
    write_foodstuff_land_usage(settings, inputs, MESS)

    ## Write foodstuff sector fertizer usage
    write_foodstuff_fertizer_usage(settings, inputs, MESS)

    ## Write foodstuff sector crop production
    write_foodstuff_crop_yield(settings, inputs, MESS)

    ## Write foodstuff sector crop warehouse
    write_foodstuff_crop_warehouse(settings, inputs, MESS)

    ## Write foodstuff sector crop transport
    if CropTransport == 1
        write_foodstuff_crop_transport_flow(settings, inputs, MESS)
        write_foodstuff_crop_transport_flux(settings, inputs, MESS)
    end

    ## Write foodstuff sector food production
    write_foodstuff_food_production(settings, inputs, MESS)

    ## Write foodstuff sector residuals collection
    write_foodstuff_residuals(settings, inputs, MESS)

    ## Write foodstuff sector transmission via trucks
    if ModelTrucks == 1
        ## Write foodstuff sector truck capacity
        write_foodstuff_truck_capacity(settings, inputs, MESS)
        ## Write foodstuff sector truck flow
        write_foodstuff_truck_flow(settings, inputs, MESS)
    end

    ## Write foodstuff sector food transport
    if FoodTransport == 1
        write_foodstuff_food_transport_flow(settings, inputs, MESS)
        write_foodstuff_food_transport_flux(settings, inputs, MESS)
    end

    ## Write foodstuff sector food warehouse
    write_foodstuff_food_warehouse(settings, inputs, MESS)

    ## Write foodstuff sector demand
    write_foodstuff_demand(settings, inputs, MESS)

    ## Write foodstuff sector additional demand decomposition
    write_foodstuff_additional_demand_decomposition(settings, inputs, MESS)

    ## Write foodstuff sector balance
    write_foodstuff_balance(settings, inputs, MESS)

    ## Write foodstuff sector emissions
    write_foodstuff_emissions(settings, inputs, MESS)

    ## Write foodstuff sector captured carbon
    write_foodstuff_captured_carbon(settings, inputs, MESS)

    return nothing
end
