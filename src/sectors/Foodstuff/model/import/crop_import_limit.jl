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
function crop_import_limit(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Sector Crops Import Limit Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    foodstuff_inputs = inputs["FoodstuffInputs"]
    Crops = foodstuff_inputs["Crops"]
    Foods = foodstuff_inputs["Foods"]
    FT = foodstuff_inputs["FT"]

    dfFood = foodstuff_inputs["dfFood"]
    dfImport = foodstuff_inputs["dfImport"]

    ### Expressions ###
    ## Equivalent amount of food import of food type "fs" at time "t"
    @expression(
        MESS,
        eFFoodImportEq[z in 1:Z, fs in eachindex(Foods), t in 1:T],
        sum(
            MESS[:eFFoodImport][ft, t] / dfImport[!, :Raw_Grain_Rate][only(
                intersect(
                    dfImport[dfImport.Zone .== Zones[z], :CT_ID],
                    dfImport[dfImport.Crop .== dfFood[!, :Crop][ft], :CT_ID],
                ),
            )] / dfImport[!, :Trade_Limit_Percentage][only(
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
    ### End Expressions ###

    ### Constraints ###
    ## Import limit based on annual foodstuff demand
    @constraint(
        MESS,
        cFCropImportLimit[z in 1:Z, fs in eachindex(Foods)],
        sum(MESS[:eFFoodImportEq][z, fs, t] for t in 1:T) <= foodstuff_inputs["D_Annual"][z, fs]
    )
    ### End Constraints ###

    return MESS
end
