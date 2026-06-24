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
function food_warehouse_volume(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Sector Foods Warehouse Volume Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]

    Period = inputs["Period"]

    foodstuff_settings = settings["FoodstuffSettings"]
    foodstuff_inputs = inputs["FoodstuffInputs"]

    dfFood = foodstuff_inputs["dfFood"]
    Foods = foodstuff_inputs["Foods"]
    dfSto = foodstuff_inputs["dfSto"]
    S = foodstuff_inputs["S"]

    ### Variables ###
    ## Storage discharge of resource "s" at hour "t" [tonne] on zone "z"
    @variable(MESS, vFFoodStoDis[s in 1:S, t in 1:T] >= 0)
    ## Storage charge of resource "s" at hour "t" [tonne] on zone "z"
    @variable(MESS, vFFoodStoCha[s in 1:S, t in 1:T] >= 0)
    ## Storage level of resource "s" at hour "t" [tonne] on zone "z"
    @variable(MESS, vFFoodStoVolume[s in 1:S, t in 1:T] >= 0)

    ### Expressions ###
    ## Term to represent net dispatch from storage in any period
    @expression(
        MESS,
        eFFoodBalanceStoDis[z in 1:Z, fs in eachindex(Foods), t in 1:T],
        sum(
            MESS[:vFFoodStoDis][s, t] for s in intersect(
                1:S,
                dfSto[dfSto.Zone .== Zones[z], :R_ID],
                dfSto[dfSto.Food .== Foods[fs], :R_ID],
            );
            init = 0.0,
        )
    )

    @expression(
        MESS,
        eFFoodBalanceStoCha[z in 1:Z, fs in eachindex(Foods), t in 1:T],
        sum(
            -MESS[:vFFoodStoCha][s, t] for s in intersect(
                1:S,
                dfSto[dfSto.Zone .== Zones[z], :R_ID],
                dfSto[dfSto.Food .== Foods[fs], :R_ID],
            );
            init = 0.0,
        )
    )

    @expression(
        MESS,
        eFFoodBalanceSto[z in 1:Z, fs in eachindex(Foods), t in 1:T],
        sum(
            MESS[:vFFoodStoDis][s, t] - MESS[:vFFoodStoCha][s, t] for s in intersect(
                1:S,
                dfSto[dfSto.Zone .== Zones[z], :R_ID],
                dfSto[dfSto.Food .== Foods[fs], :R_ID],
            );
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:eFBalance], MESS[:eFFoodBalanceSto])
    ### End Expressions ###

    ### Constraints ###
    ## Restrict initial food warehouse volume to a given level
    @constraint(
        MESS,
        cFFoodStoVolumeLevelStart[s in 1:S, t in START_SUBPERIODS],
        MESS[:vFFoodStoVolume][s, t] ==
        foodstuff_settings["InitialFoodVolume"] * MESS[:eFFoodStoVolumeCap][s]
    )

    ## Volume stored for the next hour in interior time
    @constraint(
        MESS,
        cFFoodStoVolumeLevelInterior[s in 1:S, t in INTERIOR_SUBPERIODS],
        MESS[:vFFoodStoVolume][s, t] ==
        MESS[:vFFoodStoVolume][s, t - 1] - MESS[:vFFoodStoDis][s, t] + MESS[:vFFoodStoCha][s, t] -
        (dfSto[!, :Self_Discharge_Percentage][s] * MESS[:vFFoodStoVolume][s, t - 1])
    )

    ## Maximum food stored must be less than food capacity
    ## TODO?: Consideration of food storage settings
    @constraint(
        MESS,
        cFFoodStoMaxVolumeLevel[s in 1:S, t in 1:T],
        MESS[:vFFoodStoVolume][s, t] <= MESS[:eFFoodStoVolumeCap][s]
    )

    ## Maximum discharging rate must be less than power rating OR available stored food in prior period, whichever is less
    @constraint(
        MESS,
        cFStoMaxVolumeDis[s in 1:S, t in 1:T],
        MESS[:vFFoodStoDis][s, t] <= MESS[:vFFoodStoVolume][s, BS1T[t]]
    )

    ## Maximum charging rate plus contribution to regulation down must be less than available storage capacity
    @constraint(
        MESS,
        cFStoMaxVolumeCha[s in 1:S, t in 1:T],
        MESS[:vFFoodStoCha][s, t] <=
        MESS[:eFFoodStoVolumeCap][s] - MESS[:vFFoodStoVolume][s, BS1T[t]]
    )
    ### End Constraints ###

    return MESS
end
