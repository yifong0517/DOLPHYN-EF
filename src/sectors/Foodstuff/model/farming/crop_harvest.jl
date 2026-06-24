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
function crop_harvest(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Sector Crops Farming Harvest Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    foodstuff_inputs = inputs["FoodstuffInputs"]
    dfCrop = foodstuff_inputs["dfCrop"]
    CT = foodstuff_inputs["CT"]
    Crop_Type = foodstuff_inputs["Crop_Type"]

    ## Crops list
    Crops = foodstuff_inputs["Crops"]

    ## Crops related time series sequence
    dfCrop_Phenology = foodstuff_inputs["dfCrop_Phenology"]
    dfCrop_LandState = foodstuff_inputs["dfCrop_LandState"]

    ### Expressions ###
    ## Annual crop yielded amount of type 'ct'
    @expression(
        MESS,
        eFCropYieldTotal[ct in 1:CT],
        dfCrop[!, :Yield_tonne_per_hm2][ct] *
        (1 - dfCrop[!, :Reaping_Loss][ct]) *
        MESS[:eFCropArableArea][ct]
    )

    ## Hourly crop yielded amount of type 'ct' at time "t"
    @expression(
        MESS,
        eFCropYieldHourly[ct in 1:CT, t in 1:T],
        if dfCrop_Phenology[t, Symbol(Crop_Type[ct])] == 3
            MESS[:eFCropYieldTotal][ct] / dfCrop_LandState[ct, "Harvest"]
        else
            0.0
        end
    )

    ## Hourly crop yielded amount of type "cs" on zone "z" at time "t"
    @expression(
        MESS,
        eFCropYield[z in 1:Z, cs in eachindex(Crops), t in 1:T],
        sum(
            MESS[:eFCropYieldHourly][ct, t] for ct in intersect(
                dfCrop[dfCrop.Zone .== Zones[z], :CT_ID],
                dfCrop[dfCrop.Crop .== Crops[cs], :CT_ID],
            );
            init = 0.0,
        )
    )

    ## Annual crop yielded amount of type "cs" on zone "z"
    @expression(
        MESS,
        eFCropYieldAnnual[z in 1:Z, cs in eachindex(Crops)],
        sum(MESS[:eFCropYield][z, cs, t] for t in 1:T)
    )
    ### End Expressions ###

    return MESS
end
