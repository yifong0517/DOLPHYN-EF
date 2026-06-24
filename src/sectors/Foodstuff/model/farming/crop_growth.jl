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
function crop_growth(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Sector Crops Farming Growth Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]

    T = inputs["T"]

    if !(settings["ModelHydrogen"] == 1)
        Hydrogen_Index = inputs["Hydrogen_Index"]
    end
    if !(settings["ModelCarbon"] == 1)
        Carbon_Index = inputs["Carbon_Index"]
    end

    foodstuff_inputs = inputs["FoodstuffInputs"]
    dfCrop = foodstuff_inputs["dfCrop"]
    Crops = foodstuff_inputs["Crops"]
    CT = foodstuff_inputs["CT"]
    Crop_Type = foodstuff_inputs["Crop_Type"]

    ## Crops related time series sequence
    dfCrop_Phenology = foodstuff_inputs["dfCrop_Phenology"]
    dfCrop_LandState = foodstuff_inputs["dfCrop_LandState"]

    ### Expressions ###
    ## Total amount of carbon sequestered by the arableland ecosystems
    @expression(
        MESS,
        eFCropCarbonAbsorptionTotal[ct in 1:CT],
        dfCrop[!, :Carbon_Uptake_Rate_Of_Crop][ct] * MESS[:eFCropYieldTotal][ct]
    )

    ## Hourly amount of carbon sequestered by the arableland ecosystems
    @expression(
        MESS,
        eFCropCarbonAbsorptionHourly[ct in 1:CT, t in 1:T],
        if dfCrop_Phenology[t, Symbol(Crop_Type[ct])] == 2
            MESS[:eFCropCarbonAbsorptionTotal][ct] / dfCrop_LandState[ct, "Growth"]
        else
            0.0
        end
    )

    ## Hourly amount of carbon sequestered by the arableland ecosystems on "z" and "t"
    @expression(
        MESS,
        eFCropCarbonAbsorption[z in 1:Z, t in 1:T],
        sum(
            MESS[:eFCropCarbonAbsorptionHourly][ct, t] for
            ct in dfCrop[dfCrop.Zone .== Zones[z], :CT_ID];
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:eFCapture], MESS[:eFCropCarbonAbsorption])

    ## Annual amount of methane emissions
    @expression(
        MESS,
        eFCropEmissionsMethaneAnnual[ct in 1:CT],
        dfCrop[:, :Methane_Emission_Factor][ct] * MESS[:eFCropArableArea][ct]
    )

    ## Hourly amount of methane emissions
    @expression(
        MESS,
        eFCropEmissionsMethaneHourly[ct in 1:CT, t in 1:T],
        if dfCrop_Phenology[t, Symbol(Crop_Type[ct])] == 2
            MESS[:eFCropEmissionsMethaneAnnual][ct] / dfCrop_LandState[ct, "Growth"]
        else
            0.0
        end
    )

    ## Hourly amount of methane emissions on "z" and "t"
    ## 25 is the global warming potential of methane relative to CO2
    @expression(
        MESS,
        eFCropEmissionsCO2eqMethane[z in 1:Z, t in 1:T],
        25 * sum(
            MESS[:eFCropEmissionsMethaneHourly][ct, t] for
            ct in dfCrop[dfCrop.Zone .== Zones[z], :CT_ID];
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:eFEmissionsCO2eq], MESS[:eFCropEmissionsCO2eqMethane])

    ## Carbon consumption from urea usage in crop growing
    if settings["ModelCarbon"] == 1
        @expression(
            MESS,
            eCBalanceCropGrowing[z in 1:Z, t in 1:T],
            sum(
                MESS[:eFCropCarbonUsageHourly][ct, t] for
                ct in intersect(1:CT, dfCrop[dfCrop.Zone .== Zones[z], :CT_ID]);
                init = 0.0,
            )
        )

        add_to_expression!.(MESS[:eCBalance], -MESS[:eCBalanceCropGrowing])
        add_to_expression!.(MESS[:eCDemandAddition], MESS[:eCBalanceCropGrowing])
    else
        @expression(
            MESS,
            eFCarbonConsumptionFromGrowing[f in eachindex(Carbon_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:eFCropCarbonUsageHourly][ct, t] for ct in intersect(
                    1:CT,
                    dfCrop[dfCrop.Zone .== Zones[z], :CT_ID],
                    dfCrop[dfCrop.Carbon .== Carbon_Index[f], :CT_ID],
                );
                init = 0.0,
            )
        )

        add_to_expression!.(MESS[:eFCarbonConsumption], MESS[:eFCarbonConsumptionFromGrowing])
    end

    ## Ammonia consumption from urea usage in crop growing
    if settings["ModelAmmonia"] == 1
        @expression(
            MESS,
            eABalanceCropGrowing[z in 1:Z, t in 1:T],
            sum(
                MESS[:eFCropAmmoniaUsageHourly][ct, t] for
                ct in intersect(1:CT, dfCrop[dfCrop.Zone .== Zones[z], :CT_ID]);
                init = 0.0,
            )
        )

        add_to_expression!.(MESS[:eABalance], -MESS[:eABalanceCropGrowing])
        add_to_expression!.(MESS[:eADemandAddition], MESS[:eABalanceCropGrowing])
    else
        ## Hydrogen consumption - based on ammonia consumption
        @expression(
            MESS,
            eFCropHydrogenUsage[ct in 1:CT],
            foodstuff_inputs["HydrogenRateAmmonia"] * MESS[:eFCropAmmoniaUsage][ct]
        )
        @expression(
            MESS,
            eFCropZonalHydrogenUsage[z in 1:Z, cs in eachindex(Crops)],
            foodstuff_inputs["HydrogenRateAmmonia"] * MESS[:eFCropZonalAmmoniaUsage][z, cs]
        )

        ## Hourly amount of hydrogen consumption
        @expression(
            MESS,
            eFCropHydrogenUsageHourly[ct in 1:CT, t in 1:T],
            if dfCrop_Phenology[t, Symbol(Crop_Type[ct])] == 2
                MESS[:eFCropHydrogenUsage][ct] / dfCrop_LandState[ct, "Growth"]
            else
                0.0
            end
        )

        if settings["ModelHydrogen"] == 1
            @expression(
                MESS,
                eHBalanceCropGrowing[z in 1:Z, t in 1:T],
                sum(
                    MESS[:eFCropHydrogenUsageHourly][ct, t] for
                    ct in intersect(1:CT, dfCrop[dfCrop.Zone .== Zones[z], :CT_ID]);
                    init = 0.0,
                )
            )

            add_to_expression!.(MESS[:eHBalance], -MESS[:eHBalanceCropGrowing])
            add_to_expression!.(MESS[:eHDemandAddition], MESS[:eHBalanceCropGrowing])
        else
            ## Hydrogen consumption from crop growing
            @expression(
                MESS,
                eFCropHydrogenConsumptionFromGrowing[
                    f in eachindex(Hydrogen_Index),
                    z in 1:Z,
                    t in 1:T,
                ],
                sum(
                    MESS[:eFCropHydrogenUsageHourly][ct, t] for ct in intersect(
                        1:CT,
                        dfCrop[dfCrop.Zone .== Zones[z], :CT_ID],
                        dfCrop[dfCrop.Hydrogen .== Hydrogen_Index[f], :CT_ID],
                    );
                    init = 0.0,
                )
            )

            add_to_expression!.(
                MESS[:eFHydrogenConsumption],
                MESS[:eFCropHydrogenConsumptionFromGrowing],
            )
        end

        ## Nitrogen consumption - based on ammonia consumption
        @expression(
            MESS,
            eFCropNitrogenUsage[ct in 1:CT],
            foodstuff_inputs["NitrogenRateAmmonia"] * MESS[:eFCropAmmoniaUsage][ct]
        )
        @expression(
            MESS,
            eFCropZonalNitrogenUsage[z in 1:Z, cs in eachindex(Crops)],
            foodstuff_inputs["NitrogenRateAmmonia"] * MESS[:eFCropZonalAmmoniaUsage][z, cs]
        )
    end
    ### End Expressions ###

    return MESS
end
