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
function capture_no_commit(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Carbon Capture Direct Air No Unit Commitment Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    carbon_settings = settings["CarbonSettings"]
    carbon_inputs = inputs["CarbonInputs"]
    dfGen = carbon_inputs["dfGen"]

    NO_COMMIT = carbon_inputs["NO_COMMIT"]

    ### Expressions ###
    ## Balance Expressions ##
    @expression(
        MESS,
        eCBalanceNoCommit[z in 1:Z, t in 1:T],
        sum(
            MESS[:vCCap][g, t] for g in intersect(NO_COMMIT, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    ## Sub zonal no commit capture expressions
    if carbon_settings["SubZone"] == 1
        SubZones = carbon_inputs["SubZones"]
        ## Carbon sector sub zonal no commit capture
        @expression(
            MESS,
            eCCaptureSubZonalNoCommit[z in SubZones, t = 1:T],
            sum(
                MESS[:vCCap][g, t] for g in intersect(NO_COMMIT, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            ),
        )
    end
    ### End Expressions ###

    ### Constraints ###
    ## Maximum ramp up and down between consecutive hours (Constraints #1-2)
    @constraint(
        MESS,
        cCCaptureMaxRampUpNoCommit[g in NO_COMMIT, t in 1:T],
        MESS[:vCCap][g, t] - MESS[:vCCap][g, BS1T[t]] <=
        dfGen[!, :Ramp_Up_Percentage][g] * MESS[:eCCaptureCap][g]
    )

    ## Maximum ramp down between consecutive hours
    @constraint(
        MESS,
        cCCaptureMaxRampDnNoCommit[g in NO_COMMIT, t in 1:T],
        MESS[:vCCap][g, BS1T[t]] - MESS[:vCCap][g, t] <=
        dfGen[!, :Ramp_Dn_Percentage][g] * MESS[:eCCaptureCap][g]
    )

    ## Minimum stable power generated per technology "g" at hour "t"
    @constraint(
        MESS,
        cCCaptureMinPowerNoCommit[g in NO_COMMIT, t = 1:T],
        MESS[:vCCap][g, t] >= dfGen[!, :Min_Cap_Percentage][g] * MESS[:eCCaptureCap][g]
    )

    ## Maximum power generated per technology "g" at hour "t"
    @constraint(
        MESS,
        cCCaptureMaxPowerNoCommit[g in NO_COMMIT, t = 1:T],
        MESS[:vCCap][g, t] <= carbon_inputs["P_Max"][g, t] * MESS[:eCCaptureCap][g]
    )
    ### End Constraints ###

    return MESS
end
