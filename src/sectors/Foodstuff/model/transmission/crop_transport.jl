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
function crop_transport(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Crop Transport Flow Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    foodstuff_inputs = inputs["FoodstuffInputs"]
    dfRoute = foodstuff_inputs["dfRoute"]

    Transport_map = foodstuff_inputs["Transport_map"]
    TRANSPORT_ZONES = foodstuff_inputs["TRANSPORT_ZONES"]

    R = foodstuff_inputs["R"]
    Crops = foodstuff_inputs["Crops"]

    ### Variables ###
    ## Transport flow volume [tonne] through at time "t" on zone "z" for crop "cs"
    @variable(MESS, vFCropFlow[z in TRANSPORT_ZONES, cs in eachindex(Crops), t = 1:T])
    @variable(MESS, vFCropFlux[r in 1:R, cs in eachindex(Crops), d in [-1, 1], t = 1:T] >= 0)

    ### Expressions ###
    ## Objective Expressions ##
    @expression(
        MESS,
        eFObjCropTransportCostsORT[r in 1:R, t = 1:T],
        sum(
            1.6093 *
            MESS[:vFCropFlux][r, cs, d, t] *
            dfRoute[r, :Distance] *
            dfRoute[r, :Crop_Transport_Costs_per_ton_per_km] for cs in eachindex(Crops),
            d in [-1, 1]
        )
    )
    @expression(
        MESS,
        eFObjCropTransportCostsOR[r in 1:R],
        sum(weights[t] * MESS[:eFObjCropTransportCostsORT][r, t] for t in 1:T)
    )
    @expression(
        MESS,
        eFObjCropTransportCosts,
        sum(MESS[:eFObjCropTransportCostsOR][r] for r in 1:R)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eFObj], MESS[:eFObjCropTransportCosts])
    ## End Objective Expressions ##

    ## Balance Expressions ##
    ## Foodstuff balance
    @expression(
        MESS,
        eFCropTransportFlow[z = 1:Z, cs in eachindex(Crops), t = 1:T],
        begin
            if Zones[z] in TRANSPORT_ZONES
                MESS[:vFCropFlow][Zones[z], cs, t]
            else
                0
            end
        end
    )
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###
    @constraint(
        MESS,
        cFCropFlow[z in TRANSPORT_ZONES, cs in eachindex(Crops), t = 1:T],
        MESS[:vFCropFlow][z, cs, t] ==
        -sum(
            Transport_map[(Transport_map.Zone .== z) .& (Transport_map.route_no .== r), :d][1] *
            (MESS[:vFCropFlux][r, cs, 1, t] - MESS[:vFCropFlux][r, cs, -1, t]) *
            (1 - dfRoute[r, :Crop_Transport_Loss]) for
            r in Transport_map[Transport_map.Zone .== z, :route_no]
        ),
    )
    ### End Constraints ###

    return MESS
end
