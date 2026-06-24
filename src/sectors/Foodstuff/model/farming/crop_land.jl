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
function crop_land(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Sector Crops Farming Arable Land Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    foodstuff_settings = settings["FoodstuffSettings"]

    foodstuff_inputs = inputs["FoodstuffInputs"]
    dfLand = foodstuff_inputs["dfLand"]
    dfCrop = foodstuff_inputs["dfCrop"]
    CT = foodstuff_inputs["CT"]
    Crop_Type = foodstuff_inputs["Crop_Type"]
    Crops = foodstuff_inputs["Crops"]

    ## Crops related time series sequence
    dfCrop_LandAvail = foodstuff_inputs["dfCrop_LandAvail"]

    ### Expressions ###
    ## The area of the crop arableland
    ## The cultivated land area is calculated from 2013 to 2021, according to the China Statistical Yearbook
    if foodstuff_settings["ArableAreaDivision"] == "mannual"
        @expression(
            MESS,
            eFCropArableArea[ct in 1:CT],
            dfCrop[!, :Arableland_Area_Percentage][ct] * first(
                dfLand[
                    dfLand.Zone .== dfCrop[!, :Zone][ct],
                    Symbol(foodstuff_settings["ReferenceYear"]),
                ],
            )
        )
    elseif foodstuff_settings["ArableAreaDivision"] == "automatic"
        @variable(MESS, vFCropArableAreaPercentage[ct in 1:CT] >= 0)
        @expression(
            MESS,
            eFCropArableArea[ct in 1:CT],
            foodstuff_inputs["TotalArableArea"] * MESS[:vFCropArableAreaPercentage][ct]
        )
    end

    ## Zonal crop arable area
    @expression(
        MESS,
        eFCropArableZonalArea[z in 1:Z, cs in eachindex(Crops)],
        sum(
            MESS[:eFCropArableArea][ct] for ct in intersect(
                1:CT,
                dfCrop[dfCrop.Zone .== Zones[z], :CT_ID],
                dfCrop[dfCrop.Crop .== Crops[cs], :CT_ID],
            );
            init = 0.0,
        )
    )
    ### End Expressions ###

    ### Constraints ###
    ## Total arable land area is less than available land area
    if foodstuff_settings["ArableAreaDivision"] == "mannual"
        @constraint(
            MESS,
            cFCropTotalArableArea[t in 1:T],
            sum(
                MESS[:eFCropArableArea][ct] * dfCrop_LandAvail[t, Symbol(Crop_Type[ct])] for
                ct in 1:CT
            ) <= foodstuff_inputs["TotalArableArea"]
        )
    elseif foodstuff_settings["ArableAreaDivision"] == "automatic"
        @constraint(
            MESS,
            cFCropTotalArableArea[t in 1:T],
            sum(
                MESS[:vFCropArableAreaPercentage][ct] * dfCrop_LandAvail[t, Symbol(Crop_Type[ct])]
                for ct in 1:CT
            ) <= 1
        )
    end

    ## Zonal arable land area is less than the total available zonal arable land area
    if foodstuff_settings["ArableAreaDivision"] == "mannual"
        @constraint(
            MESS,
            cFCropZonalArableArea[z in 1:Z, t in 1:T],
            sum(
                MESS[:eFCropArableArea][ct] * dfCrop_LandAvail[t, Symbol(Crop_Type[ct])] for
                ct in intersect(1:CT, dfCrop[dfCrop.Zone .== Zones[z], :CT_ID])
            ) <=
            first(dfLand[dfLand.Zone .== Zones[z], Symbol(foodstuff_settings["ReferenceYear"])])
        )
    elseif foodstuff_settings["ArableAreaDivision"] == "automatic"
        @constraint(
            MESS,
            cFCropZonalArableArea[z in 1:Z, t in 1:T],
            sum(
                MESS[:vFCropArableAreaPercentage][ct] * dfCrop_LandAvail[t, Symbol(Crop_Type[ct])]
                for ct in intersect(1:CT, dfCrop[dfCrop.Zone .== Zones[z], :CT_ID])
            ) <=
            first(dfLand[dfLand.Zone .== Zones[z], Symbol(foodstuff_settings["ReferenceYear"])]) /
            foodstuff_inputs["TotalArableArea"]
        )
    end
    ### End Constraints ###

    return MESS
end
