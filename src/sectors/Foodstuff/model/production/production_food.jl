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
function production_food(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Sector Foods Production Conversion Module")

    T = inputs["T"]
    Z = inputs["Z"]
    Zones = inputs["Zones"]

    foodstuff_settings = settings["FoodstuffSettings"]
    foodstuff_inputs = inputs["FoodstuffInputs"]
    Crops = foodstuff_inputs["Crops"]
    Foods = foodstuff_inputs["Foods"]
    FT = foodstuff_inputs["FT"]

    dfFood = foodstuff_inputs["dfFood"]

    if foodstuff_settings["AllowImport"] == 1
        dfImport = foodstuff_inputs["dfImport"]
    end

    ### Expressions ###
    ## Balance Expressions ##
    ## Food production from crops "cs" to food "fs"
    ## Assuming that all crops are from warehouse
    if foodstuff_settings["AllowImport"] == 1
        @expression(
            MESS,
            eFFoodProduction[z in 1:Z, fs in eachindex(Foods), t in 1:T],
            sum(
                MESS[:eFCropAvail][z, only(indexin([dfFood[!, :Crop][ft]], Crops)), t] *
                dfFood[!, :Production_Food_Percentage][ft] *
                dfFood[!, :Production_Food_Rate][ft] +
                MESS[:eFFoodImport][ft, t] / dfImport[!, :Raw_Grain_Rate][only(
                    intersect(
                        dfImport[dfImport.Zone .== Zones[z], :CT_ID],
                        dfImport[dfImport.Crop .== dfFood[!, :Crop][ft], :CT_ID],
                    ),
                )] for ft in intersect(
                    1:FT,
                    dfFood[dfFood.Zone .== Zones[z], :FT_ID],
                    dfFood[dfFood.Production_Food_Type .== Foods[fs], :FT_ID],
                );
                init = 0.0,
            )
        )
    else
        @expression(
            MESS,
            eFFoodProduction[z in 1:Z, fs in eachindex(Foods), t in 1:T],
            sum(
                MESS[:eFCropAvail][z, only(indexin([dfFood[!, :Crop][ft]], Crops)), t] *
                dfFood[!, :Production_Food_Percentage][ft] *
                dfFood[!, :Production_Food_Rate][ft] for ft in intersect(
                    1:FT,
                    dfFood[dfFood.Zone .== Zones[z], :FT_ID],
                    dfFood[dfFood.Production_Food_Type .== Foods[fs], :FT_ID],
                );
                init = 0.0,
            )
        )
    end

    add_to_expression!.(MESS[:eFBalance], MESS[:eFFoodProduction])
    ## End Balance Expressions ##

    ## Objective Expressions ##
    ## Cost of food production
    @expression(
        MESS,
        eFObjFoodProductionOZFST[z in 1:Z, fs in eachindex(Foods), t in 1:T],
        sum(
            MESS[:vFCropStoDis][z, only(indexin([dfFood[!, :Crop][ft]], Crops)), t] *
            dfFood[!, :Production_Food_Cost][ft] for ft in intersect(
                1:FT,
                dfFood[dfFood.Zone .== Zones[z], :FT_ID],
                dfFood[dfFood.Production_Food_Type .== Foods[fs], :FT_ID],
            );
            init = 0.0,
        )
    )
    @expression(
        MESS,
        eFObjFoodProductionOZFS[z in 1:Z, fs in eachindex(Foods)],
        sum(MESS[:eFObjFoodProductionOZFST][z, fs, t] for t in 1:T)
    )
    @expression(
        MESS,
        eFObjFoodProductionOZ[z in 1:Z],
        sum(MESS[:eFObjFoodProductionOZFS][z, fs] for fs in eachindex(Foods))
    )
    @expression(MESS, eFObjFoodProduction, sum(MESS[:eFObjFoodProductionOZ][z] for z in 1:Z))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eFObj], MESS[:eFObjFoodProduction])
    ## End Objective Expressions ##
    ### End Expressions ###

    return MESS
end
