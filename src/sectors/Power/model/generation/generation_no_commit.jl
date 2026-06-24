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
function generation_no_commit(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Generation No Unit Commitment Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    ## Get power sector settings
    power_settings = settings["PowerSettings"]
    PReserve = power_settings["PReserve"]

    ## Get generators' data from dataframe
    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]

    NO_COMMIT = power_inputs["NO_COMMIT"]
    if PReserve == 1
        GEN_PRSV = power_inputs["GEN_PRSV"]
    end

    ### Expressions ###
    ## Balance Expressions ##
    @expression(
        MESS,
        ePBalanceNoCommit[z in 1:Z, t in 1:T],
        sum(
            MESS[:vPGen][g, t] for g in intersect(NO_COMMIT, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    ## Sub zonal no commit generation expressions
    if power_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = power_inputs["SubZones"]
        ## Power sector sub zonal no commit generation
        @expression(
            MESS,
            ePGenerationSubZonalNoCommit[z in SubZones, t in 1:T],
            sum(
                MESS[:vPGen][g, t] for g in intersect(NO_COMMIT, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            )
        )
    end
    ### End Expressions ###

    ### Constraints ###
    ## Maximum ramp up and down between consecutive hours (Constraints #1-2)
    @constraint(
        MESS,
        cPGenMaxRampUpNoCommit[g in NO_COMMIT, t in 1:T],
        MESS[:vPGen][g, t] - MESS[:vPGen][g, BS1T[t]] <=
        dfGen[!, :Ramp_Up_Percentage][g] * MESS[:ePGenCap][g]
    )

    ## Maximum ramp down between consecutive hours
    @constraint(
        MESS,
        cPGenMaxRampDnNoCommit[g in NO_COMMIT, t in 1:T],
        MESS[:vPGen][g, BS1T[t]] - MESS[:vPGen][g, t] <=
        dfGen[!, :Ramp_Dn_Percentage][g] * MESS[:ePGenCap][g]
    )

    ## Minimum stable power generated per technology "g" at hour "t" Min_Power
    @constraint(
        MESS,
        cPGenMinPowerNoCommit[g in NO_COMMIT, t = 1:T],
        MESS[:vPGen][g, t] >= dfGen[!, :Min_Power][g] * MESS[:ePGenCap][g]
    )

    ## Maximum power generated per technology "g" at hour "t"
    @constraint(
        MESS,
        cPGenMaxPowerNoCommit[g in NO_COMMIT, t = 1:T],
        MESS[:vPGen][g, t] <= power_inputs["P_Max"][g, t] * MESS[:ePGenCap][g]
    )

    ## Primary reserve constraints for commit resources
    if PReserve == 1 && !isempty(intersect(NO_COMMIT, GEN_PRSV))
        ## Maximum regulation and reserve contributions
        @constraint(
            MESS,
            cPGenPrimaryReserveNoCommit[g in intersect(NO_COMMIT, GEN_PRSV), t = 1:T],
            MESS[:vPGenPRSV][g, t] <=
            power_inputs["P_Max"][g, t] * dfGen[!, :PRSV_Max][g] * MESS[:ePGenCap][g]
        )

        ## Minimum stable power generated per technology "y" at hour "t" and contribution to regulation must be > min power
        @constraint(
            MESS,
            cPGenMaxPrimaryReserveUpNoCommit[g in intersect(NO_COMMIT, GEN_PRSV), t = 1:T],
            MESS[:vPGen][g, t] - MESS[:vPGenPRSV][g, t] >=
            dfGen[g, :Min_Power] * MESS[:ePGenCap][g]
        )

        ## Maximum power generated per technology "y" at hour "t" and contribution to regulation must be < max power
        @constraint(
            MESS,
            cPGenMaxPrimaryReserveDnNoCommit[g in intersect(NO_COMMIT, GEN_PRSV), t = 1:T],
            MESS[:vPGen][g, t] + MESS[:vPGenPRSV][g, t] <=
            power_inputs["P_Max"][g, t] * MESS[:ePGenCap][g]
        )
    end
    ### End Constraints ###

    return MESS
end
