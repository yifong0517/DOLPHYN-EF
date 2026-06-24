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
function crop_export(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Sector Crops Export Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    foodstuff_inputs = inputs["FoodstuffInputs"]
    dfExport = foodstuff_inputs["dfExport"]
    Crops = foodstuff_inputs["Crops"]

    ### Variables ###
    ## Amount of crop export of type "cs" in zone "z" at time "t"
    @variable(MESS, vFCropExport[z in 1:Z, cs in eachindex(Crops), t in 1:T] >= 0)

    ### Expressions ###
    ## Objective Expressions ##
    ## Export purchasing costs for crop of type "cs" in zone "z" at time "t"
    @expression(
        MESS,
        eFObjCropExportOZCST[z in 1:Z, cs in eachindex(Crops), t in 1:T],
        dfExport[!, :Trade_Price_tonne][only(
            intersect(
                dfExport[dfExport.Zone .== Zones[z], :CT_ID],
                dfExport[dfExport.Crop .== Crops[cs], :CT_ID],
            ),
        )] * MESS[:vFCropExport][z, cs, t]
    )
    @expression(
        MESS,
        eFObjCropExportOZCS[z in 1:Z, cs in eachindex(Crops)],
        sum(MESS[:eFObjCropExportOZCST][z, cs, t] for t in 1:T)
    )
    @expression(
        MESS,
        eFObjCropExportOZ[z in 1:Z],
        sum(MESS[:eFObjCropExportOZCS][z, cs] for cs in eachindex(Crops))
    )
    @expression(MESS, eFObjCropExport, sum(MESS[:eFObjCropExportOZ][z] for z in 1:Z))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eFObj], -MESS[:eFObjCropExport])
    ## End Objective Expressions ##
    ### End Expressions ###

    return MESS
end
