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
function generate_foodstuff(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Generating Foodstuff Sub Model")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    foodstuff_inputs = inputs["FoodstuffInputs"]
    foodstuff_settings = settings["FoodstuffSettings"]

    Crops = foodstuff_settings["Crops"]
    Foods = foodstuff_inputs["Foods"]

    ## Foodstuff sector objective
    @expression(MESS, eFObj, AffExpr(0))

    ## Foodstuff sector farming, transmission, storage and demand balance
    @expression(MESS, eFBalance[z in 1:Z, fs in eachindex(Foods), t in 1:T], AffExpr(0))

    ## Foodstuff sector emissions
    ## Direct emissions from foodstuff sector
    @expression(MESS, eFEmissions[z in 1:Z, t in 1:T], AffExpr(0))
    ## Non-CO2 emissions from foodstuff sector
    @expression(MESS, eFEmissionsCO2eq[z in 1:Z, t in 1:T], AffExpr(0))

    ## Foodstuff sector captured emissions
    ##! Foodstuff crop farming captured emissions should be considered more carefully
    @expression(MESS, eFCapture[z in 1:Z, t in 1:T], AffExpr(0))

    ## Foodstuff sector feedstock consumption
    MESS = consumption_in_foodstuff(settings, inputs, MESS)

    ## Foodstuff sector crop import
    if foodstuff_settings["AllowImport"] == 1
        MESS = crop_import(settings, inputs, MESS)
    end

    ## Foodstuff sector crop export
    if foodstuff_settings["AllowExport"] == 1
        MESS = crop_export(settings, inputs, MESS)
    end

    ## Foodstuff sector crop farming
    MESS = crop_farming_all(settings, inputs, MESS)

    ## Foodstuff sector crop warehouse
    MESS = crop_warehouse_all(settings, inputs, MESS)

    ## Foodstuff sector crop transport
    if foodstuff_settings["CropTransport"] == 1
        MESS = crop_transport(settings, inputs, MESS)
        @expression(
            MESS,
            eFCropAvail[z in 1:Z, cs in eachindex(Crops), t in 1:T],
            MESS[:vFCropStoDis][z, cs, t] + MESS[:eFCropTransportFlow][z, cs, t]
        )
    else
        @expression(
            MESS,
            eFCropAvail[z in 1:Z, cs in eachindex(Crops), t in 1:T],
            MESS[:vFCropStoDis][z, cs, t]
        )
    end

    ## Foodstuff sector food production
    MESS = production_all(settings, inputs, MESS)

    ## Foodstuff sector crop import limit
    if foodstuff_settings["AllowImport"] == 1
        MESS = crop_import_limit(settings, inputs, MESS)
    end

    ## Foodstuff sector crop export limit
    if foodstuff_settings["AllowExport"] == 1
        MESS = crop_export_limit(settings, inputs, MESS)
    end

    ## Foodstuff sector transmission
    @expression(MESS, eFTransmission[z in 1:Z, fs in eachindex(Foods), t in 1:T], AffExpr(0))

    ## Foodstuff sector transport
    if foodstuff_settings["FoodTransport"] == 1
        MESS = food_transport(settings, inputs, MESS)
    end

    ## Foodstuff sector truck transmission - disabled when FoodTransport is enabled
    if foodstuff_settings["ModelTrucks"] == 1
        MESS = truck_investment(settings, inputs, MESS)
        MESS = truck_all(settings, inputs, MESS)
    end

    ## Foodstuff sector warehouse storage
    MESS = food_warehouse_investment_volume(settings, inputs, MESS)
    MESS = food_warehouse_volume(settings, inputs, MESS)

    ## Foodstuff sector demand
    MESS = demand_all(settings, inputs, MESS)

    ## Foodstuff sector feedstock consumption
    MESS = consumption(settings, inputs, MESS)

    ## Add foodstuff sector objective into total objective function
    add_to_expression!(MESS[:eObj], MESS[:eFObj])

    ## Add foodstuff sector emissions into total emissions
    add_to_expression!.(MESS[:eEmissions], MESS[:eFEmissions])

    ##TODO: Foodstuff sector emissions and captured emissions should be considered more carefully
    ## Add foodstuff sector captured carbon into total captured carbon
    # add_to_expression!.(MESS[:eCapture], MESS[:eFCapture])

    return MESS
end
