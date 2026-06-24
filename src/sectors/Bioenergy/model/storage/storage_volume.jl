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
function storage_volume(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Bioenergy Storage Volume Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    START_SUBPERIODS = inputs["START_SUBPERIODS"]
    INTERIOR_SUBPERIODS = inputs["INTERIOR_SUBPERIODS"]

    bioenergy_inputs = inputs["BioenergyInputs"]
    bioenergy_settings = settings["BioenergySettings"]

    Residuals = bioenergy_inputs["Residuals"]

    dfSto = bioenergy_inputs["dfSto"]
    S = bioenergy_inputs["S"]

    ### Variables ###
    ## Storage discharge of resource "s" at hour "t" [tonne] on zone "z"
    @variable(MESS, vBStoDis[s in 1:S, t in 1:T] >= 0)
    ## Storage charge of resource "s" at hour "t" [tonne] on zone "z"
    @variable(MESS, vBStoCha[s in 1:S, t in 1:T] >= 0)
    ## Storage level of resource "s" at hour "t" [tonne] on zone "z"
    @variable(MESS, vBStoVolume[s in 1:S, t in 1:T] >= 0)

    ### Expressions ###
    ## Term to represent net dispatch from storage in any period
    @expression(
        MESS,
        eBBalanceStoDis[z in 1:Z, rs in eachindex(Residuals), t in 1:T],
        sum(
            MESS[:vBStoDis][s, t] for s in intersect(
                1:S,
                dfSto[dfSto.Zone .== Zones[z], :R_ID],
                dfSto[dfSto.Residual .== Residuals[rs], :R_ID],
            );
            init = 0.0,
        )
    )

    @expression(
        MESS,
        eBBalanceStoCha[z in 1:Z, rs in eachindex(Residuals), t in 1:T],
        sum(
            -MESS[:vBStoCha][s, t] for s in intersect(
                1:S,
                dfSto[dfSto.Zone .== Zones[z], :R_ID],
                dfSto[dfSto.Residual .== Residuals[rs], :R_ID],
            );
            init = 0.0,
        )
    )

    @expression(
        MESS,
        eBBalanceSto[z in 1:Z, rs in eachindex(Residuals), t in 1:T],
        sum(
            MESS[:vBStoDis][s, t] - MESS[:vBStoCha][s, t] for s in intersect(
                1:S,
                dfSto[dfSto.Zone .== Zones[z], :R_ID],
                dfSto[dfSto.Residual .== Residuals[rs], :R_ID],
            );
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:eBBalance], MESS[:eBBalanceSto])
    ### End Expressions ###

    ### Constraints ###
    ## Storage energy capacity and state of charge related constraints:
    ## Links state of charge in every time step with decisions in one time step before
    @constraint(
        MESS,
        cBStoVolumeLevelStart[s in 1:S, t in START_SUBPERIODS],
        MESS[:vBStoVolume][s, t] ==
        bioenergy_settings["InitialBioVolume"] * MESS[:eBStoVolumeCap][s]
    )

    ## Volume stored for the next hour in interior time
    @constraint(
        MESS,
        cBStoVolumeLevelInterior[s in 1:S, t in INTERIOR_SUBPERIODS],
        MESS[:vBStoVolume][s, t] ==
        MESS[:vBStoVolume][s, t - 1] - MESS[:vBStoDis][s, t] + MESS[:vBStoCha][s, t] -
        (dfSto[!, :Self_Discharge_Percentage][s] * MESS[:vBStoVolume][s, t - 1])
    )

    ## Maximum energy stored must be less than energy capacity
    @constraint(
        MESS,
        cBStoMaxVolumeLevel[s in 1:S, t in 1:T],
        MESS[:vBStoVolume][s, t] <= MESS[:vBNewStoVolumeCap][s]
    )

    ## Maximum discharging rate must be less than power rating OR available stored energy in prior period, whichever is less
    @constraint(
        MESS,
        cBStoMaxVolumeDis[s in 1:S, t in 1:T],
        MESS[:vBStoDis][s, t] <= MESS[:vBStoVolume][s, BS1T[t]]
    )
    ## Maximum charging rate plus contribution to regulation down must be less than available storage capacity
    @constraint(
        MESS,
        cBStoMaxVolumeCha[s in 1:S, t in 1:T],
        MESS[:vBStoCha][s, t] <= MESS[:eBStoVolumeCap][s] - MESS[:vBStoVolume][s, BS1T[t]]
    )
    ### End Constraints ###

    return MESS
end
