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

    print_and_log(settings, "i", "Synfuels Generation No Unit Commitment Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    synfuels_settings = settings["SynfuelsSettings"]
    synfuels_inputs = inputs["SynfuelsInputs"]
    dfGen = synfuels_inputs["dfGen"]

    NO_COMMIT = synfuels_inputs["NO_COMMIT"]

    ### Expressions ###
    ## Balance Expressions ##
    @expression(
        MESS,
        eSBalanceThermNoCommit[z in 1:Z, t in 1:T],
        sum(
            MESS[:vSGen][g, t] for g in intersect(NO_COMMIT, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )
    ## End Balance Expressions ##
    ## Sub zonal no commit generation expressions
    if synfuels_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = synfuels_inputs["SubZones"]
        ## Synfuels sector sub zonal no commit generation
        @expression(
            MESS,
            eSGenerationSubZonalNoCommit[z in SubZones, t = 1:T],
            sum(
                MESS[:vSGen][g, t] for g in intersect(NO_COMMIT, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            ),
        )
    end
    ### End Expressions ###

    ### Constraints ###
    ## Maximum ramp up and down between consecutive hours (Constraints #1-2)
    if !isempty(intersect(NO_COMMIT, dfGen[dfGen.Ramp_Up_Percentage .< 1, :R_ID]))
        @constraint(
            MESS,
            cSGenMaxRampUpNoCommit[
                g in intersect(NO_COMMIT, dfGen[dfGen.Ramp_Up_Percentage .< 1, :R_ID]),
                t in 1:T,
            ],
            MESS[:vSGen][g, t] - MESS[:vSGen][g, BS1T[t]] <=
            dfGen[!, :Ramp_Up_Percentage][g] * MESS[:eSGenCap][g]
        )
    end

    ## Maximum ramp down between consecutive hours
    if !isempty(intersect(NO_COMMIT, dfGen[dfGen.Ramp_Dn_Percentage .< 1, :R_ID]))
        @constraint(
            MESS,
            cSGenMaxRampDnNoCommit[
                g in intersect(NO_COMMIT, dfGen[dfGen.Ramp_Dn_Percentage .< 1, :R_ID]),
                t in 1:T,
            ],
            MESS[:vSGen][g, BS1T[t]] - MESS[:vSGen][g, t] <=
            dfGen[!, :Ramp_Dn_Percentage][g] * MESS[:eSGenCap][g]
        )
    end

    ## Minimum stable synfuels generated per technology "g" at hour "t"
    if !isempty(intersect(NO_COMMIT, dfGen[dfGen.Min_Gen_Percentage .> 0, :R_ID]))
        @constraint(
            MESS,
            cSGenMinPowerNoCommit[
                g in intersect(NO_COMMIT, dfGen[dfGen.Min_Gen_Percentage .> 0, :R_ID]),
                t = 1:T,
            ],
            MESS[:vSGen][g, t] >= dfGen[!, :Min_Gen_Percentage][g] * MESS[:eSGenCap][g]
        )
    end

    ## Maximum synfuels generated per technology "g" at hour "t"
    @constraint(
        MESS,
        cSGenMaxPowerNoCommit[g in NO_COMMIT, t = 1:T],
        MESS[:vSGen][g, t] <= synfuels_inputs["P_Max"][g, t] * MESS[:eSGenCap][g]
    )
    ### End Constraints ###

    return MESS
end
