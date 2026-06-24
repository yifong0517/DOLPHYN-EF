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
    generation_commit(inputs::Dict, MESS::Model)

"""
function generation_commit(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Generation Unit Commitment Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    ## Get power sector settings
    power_settings = settings["PowerSettings"]
    PReserve = power_settings["PReserve"]

    ## Get generators' data from dataframe
    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]

    ## Set of all resources eligible for new capacity and retirements
    NEW_GEN_CAP = power_inputs["NEW_GEN_CAP"]
    RET_GEN_CAP = power_inputs["RET_GEN_CAP"]
    COMMIT = power_inputs["COMMIT"]
    if PReserve == 1
        GEN_PRSV = power_inputs["GEN_PRSV"]
    end

    ### Expressions ###
    ## Objective Expressions ##
    ## Startup costs of "generation" for resource "g" during hour "t"
    @expression(
        MESS,
        ePObjVarStartOGT[g in COMMIT, t in 1:T],
        weights[t] *
        dfGen[!, :Cap_Size_MW][g] *
        dfGen[!, :Start_Cost_per_MW][g] *
        MESS[:vPStart][g, t]
    )
    @expression(
        MESS,
        ePObjVarStartOG[g in COMMIT],
        sum(MESS[:ePObjVarStartOGT][g, t] for t in 1:T; init = 0.0)
    )
    @expression(MESS, ePObjVarStart, sum(MESS[:ePObjVarStartOG][g] for g in COMMIT; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:ePObj], MESS[:ePObjVarStart])
    ## End Objective Expressions ##

    ## Startup fuel consumption of "generation" for resource "g" during time "t"
    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]

        @expression(
            MESS,
            ePFuelsConsumptionByStart[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vPGen][g, t] *
                dfGen[!, :Cap_Size_MW][g] *
                dfGen[!, :Start_Fuel_MMBTU_per_MW][g] for g in intersect(
                    dfGen[dfGen.Fuel .== Fuels_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                    COMMIT,
                );
                init = 0.0,
            )
        )

        ## Add fuel feedstock consumption
        add_to_expression!.(MESS[:ePFuelsConsumption], MESS[:ePFuelsConsumptionByStart])
    end

    ## Balance Expressions ##
    @expression(
        MESS,
        ePBalanceCommit[z in 1:Z, t in 1:T],
        sum(
            MESS[:vPGen][g, t] for g in intersect(COMMIT, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    ## Sub zonal commit generation expressions
    if power_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = power_inputs["SubZones"]
        ## Power sector sub zonal commit generation
        @expression(
            MESS,
            ePGenerationSubZonalCommit[z in SubZones, t in 1:T],
            sum(
                MESS[:vPGen][g, t] for g in intersect(COMMIT, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            )
        )
    end
    ### End Expressions ###

    ### Constraints ###
    ## Declaration of integer/binary variables
    if power_settings["UCommit"] == 1
        for g in COMMIT
            set_integer.(MESS[:vPOnline][g, :])
            set_integer.(MESS[:vPStart][g, :])
            set_integer.(MESS[:vPShut][g, :])
            if g in RET_GEN_CAP
                set_integer(MESS[:vPRetGenCap][g])
            end
            if g in NEW_GEN_CAP
                set_integer(MESS[:vPNewGenCap][g])
            end
        end
    end

    ## Capacitated limits on unit commitment decision variables (Constraints #1-3)
    @constraints(
        MESS,
        begin
            cPGenMaxOnline[g in COMMIT, t in 1:T],
            MESS[:vPOnline][g, t] <= MESS[:ePGenCap][g] / dfGen[!, :Cap_Size_MW][g]
            cPGenMaxStart[g in COMMIT, t in 1:T],
            MESS[:vPStart][g, t] <= MESS[:ePGenCap][g] / dfGen[!, :Cap_Size_MW][g]
            cPGenMaxShut[g in COMMIT, t in 1:T],
            MESS[:vPShut][g, t] <= MESS[:ePGenCap][g] / dfGen[!, :Cap_Size_MW][g]
        end
    )

    ## Commitment state constraint linking startup and shutdown decisions (Constraint #4)
    @constraint(
        MESS,
        cPGenOnlineStart[g in COMMIT, t in 1:T],
        MESS[:vPOnline][g, t] ==
        MESS[:vPOnline][g, BS1T[t]] + MESS[:vPStart][g, t] - MESS[:vPShut][g, t]
    )

    ## Maximum ramp up and down between consecutive hours (Constraints #5-6)
    ## Rampup constraints
    @constraint(
        MESS,
        cPGenMaxRampUpCommit[g in COMMIT, t in 1:T],
        MESS[:vPGen][g, t] - MESS[:vPGen][g, BS1T[t]] <=
        dfGen[!, :Ramp_Up_Percentage][g] *
        dfGen[!, :Cap_Size_MW][g] *
        (MESS[:vPOnline][g, t] - MESS[:vPStart][g, t]) +
        min(
            power_inputs["P_Max"][g, t],
            max(dfGen[!, :Min_Power][g], dfGen[!, :Ramp_Up_Percentage][g]),
        ) *
        dfGen[!, :Cap_Size_MW][g] *
        MESS[:vPStart][g, t] -
        dfGen[!, :Min_Power][g] * dfGen[!, :Cap_Size_MW][g] * MESS[:vPShut][g, t]
    )

    ## Rampdown constraints
    @constraint(
        MESS,
        cPGenMaxRampDnCommit[g in COMMIT, t in 1:T],
        MESS[:vPGen][g, BS1T[t]] - MESS[:vPGen][g, t] <=
        dfGen[!, :Ramp_Dn_Percentage][g] *
        dfGen[!, :Cap_Size_MW][g] *
        (MESS[:vPOnline][g, t] - MESS[:vPStart][g, t]) -
        dfGen[!, :Min_Power][g] * dfGen[!, :Cap_Size_MW][g] * MESS[:vPStart][g, t] +
        min(
            power_inputs["P_Max"][g, t],
            max(dfGen[!, :Min_Power][g], dfGen[!, :Ramp_Dn_Percentage][g]),
        ) *
        dfGen[!, :Cap_Size_MW][g] *
        MESS[:vPShut][g, t]
    )

    ### Minimum and maximum power output constraints (Constraints #7-8)
    ## Minimum stable power generated per technology "g" at hour "t" > Min power
    @constraint(
        MESS,
        cPGenMinPowerCommit[g in COMMIT, t in 1:T],
        MESS[:vPGen][g, t] >=
        dfGen[!, :Min_Power][g] * dfGen[!, :Cap_Size_MW][g] * MESS[:vPOnline][g, t]
    )

    ## Maximum power generated per technology "g" at hour "t" < Max power
    @constraint(
        MESS,
        cPGenMaxPowerCommit[g in COMMIT, t = 1:T],
        MESS[:vPGen][g, t] <=
        power_inputs["P_Max"][g, t] * dfGen[!, :Cap_Size_MW][g] * MESS[:vPOnline][g, t]
    )

    ## Minimum up and down times (Constraints #9-10)
    Up_Time = zeros(Int, size(dfGen, 1))
    Up_Time[COMMIT] .= Int.(floor.(dfGen[COMMIT, :Up_Time]))
    @constraint(
        MESS,
        cPGenRampUpCommit[g in COMMIT, t in 1:T],
        MESS[:vPOnline][g, t] >=
        sum(MESS[:vPStart][g, tau] for tau in hours_before(Period, t, 0:(Up_Time[g] - 1)))
    )

    Down_Time = zeros(Int, size(dfGen, 1))
    Down_Time[COMMIT] .= Int.(floor.(dfGen[COMMIT, :Down_Time]))
    @constraint(
        MESS,
        cPGenRampDnCommit[g in COMMIT, t in 1:T],
        MESS[:ePGenCap][g] / dfGen[g, :Cap_Size_MW] - MESS[:vPOnline][g, t] >=
        sum(MESS[:vPShut][g, tau] for tau in hours_before(Period, t, 0:(Down_Time[g] - 1)))
    )

    ## Primary reserve constraints for commit resources
    if PReserve == 1 && !isempty(intersect(COMMIT, GEN_PRSV))
        ## Maximum regulation and reserve contributions
        @constraint(
            MESS,
            cPGenPrimaryReserveCommit[g in intersect(COMMIT, GEN_PRSV), t = 1:T],
            MESS[:vPGenPRSV][g, t] <=
            power_inputs["P_Max"][g, t] *
            dfGen[!, :PRSV_Max][g] *
            dfGen[g, :Cap_Size_MW] *
            MESS[:vPOnline][g, t]
        )

        ## Minimum stable power generated per technology "y" at hour "t" and contribution to regulation must be > min power
        @constraint(
            MESS,
            cPGenMaxPrimaryReserveUpCommit[g in intersect(COMMIT, GEN_PRSV), t = 1:T],
            MESS[:vPGen][g, t] - MESS[:vPGenPRSV][g, t] >=
            dfGen[g, :Min_Power] * dfGen[g, :Cap_Size_MW] * MESS[:vPOnline][g, t]
        )

        ## Maximum power generated per technology "y" at hour "t" and contribution to regulation must be < max power
        @constraint(
            MESS,
            cPGenMaxPrimaryReserveDnCommit[g in intersect(COMMIT, GEN_PRSV), t = 1:T],
            MESS[:vPGen][g, t] + MESS[:vPGenPRSV][g, t] <=
            power_inputs["P_Max"][g, t] * dfGen[g, :Cap_Size] * MESS[:vPOnline][g, t]
        )
    end
    ### End Constraints ###

    return MESS
end
