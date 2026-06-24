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
function production_residuals(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Sector Foods Production Residuals Module")

    T = inputs["T"]
    Z = inputs["Z"]
    Zones = inputs["Zones"]

    foodstuff_inputs = inputs["FoodstuffInputs"]
    Crops = foodstuff_inputs["Crops"]
    Residuals = foodstuff_inputs["Agriculture_Production_Residuals"]
    FT = foodstuff_inputs["FT"]

    dfFood = foodstuff_inputs["dfFood"]

    ### Expressions ###
    ## The amount of residues from food produciton
    ## Assuming that all crops are from warehouse
    @expression(
        MESS,
        eFFoodResidualsProduction[z in 1:Z, rs in eachindex(Residuals), t in 1:T],
        sum(
            MESS[:vFCropStoDis][z, only(indexin([dfFood[!, :Crop][ft]], Crops)), t] *
            dfFood[!, :Production_Biomass_Percentage][ft] *
            dfFood[!, :Production_Biomass_Rate][ft] for ft in intersect(
                1:FT,
                dfFood[dfFood.Zone .== Zones[z], :FT_ID],
                dfFood[dfFood.Production_Biomass_Type .== Residuals[rs], :FT_ID],
            );
            init = 0.0,
        )
    )

    @expression(
        MESS,
        eFFoodResidualsProductionZonal[z in 1:Z, rs in eachindex(Residuals)],
        sum(MESS[:eFFoodResidualsProduction][z, rs, t] for t in 1:T; init = 0.0)
    )
    ### End Expressions ###

    return MESS
end
