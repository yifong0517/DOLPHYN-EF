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
function crop_import(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Sector Crops Import Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    foodstuff_inputs = inputs["FoodstuffInputs"]
    dfImport = foodstuff_inputs["dfImport"]
    dfFood = foodstuff_inputs["dfFood"]
    Crops = foodstuff_inputs["Crops"]
    FT = foodstuff_inputs["FT"]

    ### Variables ###
    ## Amount of crop import of food type 'ft' at time "t"
    @variable(MESS, vFCropImport[ft in 1:FT, t in 1:T] >= 0)

    ### Expressions ###
    ## Imported crops production expression
    @expression(
        MESS,
        eFFoodImport[ft in 1:FT, t in 1:T],
        MESS[:vFCropImport][ft, t] *
        dfFood[!, :Production_Food_Percentage][ft] *
        dfFood[!, :Production_Food_Rate][ft]
    )

    ## Amount of crop import in zone "z" of crop type "cs" at time "t"
    @expression(
        MESS,
        eFCropImport[z in 1:Z, cs in eachindex(Crops), t in 1:T],
        sum(
            MESS[:vFCropImport][ft, t] for ft in intersect(
                1:FT,
                dfFood[dfFood.Zone .== Zones[z], :FT_ID],
                dfFood[dfFood.Crop .== Crops[cs], :FT_ID],
            );
            init = 0.0,
        )
    )

    ## Objective Expressions ##
    ## Import purchasing costs for crop of type "cs" in zone "z" at time "t"
    @expression(
        MESS,
        eFObjCropImportOZCST[z in 1:Z, cs in eachindex(Crops), t in 1:T],
        dfImport[!, :Trade_Price_tonne][only(
            intersect(
                dfImport[dfImport.Zone .== Zones[z], :CT_ID],
                dfImport[dfImport.Crop .== Crops[cs], :CT_ID],
            ),
        )] * MESS[:eFCropImport][z, cs, t]
    )
    @expression(
        MESS,
        eFObjCropImportOZCS[z in 1:Z, cs in eachindex(Crops)],
        sum(MESS[:eFObjCropImportOZCST][z, cs, t] for t in 1:T)
    )
    @expression(
        MESS,
        eFObjCropImportOZ[z in 1:Z],
        sum(MESS[:eFObjCropImportOZCS][z, cs] for cs in eachindex(Crops))
    )
    @expression(MESS, eFObjCropImport, sum(MESS[:eFObjCropImportOZ][z] for z in 1:Z))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eFObj], MESS[:eFObjCropImport])
    ## End Objective Expressions ##
    ### End Expressions ###

    return MESS
end
