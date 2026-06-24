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

    print_and_log(settings, "i", "Power Storage Energy Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]

    T = inputs["T"]
    weights = inputs["weights"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    ## Get power sector settings
    power_settings = settings["PowerSettings"]
    PReserve = power_settings["PReserve"]

    power_inputs = inputs["PowerInputs"]

    dfSto = power_inputs["dfSto"]
    S = power_inputs["S"]
    if PReserve == 1
        STO_PRSV = power_inputs["STO_PRSV"]
    end
    ResourceType = power_inputs["StoResourceType"]

    ### Variables ###
    ## Storage level of resource "s" at hour "t" [MWh] on zone "z"
    @variable(MESS, vPStoEneLevel[s in 1:S, t in 1:T] >= 0)

    ### Expressions ###
    ## Energy losses related to technologies (increase in effective demand)
    @expression(
        MESS,
        ePStoEneLossOS[s in 1:S],
        sum(weights[t] * MESS[:vPStoCha][s, t] for t in 1:T; init = 0.0) -
        sum(weights[t] * MESS[:vPStoDis][s, t] for t in 1:T; init = 0.0)
    )

    @expression(
        MESS,
        ePStoEneLossOZRT[z in 1:Z, rt in ResourceType],
        sum(
            MESS[:ePStoEneLossOS][s] for
            s in dfSto[(dfSto.Zone .== Zones[z]) .& (dfSto.Resource_Type .== rt), :R_ID];
            init = 0.0,
        )
    )

    ## For emission policy module
    @expression(
        MESS,
        ePStoEneLossOZ[z = 1:Z],
        sum(
            MESS[:ePStoEneLossOS][s] for s in intersect(1:S, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    @expression(
        MESS,
        ePStoEneLoss[z in 1:Z, t in 1:T],
        sum(
            MESS[:vPStoCha][s, t] - MESS[:vPStoDis][s, t] for
            s in intersect(1:S, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )
    ### End Expressions ###

    ### Constraints ###
    ## Storage energy capacity and state of charge related constraints:
    @constraint(
        MESS,
        cPStoEneLevel[s in 1:S, t in 1:T],
        MESS[:vPStoEneLevel][s, t] ==
        MESS[:vPStoEneLevel][s, BS1T[t]] -
        (1 / dfSto[!, :Eff_Discharge][s] * MESS[:vPStoDis][s, t]) +
        (dfSto[!, :Eff_Charge][s] * MESS[:vPStoCha][s, t]) -
        (dfSto[!, :Self_Discharge_Percentage][s] * MESS[:vPStoEneLevel][s, BS1T[t]])
    )

    ## Maximum energy stored must be less than energy capacity
    @constraint(
        MESS,
        cPStoMaxEneLevel[s in 1:S, t in 1:T],
        MESS[:vPStoEneLevel][s, t] <= MESS[:ePStoEneCap][s]
    )
    if PReserve == 1 && !isempty(STO_PRSV)
        ## Maximum discharging rate and contribution to reserves up must be less than power rating OR available stored energy in prior period, whichever is less
        ## wrapping from end of sample period to start of sample period for energy capacity constraint
        @constraint(
            MESS,
            cPStoMaxPrimaryReserveDis[s in STO_PRSV, t in 1:T],
            (MESS[:vPStoDis][s, t] + MESS[:vPStoDisPRSV][s, t]) / dfSto[!, :Eff_Discharge][s] <=
            MESS[:vPStoEneLevel][s, BS1T[t]]
        )
        ## Maximum charging rate plus contribution to regulation down must be less than available storage capacity
        @constraint(
            MESS,
            cPStoMaxPrimaryReserveCha[s in STO_PRSV, t in 1:T],
            (MESS[:vPStoCha][s, t] + MESS[:vPStoChaPRSV][s, t]) * dfSto[s, :Eff_Charge] <=
            MESS[:ePStoEneCap][s] - MESS[:vPStoEneLevel][s, BS1T[t]]
        )
    else
        ## Maximum discharging rate must be less than power rating OR available stored energy in prior period, whichever is less
        ## wrapping from end of sample period to start of sample period for energy capacity constraint
        @constraint(
            MESS,
            cPStoMaxEneDis[s in 1:S, t in 1:T],
            MESS[:vPStoDis][s, t] / dfSto[!, :Eff_Discharge][s] <= MESS[:vPStoEneLevel][s, BS1T[t]]
        )
        ## Maximum charging rate plus contribution to regulation down must be less than available storage capacity
        @constraint(
            MESS,
            cPStoMaxEneCha[s in 1:S, t in 1:T],
            MESS[:vPStoCha][s, t] * dfSto[s, :Eff_Charge] <=
            MESS[:ePStoEneCap][s] - MESS[:vPStoEneLevel][s, BS1T[t]]
        )
    end
    ### End Constraints ###

    return MESS
end
