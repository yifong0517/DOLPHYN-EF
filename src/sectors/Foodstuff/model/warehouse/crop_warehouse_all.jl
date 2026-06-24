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
function crop_warehouse_all(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Sector Crops Warehouse Core Module")

    T = inputs["T"]
    Z = inputs["Z"]
    Zones = inputs["Zones"]

    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]

    foodstuff_settings = settings["FoodstuffSettings"]
    foodstuff_inputs = inputs["FoodstuffInputs"]
    Crops = foodstuff_inputs["Crops"]

    dfRotation = foodstuff_inputs["dfRotation"]
    if foodstuff_settings["AllowExport"] == 1
        dfExport = foodstuff_inputs["dfExport"]
    end

    ### Variables ###
    ## Storage discharge [tonne] at hour "t" on zone "z" for crop "cs"
    @variable(MESS, vFCropStoDis[z in 1:Z, cs in eachindex(Crops), t in 1:T] >= 0)
    ## Storage level [tonne] at hour "t" on zone "z" for crop "cs"
    @variable(MESS, vFCropStoVolume[z in 1:Z, cs in eachindex(Crops), t in 1:T] >= 0)
    ## Storage capacity [tonne] on zone "z" for crop
    @variable(MESS, vFCropStoVolumeCap[z in 1:Z, cs in eachindex(Crops)] >= 0)

    ### Expressions ###
    ## Crop storage charge [tonne] at hour "t" on zone "z" for crop "cs"
    ## TODO: Assuming immediate storage action - time delay may be applied by average time difference
    if foodstuff_settings["AllowExport"] == 1
        @expression(
            MESS,
            vFCropExportEq[z in 1:Z, cs in eachindex(Crops), t in 1:T],
            MESS[:vFCropExport][z, cs, t] / dfExport[!, :Raw_Grain_Rate][only(
                intersect(
                    dfExport[dfExport.Zone .== Zones[z], :CT_ID],
                    dfExport[dfExport.Crop .== Crops[cs], :CT_ID],
                ),
            )]
        )
        @expression(
            MESS,
            eFCropStoCha[z in 1:Z, cs in eachindex(Crops), t in 1:T],
            MESS[:eFCropYield][z, cs, t] - MESS[:vFCropExportEq][z, cs, t]
        )
    else
        @expression(
            MESS,
            eFCropStoCha[z in 1:Z, cs in eachindex(Crops), t in 1:T],
            MESS[:eFCropYield][z, cs, t]
        )
    end
    ### End Expressions ###

    ### Constraints ###
    ## Restrict initial crop warehouse volume to a given level
    @constraint(
        MESS,
        cFCropStoVolumeLevelStart[z in 1:Z, cs in eachindex(Crops), t in START_SUBPERIODS],
        MESS[:vFCropStoVolume][z, cs, t] ==
        foodstuff_settings["InitialCropVolume"] * MESS[:vFCropStoVolumeCap][z, cs]
    )

    ## Volume stored for the next hour in interior time
    if foodstuff_settings["CropRotation"] == 1
        @expression(
            MESS,
            eFCropRotation[z in 1:Z, cs in eachindex(Crops), t in 1:T],
            if t in START_SUBPERIODS
                0.0
            else
                sum(
                    dfRotation[
                        (dfRotation.Zone .== Zones[z]) .& (dfRotation.Crop .== Crops[cs]),
                        :Crop_Rotation_Rate,
                    ],
                ) * MESS[:vFCropStoVolume][z, cs, t - 1]
            end
        )

        @constraint(
            MESS,
            cFCropStoVolumeLevelInterior[
                z in 1:Z,
                cs in eachindex(Crops),
                t in INTERIOR_SUBPERIODS,
            ],
            MESS[:vFCropStoVolume][z, cs, t] ==
            MESS[:vFCropStoVolume][z, cs, t - 1] - MESS[:vFCropStoDis][z, cs, t] +
            MESS[:eFCropStoCha][z, cs, t] - MESS[:eFCropRotation][z, cs, t]
        )
    else
        @constraint(
            MESS,
            cFCropStoVolumeLevelInterior[
                z in 1:Z,
                cs in eachindex(Crops),
                t in INTERIOR_SUBPERIODS,
            ],
            MESS[:vFCropStoVolume][z, cs, t] ==
            MESS[:vFCropStoVolume][z, cs, t - 1] - MESS[:vFCropStoDis][z, cs, t] +
            MESS[:eFCropStoCha][z, cs, t]
        )
    end

    ## Storage volume capacity
    ## TODO?: Consideration of crop storage settings
    @constraint(
        MESS,
        cFCropStoVolume[z in 1:Z, cs in eachindex(Crops), t in 1:T],
        MESS[:vFCropStoVolume][z, cs, t] <= MESS[:vFCropStoVolumeCap][z, cs]
    )

    ## Storage discharge
    @constraint(
        MESS,
        cFCropStoDis[z in 1:Z, cs in eachindex(Crops), t in 1:T],
        MESS[:vFCropStoDis][z, cs, t] <= MESS[:vFCropStoVolume][z, cs, t]
    )

    ## Storage charge
    @constraint(
        MESS,
        cFCropStoCha[z in 1:Z, cs in eachindex(Crops), t in 1:T],
        MESS[:eFCropStoCha][z, cs, t] <=
        MESS[:vFCropStoVolumeCap][z, cs] - MESS[:vFCropStoVolume][z, cs, t]
    )
    ### End Constraints ###

    return MESS
end
