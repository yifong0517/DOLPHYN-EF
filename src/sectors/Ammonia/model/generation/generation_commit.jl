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
    generation_commit(settings::Dict, inputs::Dict, MESS::Model)

"""
function generation_commit(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Ammonia Generation Unit Commitment Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    ammonia_settings = settings["AmmoniaSettings"]
    ammonia_inputs = inputs["AmmoniaInputs"]
    dfGen = ammonia_inputs["dfGen"]

    ## Set of all resources eligible for new capacity and retirements
    NEW_GEN_CAP = ammonia_inputs["NEW_GEN_CAP"]
    RET_GEN_CAP = ammonia_inputs["RET_GEN_CAP"]
    COMMIT = ammonia_inputs["COMMIT"]

    ### Expressions ###
    ## Objective Expressions ##
    ## Startup costs of "generation" for resource "g" during hour "t"
    @expression(
        MESS,
        eAObjVarStartOGT[g in COMMIT, t in 1:T],
        weights[t] *
        dfGen[!, :Start_Cost_per_tonne_per_hr][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vAStart][g, t]
    )

    ## Add total variable startup cost contribution to objective function
    @expression(MESS, eAObjVarStartOG[g in COMMIT], sum(MESS[:eAObjVarStartOGT][g, t] for t in 1:T))
    @expression(MESS, eAObjVarStart, sum(MESS[:eAObjVarStartOG][g] for g in COMMIT))
    add_to_expression!(MESS[:eAObj], MESS[:eAObjVarStart])

    ## Startup fuel consumption of "generation" for resource "g" during time "t"
    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]
        @expression(
            MESS,
            eAFuelsConsumptionByStart[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vAGen][g, t] *
                dfGen[!, :Cap_Size_tonne_per_hr][g] *
                dfGen[!, :Start_Cost_per_tonne_per_hr][g] for g in intersect(
                    dfGen[dfGen.Fuel .== Fuels_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                    COMMIT,
                );
                init = 0.0,
            )
        )

        ## Add fuel feedstock consumption
        add_to_expression!.(MESS[:eAFuelsConsumption], MESS[:eAFuelsConsumptionByStart])
    end

    ## Balance Expressions ##
    @expression(
        MESS,
        eABalanceThermCommit[z in 1:Z, t in 1:T],
        sum(
            MESS[:vAGen][g, t] for g in intersect(COMMIT, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    ## Sub zonal commit generation expressions
    if ammonia_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = ammonia_inputs["SubZones"]
        ## Ammonia sector sub zonal commit generation
        @expression(
            MESS,
            eAGenerationSubZonalCommit[z in SubZones, t = 1:T],
            sum(
                MESS[:vAGen][g, t] for g in intersect(COMMIT, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            ),
        )
    end
    ### End Expressions ###

    ### Constraints ###
    ## Declaration of integer/binary variables
    if ammonia_settings["GenCommit"] == 1
        for g in COMMIT
            set_integer.(MESS[:vAOnline][g, :])
            set_integer.(MESS[:vAStart][g, :])
            set_integer.(MESS[:vAShut][g, :])
            if g in RET_GEN_CAP
                set_integer(MESS[:vARetCap][g])
            end
            if g in NEW_GEN_CAP
                set_integer(MESS[:vANewCAP][g])
            end
        end
    end

    ## Capacitated limits on unit commitment decision variables (Constraints #1-3)
    @constraints(
        MESS,
        begin
            cAGenMaxOnline[g in COMMIT, t in 1:T],
            MESS[:vAOnline][g, t] <= MESS[:eAGenCap][g] / dfGen[!, :Cap_Size_tonne_per_hr][g]
            cAGenMaxStart[g in COMMIT, t in 1:T],
            MESS[:vAStart][g, t] <= MESS[:eAGenCap][g] / dfGen[!, :Cap_Size_tonne_per_hr][g]
            cAGenMaxShut[g in COMMIT, t in 1:T],
            MESS[:vAShut][g, t] <= MESS[:eAGenCap][g] / dfGen[!, :Cap_Size_tonne_per_hr][g]
        end
    )

    ## Commitment state constraint linking startup and shutdown decisions (Constraint #4)
    @constraint(
        MESS,
        cAGenOnline[g in COMMIT, t in 1:T],
        MESS[:vAOnline][g, t] ==
        MESS[:vAOnline][g, BS1T[t]] + MESS[:vAStart][g, t] - MESS[:vAShut][g, t]
    )

    ## Maximum ramp up and down between consecutive hours (Constraints #5-6)
    ## Rampup constraints
    @constraint(
        MESS,
        cAGenMaxRampUpCommit[g in COMMIT, t in 1:T],
        MESS[:vAGen][g, t] - MESS[:vAGen][g, BS1T[t]] <=
        dfGen[!, :Ramp_Up_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        (MESS[:vAOnline][g, t] - MESS[:vAStart][g, t]) +
        min(
            ammonia_inputs["P_Max"][g, t],
            max(dfGen[!, :Min_Gen_Percentage][g], dfGen[!, :Ramp_Up_Percentage][g]),
        ) *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vAStart][g, t] -
        dfGen[!, :Min_Gen_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vAShut][g, t]
    )

    ## Rampdown constraints
    @constraint(
        MESS,
        cAGenMaxRampDnCommit[g in COMMIT, t in 1:T],
        MESS[:vAGen][g, BS1T[t]] - MESS[:vAGen][g, t] <=
        dfGen[!, :Ramp_Dn_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        (MESS[:vAOnline][g, t] - MESS[:vAStart][g, t]) -
        dfGen[!, :Min_Gen_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vAStart][g, t] +
        min(
            ammonia_inputs["P_Max"][g, t],
            max(dfGen[!, :Min_Gen_Percentage][g], dfGen[!, :Ramp_Dn_Percentage][g]),
        ) *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vAShut][g, t]
    )

    ### Minimum and maximum ammonia output constraints (Constraints #7-8)
    ## Minimum stable ammonia generated per technology "g" at hour "t" > Min ammonia
    @constraint(
        MESS,
        cAGenMinPowerCommit[g in COMMIT, t = 1:T],
        MESS[:vAGen][g, t] >=
        dfGen[!, :Min_Gen_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vAOnline][g, t]
    )

    ## Maximum ammonia generated per technology "g" at hour "t" < Max ammonia
    @constraint(
        MESS,
        cAGenMaxPowerCommit[g in COMMIT, t = 1:T],
        MESS[:vAGen][g, t] <=
        ammonia_inputs["P_Max"][g, t] * dfGen[!, :Cap_Size_tonne_per_hr][g] * MESS[:vAOnline][g, t]
    )

    ## Minimum up and down times (Constraints #9-10)
    Up_Time = zeros(Int, size(dfGen, 1))
    Up_Time[COMMIT] .= Int.(floor.(dfGen[COMMIT, :Up_Time]))
    @constraint(
        MESS,
        cAGenRampUpCommit[g in COMMIT, t in 1:T],
        MESS[:vAOnline][g, t] >=
        sum(MESS[:vAStart][g, tau] for tau in hours_before(Period, t, 0:(Up_Time[g] - 1)))
    )

    Down_Time = zeros(Int, size(dfGen, 1))
    Down_Time[COMMIT] .= Int.(floor.(dfGen[COMMIT, :Down_Time]))
    @constraint(
        MESS,
        cAGenRampDnCommit[g in COMMIT, t in 1:T],
        MESS[:eAGenCap][g] / dfGen[g, :Cap_Size_tonne_per_hr] - MESS[:vAOnline][g, t] >=
        sum(MESS[:vAShut][g, tau] for tau in hours_before(Period, t, 0:(Down_Time[g] - 1)))
    )
    ### End Constraints ###

    return MESS
end
