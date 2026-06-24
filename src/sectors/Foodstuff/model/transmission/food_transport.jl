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

@doc """

"""
function food_transport(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Food Transport Flow Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    foodstuff_inputs = inputs["FoodstuffInputs"]
    dfRoute = foodstuff_inputs["dfRoute"]

    Transport_map = foodstuff_inputs["Transport_map"]
    TRANSPORT_ZONES = foodstuff_inputs["TRANSPORT_ZONES"]

    R = foodstuff_inputs["R"]
    Foods = foodstuff_inputs["Foods"]

    ### Variables ###
    ## Transport flow volume [tonne] through at time "t" on zone "z" for food "fs"
    @variable(MESS, vFBalanceFoodFlow[z in TRANSPORT_ZONES, fs in eachindex(Foods), t = 1:T])
    @variable(MESS, vFFoodFlux[r in 1:R, fs in eachindex(Foods), d in [-1, 1], t = 1:T] >= 0)

    ### Expressions ###
    ## Objective Expressions ##
    @expression(
        MESS,
        eFObjFoodTransportCostsORT[r in 1:R, t = 1:T],
        sum(
            1.6093 *
            MESS[:vFFoodFlux][r, fs, d, t] *
            dfRoute[r, :Distance] *
            dfRoute[r, :Food_Transport_Costs_per_ton_per_km] for fs in eachindex(Foods),
            d in [-1, 1]
        )
    )
    @expression(
        MESS,
        eFObjFoodTransportCostsOR[r in 1:R],
        sum(weights[t] * MESS[:eFObjFoodTransportCostsORT][r, t] for t in 1:T)
    )
    @expression(
        MESS,
        eFObjFoodTransportCosts,
        sum(MESS[:eFObjFoodTransportCostsOR][r] for r in 1:R)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eFObj], MESS[:eFObjFoodTransportCosts])
    ## End Objective Expressions ##

    ## Balance Expressions ##
    ## Foodstuff balance
    @expression(
        MESS,
        eFBalanceTransportFlow[z = 1:Z, fs in eachindex(Foods), t = 1:T],
        begin
            if Zones[z] in TRANSPORT_ZONES
                MESS[:vFBalanceFoodFlow][Zones[z], fs, t]
            else
                0
            end
        end
    )

    add_to_expression!.(MESS[:eFBalance], MESS[:eFBalanceTransportFlow])
    add_to_expression!.(MESS[:eFTransmission], MESS[:eFBalanceTransportFlow])
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###
    @constraint(
        MESS,
        cFFoodFlow[z in TRANSPORT_ZONES, fs in eachindex(Foods), t = 1:T],
        MESS[:vFBalanceFoodFlow][z, fs, t] ==
        -sum(
            Transport_map[(Transport_map.Zone .== z) .& (Transport_map.route_no .== r), :d][1] *
            (MESS[:vFFoodFlux][r, fs, 1, t] - MESS[:vFFoodFlux][r, fs, -1, t]) for
            r in Transport_map[Transport_map.Zone .== z, :route_no]
        ),
    )
    ### End Constraints ###

    return MESS
end
