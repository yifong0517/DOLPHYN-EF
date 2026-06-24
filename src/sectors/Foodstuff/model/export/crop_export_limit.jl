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
function crop_export_limit(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Sector Crops Export Limit Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    foodstuff_inputs = inputs["FoodstuffInputs"]
    Crops = foodstuff_inputs["Crops"]
    dfExport = foodstuff_inputs["dfExport"]

    ### Constraints ###
    ## Export limit based on annual crop yield
    @constraint(
        MESS,
        cFCropExportLimit[z in 1:Z, cs in eachindex(Crops)],
        sum(MESS[:vFCropExport][z, cs, t] for t in 1:T) <=
        MESS[:eFCropYieldAnnual][z, cs] *
        dfExport[!, :Raw_Grain_Rate][only(
            intersect(
                dfExport[dfExport.Zone .== Zones[z], :CT_ID],
                dfExport[dfExport.Crop .== Crops[cs], :CT_ID],
            ),
        )] *
        dfExport[!, :Trade_Limit_Percentage][only(
            intersect(
                dfExport[dfExport.Zone .== Zones[z], :CT_ID],
                dfExport[dfExport.Crop .== Crops[cs], :CT_ID],
            ),
        )]
    )
    ### End Constraints ###

    return MESS
end
