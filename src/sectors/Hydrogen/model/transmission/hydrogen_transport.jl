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
function hydrogen_transport(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Hydrogen Sector Transport Flow Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    hydrogen_inputs = inputs["HydrogenInputs"]
    dfRoute = hydrogen_inputs["dfRoute"]

    Transport_map = hydrogen_inputs["Transport_map"]
    TRANSPORT_ZONES = hydrogen_inputs["TRANSPORT_ZONES"]

    R = hydrogen_inputs["R"]

    ### Variables ###
    ## Transport flow volume [tonne] through at time "t" on zone "z"
    @variable(MESS, vHTransportFlow[z in TRANSPORT_ZONES, t = 1:T])
    @variable(MESS, vHTransportFlux[r in 1:R, d in [-1, 1], t = 1:T] >= 0)

    ### Expressions ###
    ## Objective Expressions ##
    @expression(
        MESS,
        eHObjTransportCostsORT[r in 1:R, t = 1:T],
        sum(
            1.6093 *
            MESS[:vHTransportFlux][r, d, t] *
            dfRoute[r, :Distance] *
            dfRoute[r, :Transport_Costs_per_ton_per_km] for d in [-1, 1]
        )
    )
    @expression(
        MESS,
        eHObjTransportCostsOR[r in 1:R],
        sum(weights[t] * MESS[:eHObjTransportCostsORT][r, t] for t in 1:T)
    )
    @expression(MESS, eHObjTransportCosts, sum(MESS[:eHObjTransportCostsOR][r] for r in 1:R))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eHObj], MESS[:eHObjTransportCosts])
    ## End Objective Expressions ##

    ## Balance Expressions ##
    ## Hydrogen balance
    @expression(
        MESS,
        eHBalanceTransportFlow[z = 1:Z, t = 1:T],
        begin
            if Zones[z] in TRANSPORT_ZONES
                MESS[:vHTransportFlow][Zones[z], t]
            else
                0
            end
        end
    )

    add_to_expression!.(MESS[:eHBalance], MESS[:eHBalanceTransportFlow])
    add_to_expression!.(MESS[:eHTransmission], MESS[:eHBalanceTransportFlow])
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###
    @constraint(
        MESS,
        cHTransportFlow[z in TRANSPORT_ZONES, t = 1:T],
        MESS[:vHTransportFlow][z, t] ==
        -sum(
            Transport_map[(Transport_map.Zone .== z) .& (Transport_map.route_no .== r), :d][1] *
            (MESS[:vHTransportFlux][r, 1, t] - MESS[:vHTransportFlux][r, -1, t]) *
            (1 - dfRoute[r, :Transport_Loss]) for
            r in Transport_map[Transport_map.Zone .== z, :route_no]
        ),
    )
    ### End Constraints ###

    return MESS
end
