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
function storage_energy(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Hydrogen Storage Energy Module")

    Z = inputs["Z"] # Number of zones
    Zones = inputs["Zones"] # List of modeled zones

    T = inputs["T"] # Number of time steps (hours)
    weights = inputs["weights"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    hydrogen_inputs = inputs["HydrogenInputs"]

    dfSto = hydrogen_inputs["dfSto"]
    S = hydrogen_inputs["S"]
    ResourceType = hydrogen_inputs["StoResourceType"]

    ### Variables ###
    ## Storage level of resource "s" at hour "t" [tonne] on zone "z"
    @variable(MESS, vHStoEneLevel[s in 1:S, t in 1:T] >= 0)

    ### Expressions ###
    ## Energy losses related to technologies (increase in effective demand)
    @expression(
        MESS,
        eHStoEneLossOS[s in 1:S],
        sum(weights[t] * MESS[:vHStoCha][s, t] for t in 1:T; init = 0.0) -
        sum(weights[t] * MESS[:vHStoDis][s, t] for t in 1:T; init = 0.0)
    )

    @expression(
        MESS,
        eHStoEneLossOZRT[z in 1:Z, rt in ResourceType],
        sum(
            MESS[:eHStoEneLossOS][s] for
            s in dfSto[(dfSto.Zone .== Zones[z]) .& (dfSto.Resource_Type .== rt), :R_ID];
            init = 0.0,
        )
    )
    ## For emission policy module
    @expression(
        MESS,
        eHStoEneLossOZ[z = 1:Z],
        sum(
            MESS[:eHStoEneLossOS][s] for s in intersect(1:S, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    @expression(
        MESS,
        eHStoEneLoss[z in 1:Z, t in 1:T],
        sum(
            MESS[:vHStoCha][s, t] - MESS[:vHStoDis][s, t] for
            s in intersect(1:S, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )
    ### End Expressions ###

    ### Constraints ###
    ## Storage energy capacity and state of charge related constraints:
    @constraint(
        MESS,
        cHStoEneLevel[s in 1:S, t in 1:T],
        MESS[:vHStoEneLevel][s, t] ==
        MESS[:vHStoEneLevel][s, BS1T[t]] -
        (1 / dfSto[!, :Eff_Discharge][s] * MESS[:vHStoDis][s, t]) +
        (dfSto[!, :Eff_Charge][s] * MESS[:vHStoCha][s, t]) -
        (dfSto[!, :Self_Discharge_Percentage][s] * MESS[:vHStoEneLevel][s, BS1T[t]])
    )

    ## Maximum energy stored must be less than energy capacity
    @constraint(
        MESS,
        cHStoMaxEneLevel[s in 1:S, t in 1:T],
        MESS[:vHStoEneLevel][s, t] <= MESS[:eHStoEneCap][s]
    )

    ## Maximum discharging rate must be less than power rating OR available stored energy in prior period, whichever is less
    @constraint(
        MESS,
        cHStoMaxEneDis[s in 1:S, t in 1:T],
        MESS[:vHStoDis][s, t] / dfSto[!, :Eff_Discharge][s] <= MESS[:vHStoEneLevel][s, BS1T[t]]
    )

    ## Maximum charging rate plus contribution to regulation down must be less than available storage capacity
    @constraint(
        MESS,
        cHStoMaxEneCha[s in 1:S, t in 1:T],
        MESS[:vHStoCha][s, t] * dfSto[s, :Eff_Charge] <=
        MESS[:eHStoEneCap][s] - MESS[:vHStoEneLevel][s, BS1T[t]]
    )
    ### End Constraints ###

    return MESS
end
