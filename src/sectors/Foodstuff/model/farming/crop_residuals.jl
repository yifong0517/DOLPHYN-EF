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
function crop_residuals(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Sector Crops Farming Residuals Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    foodstuff_inputs = inputs["FoodstuffInputs"]
    dfCrop = foodstuff_inputs["dfCrop"]
    CT = foodstuff_inputs["CT"]
    Straws = foodstuff_inputs["Straws"]

    ### Expressions ###
    ## The total amount of straw that can be collected from harvest
    ##TODO: 0.089 is percentage that are used in energy, this should be moved out of here as parameters
    @expression(
        MESS,
        eFCropCollectedStrawTotal[ct in 1:CT],
        dfCrop[!, :Collectable_Straw_Coefficient][ct] *
        MESS[:eFCropYieldTotal][ct] *
        dfCrop[!, :Residuals_Energy_Utilization][ct]
    )

    ## Hourly collected straw amount from crop type 'ct' at time "t"
    @expression(
        MESS,
        eFCropCollectedStrawHourly[ct in 1:CT, t in 1:T],
        dfCrop[!, :Collectable_Straw_Coefficient][ct] *
        MESS[:eFCropYieldHourly][ct, t] *
        dfCrop[!, :Residuals_Energy_Utilization][ct]
    )

    ## Zonal collected straw amount on zone "z"
    @expression(
        MESS,
        eFCropCollectedStrawZonal[z in 1:Z, ss in eachindex(Straws)],
        sum(
            MESS[:eFCropCollectedStrawTotal][ct] for ct in intersect(
                dfCrop[dfCrop.Zone .== Zones[z], :CT_ID],
                dfCrop[dfCrop.Straw_Type .== Straws[ss], :CT_ID],
            );
            init = 0.0,
        )
    )

    ## Hourly collected straw amount on zone "z" at time "t" for each type of straw
    @expression(
        MESS,
        eFCropCollectedStraw[z in 1:Z, ss in eachindex(Straws), t in 1:T],
        sum(
            MESS[:eFCropCollectedStrawHourly][ct, t] for ct in intersect(
                dfCrop[dfCrop.Zone .== Zones[z], :CT_ID],
                dfCrop[dfCrop.Straw_Type .== Straws[ss], :CT_ID],
            );
            init = 0.0,
        )
    )
    ### End Expressions ###

    return MESS
end
