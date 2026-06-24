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

    print_and_log(settings, "i", "Carbon Storage Energy Module")

    carbon_settings = settings["CarbonSettings"]

    ## Flags
    AllowDis = carbon_settings["AllowDis"]

    Z = inputs["Z"]
    Zones = inputs["Zones"]

    T = inputs["T"]
    weights = inputs["weights"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    carbon_inputs = inputs["CarbonInputs"]

    dfSto = carbon_inputs["dfSto"]
    S = carbon_inputs["S"]
    ResourceType = carbon_inputs["StoResourceType"]

    ### Variables ###
    ## Storage level of resource "s" at hour "t" [tonne] on zone "z"
    @variable(MESS, vCStoEneLevel[s in 1:S, t in 1:T] >= 0)

    ### Expressions ###
    if AllowDis == 1
        # Carbon losses related to technologies (increase in effective demand)
        @expression(
            MESS,
            eCStoEneLossOS[s in 1:S],
            sum(weights[t] * MESS[:vCStoCha][s, t] for t in 1:T; init = 0.0) -
            sum(weights[t] * MESS[:vCStoDis][s, t] for t in 1:T; init = 0.0)
        )

        @expression(
            MESS,
            eCStoEneLossOZRT[z in 1:Z, rt in ResourceType],
            sum(
                MESS[:eCStoEneLossOS][s] for
                s in dfSto[(dfSto.Zone .== Zones[z]) .& (dfSto.Resource_Type .== rt), :R_ID];
                init = 0.0,
            )
        )
        ## For emission policy module
        @expression(
            MESS,
            eCStoEneLossOZ[z = 1:Z],
            sum(
                MESS[:eCStoEneLossOS][s] for
                s in intersect(1:S, dfSto[dfSto[!, :Zone] .== Zones[z], :R_ID]);
                init = 0.0,
            )
        )

        @expression(
            MESS,
            eCStoEneLoss[z in 1:Z, t in 1:T],
            sum(
                MESS[:vCStoCha][s, t] - MESS[:vCStoDis][s, t] for
                s in intersect(1:S, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
                init = 0.0,
            )
        )
    end
    ### End Expressions ###

    ### Constraints ###
    if AllowDis == 1
        ## Storage energy capacity and state of charge related constraints:

        ## Links state of charge in first time step with decisions in last time step of each subperiod
        @constraint(
            MESS,
            cCStoEneLevel[s in 1:S, t in 1:T],
            MESS[:vCStoEneLevel][s, t] ==
            MESS[:vCStoEneLevel][s, BS1T[t]] -
            (1 / dfSto[!, :Eff_Discharge][s] * MESS[:vCStoDis][s, t]) +
            (dfSto[!, :Eff_Charge][s] * MESS[:vCStoCha][s, t]) -
            (dfSto[!, :Self_Discharge_Percentage][s] * MESS[:vCStoEneLevel][s, BS1T[t]])
        )

        ## Maximum carbon stored must be less than energy capacity
        @constraint(
            MESS,
            cCStoMaxEneLevel[s in 1:S, t in 1:T],
            MESS[:vCStoEneLevel][s, t] <= MESS[:eCStoEneCap][s]
        )

        ## Maximum discharging rate must be less than power rating OR available stored energy in prior period, whichever is less
        @constraint(
            MESS,
            cCStoMaxEneDis[s in 1:S, t in 1:T],
            MESS[:vCStoDis][s, t] / dfSto[!, :Eff_Discharge][s] <= MESS[:vCStoEneLevel][s, BS1T[t]]
        )
        ## Maximum charging rate plus contribution to regulation down must be less than available storage capacity
        @constraint(
            MESS,
            cCStoMaxEneCha[s in 1:S, t in 1:T],
            MESS[:vCStoCha][s, t] * dfSto[s, :Eff_Charge] <=
            MESS[:eCStoEneCap][s] - MESS[:vCStoEneLevel][s, BS1T[t]]
        )
    else
        ## Force carbon storage level in first time step to be zero
        @constraint(MESS, cCStoEneLevel[s in 1:S, t = 1], MESS[:vCStoEneLevel][s, t] == 0.0)
        ## Energy stored for the next hour in interior time
        @constraint(
            MESS,
            cCStoEneLevelInterior[s in 1:S, t in 2:T],
            MESS[:vCStoEneLevel][s, t] ==
            MESS[:vCStoEneLevel][s, t - 1] + (dfSto[!, :Eff_Charge][s] * MESS[:vCStoCha][s, t]) -
            (dfSto[!, :Self_Discharge_Percentage][s] * MESS[:vCStoEneLevel][s, t - 1])
        )

        ## Annuitized charged carbon amount should not excess energy capacity
        @constraint(
            MESS,
            cCStoMaxEneLevel[s in 1:S],
            sum(weights[t] * dfSto[!, :Eff_Charge][s] * MESS[:vCStoCha][s, t] for t in 1:T) <=
            MESS[:eCStoEneCap][s]
        )
    end
    ### End Constraints ###

    return MESS
end
