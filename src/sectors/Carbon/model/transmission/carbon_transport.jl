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
function carbon_transport(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Carbon Sector Transport Flow Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    carbon_inputs = inputs["CarbonInputs"]
    dfRoute = carbon_inputs["dfRoute"]

    Transport_map = carbon_inputs["Transport_map"]
    TRANSPORT_ZONES = carbon_inputs["TRANSPORT_ZONES"]

    R = carbon_inputs["R"]

    ### Variables ###
    ## Transport flow volume [tonne] through at time "t" on zone "z"
    @variable(MESS, vCTransportFlow[z in TRANSPORT_ZONES, t = 1:T])
    @variable(MESS, vCTransportFlux[r in 1:R, d in [-1, 1], t = 1:T] >= 0)

    ### Expressions ###
    ## Objective Expressions ##
    @expression(
        MESS,
        eCObjTransportCostsORT[r in 1:R, t = 1:T],
        sum(
            1.6093 *
            MESS[:vCTransportFlux][r, d, t] *
            dfRoute[r, :Distance] *
            dfRoute[r, :Transport_Costs_per_ton_per_km] for d in [-1, 1]
        )
    )
    @expression(
        MESS,
        eCObjTransportCostsOR[r in 1:R],
        sum(weights[t] * MESS[:eCObjTransportCostsORT][r, t] for t in 1:T)
    )
    @expression(MESS, eCObjTransportCosts, sum(MESS[:eCObjTransportCostsOR][r] for r in 1:R))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eCObj], MESS[:eCObjTransportCosts])
    ## End Objective Expressions ##

    ## Balance Expressions ##
    ## Carbon balance
    @expression(
        MESS,
        eCBalanceTransportFlow[z = 1:Z, t = 1:T],
        begin
            if Zones[z] in TRANSPORT_ZONES
                MESS[:vCTransportFlow][Zones[z], t]
            else
                0
            end
        end
    )

    add_to_expression!.(MESS[:eCBalance], MESS[:eCBalanceTransportFlow])
    add_to_expression!.(MESS[:eCTransmission], MESS[:eCBalanceTransportFlow])
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###
    @constraint(
        MESS,
        cCTransportFlow[z in TRANSPORT_ZONES, t = 1:T],
        MESS[:vCTransportFlow][z, t] ==
        -sum(
            Transport_map[(Transport_map.Zone .== z) .& (Transport_map.route_no .== r), :d][1] *
            (MESS[:vCTransportFlux][r, 1, t] - MESS[:vCTransportFlux][r, -1, t]) *
            (1 - dfRoute[r, :Transport_Loss]) for
            r in Transport_map[Transport_map.Zone .== z, :route_no]
        ),
    )
    ### End Constraints ###

    return MESS
end
