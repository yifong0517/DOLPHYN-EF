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
function crop_fertilizer(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Sector Crops Farming Fertilizer Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    foodstuff_inputs = inputs["FoodstuffInputs"]

    dfCrop = foodstuff_inputs["dfCrop"]
    CT = foodstuff_inputs["CT"]
    Crop_Type = foodstuff_inputs["Crop_Type"]
    Crops = foodstuff_inputs["Crops"]

    ## Crops related time series sequence
    dfCrop_Phenology = foodstuff_inputs["dfCrop_Phenology"]
    dfCrop_LandState = foodstuff_inputs["dfCrop_LandState"]

    ### Expressions ###
    ## Urea usage
    @expression(
        MESS,
        eFCropUreaUsage[ct in 1:CT],
        dfCrop[!, :Urea_Rate_tonne_per_hm2][ct] * MESS[:eFCropArableArea][ct]
    )
    @expression(
        MESS,
        eFCropZonalUreaUsage[z in 1:Z, cs in eachindex(Crops)],
        sum(
            dfCrop[!, :Urea_Rate_tonne_per_hm2][ct] * MESS[:eFCropArableZonalArea][z, cs] for
            ct in intersect(
                1:CT,
                dfCrop[dfCrop.Zone .== Zones[z], :CT_ID],
                dfCrop[dfCrop.Crop .== Crops[cs], :CT_ID],
            );
            init = 0.0,
        )
    )

    ## Annual amount of N2O emission
    @expression(
        MESS,
        eFCropEmissionsN2OAnnual[ct in 1:CT],
        dfCrop[!, :N2O_Rate_tonne_per_Urea][ct] *
        dfCrop[!, :Urea_Rate_tonne_per_hm2][ct] *
        MESS[:eFCropArableArea][ct]
    )

    ## Hourly amount of N2O emissions
    @expression(
        MESS,
        eFCropEmissionsN2OHourly[ct in 1:CT, t in 1:T],
        if dfCrop_Phenology[t, Symbol(Crop_Type[ct])] == 2
            MESS[:eFCropEmissionsN2OAnnual][ct] / dfCrop_LandState[ct, "Growth"]
        else
            0.0
        end
    )

    ## Hourly amount of N2O emissions on "z" and "t"
    ## 298 is global warming potential of N2O relative to CO2
    @expression(
        MESS,
        eFCropEmissionsCO2eqN2O[z in 1:Z, t in 1:T],
        298 * sum(
            MESS[:eFCropEmissionsN2OHourly][ct, t] for
            ct in dfCrop[dfCrop.Zone .== Zones[z], :CT_ID];
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:eFEmissionsCO2eq], MESS[:eFCropEmissionsCO2eqN2O])

    ## Ammonia consumption - based on urea usage
    @expression(
        MESS,
        eFCropAmmoniaUsage[ct in 1:CT],
        foodstuff_inputs["AmmoniaRateUrea"] * MESS[:eFCropUreaUsage][ct]
    )
    @expression(
        MESS,
        eFCropZonalAmmoniaUsage[z in 1:Z, cs in eachindex(Crops)],
        foodstuff_inputs["AmmoniaRateUrea"] * MESS[:eFCropZonalUreaUsage][z, cs]
    )

    ## Hourly amount of ammonia consumption
    @expression(
        MESS,
        eFCropAmmoniaUsageHourly[ct in 1:CT, t in 1:T],
        if dfCrop_Phenology[t, Symbol(Crop_Type[ct])] == 2
            MESS[:eFCropAmmoniaUsage][ct] / dfCrop_LandState[ct, "Growth"]
        else
            0.0
        end
    )

    ## Carbon consumption and hydrogen consumption are linked in the script crop_fertilizer.jl
    ## Carbon dioxide consumption - based on urea usage
    @expression(
        MESS,
        eFCropCarbonUsage[ct in 1:CT],
        foodstuff_inputs["CarbonRateUrea"] * MESS[:eFCropUreaUsage][ct]
    )
    @expression(
        MESS,
        eFCropZonalCarbonUsage[z in 1:Z, cs in eachindex(Crops)],
        foodstuff_inputs["CarbonRateUrea"] * MESS[:eFCropZonalUreaUsage][z, cs]
    )

    ## Hourly amount of carbon consumption
    @expression(
        MESS,
        eFCropCarbonUsageHourly[ct in 1:CT, t in 1:T],
        if dfCrop_Phenology[t, Symbol(Crop_Type[ct])] == 2
            MESS[:eFCropCarbonUsage][ct] / dfCrop_LandState[ct, "Growth"]
        else
            0.0
        end
    )

    ### End Expressions ###

    return MESS
end
