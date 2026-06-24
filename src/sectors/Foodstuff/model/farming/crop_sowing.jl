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
function crop_sowing(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Sector Crops Farming Sowing Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
    end
    foodstuff_inputs = inputs["FoodstuffInputs"]

    dfCrop = foodstuff_inputs["dfCrop"]
    CT = foodstuff_inputs["CT"]
    Crop_Type = foodstuff_inputs["Crop_Type"]

    ## Crops related time series sequence
    dfCrop_Phenology = foodstuff_inputs["dfCrop_Phenology"]
    dfCrop_LandState = foodstuff_inputs["dfCrop_LandState"]

    ### Expressions ###
    ## Annual power consumption from crops sowing during farming
    @expression(
        MESS,
        eFElectricityConsumptionAnnual[ct in 1:CT],
        dfCrop[!, :Electricity_Rate_MWh_per_hm2][ct] * MESS[:eFCropArableArea][ct]
    )

    ## Hourly power consumption from crops sowing during farming
    @expression(
        MESS,
        eFElectricityConsumptionHourly[ct in 1:CT, t in 1:T],
        if dfCrop_Phenology[t, Symbol(Crop_Type[ct])] == 1
            MESS[:eFElectricityConsumptionAnnual][ct] / dfCrop_LandState[ct, "Sowing"]
        else
            0.0
        end
    )

    ## Hourly power consumption from crops sowing during farming on "z" and "t"
    ## Power consumption from foodstuff sowing
    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceCropSowing[z in 1:Z, t in 1:T],
            sum(
                MESS[:eFElectricityConsumptionHourly][ct, t] for
                ct in intersect(1:CT, dfCrop[dfCrop.Zone .== Zones[z], :CT_ID]);
                init = 0.0,
            )
        )

        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceCropSowing])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceCropSowing])
    else
        @expression(
            MESS,
            eFElectricityConsumptionFromSowing[
                f in eachindex(Electricity_Index),
                z in 1:Z,
                t in 1:T,
            ],
            sum(
                MESS[:eFElectricityConsumptionHourly][ct, t] for ct in intersect(
                    1:CT,
                    dfCrop[dfCrop.Zone .== Zones[z], :CT_ID],
                    dfCrop[dfCrop.Electricity .== Electricity_Index[f], :CT_ID],
                );
                init = 0.0,
            )
        )

        add_to_expression!.(
            MESS[:eFElectricityConsumption],
            MESS[:eFElectricityConsumptionFromSowing],
        )
    end
    ### End Expressions ###

    return MESS
end
