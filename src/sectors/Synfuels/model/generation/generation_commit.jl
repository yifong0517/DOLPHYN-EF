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

    print_and_log(settings, "i", "Synfuels Generation Unit Commitment Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    synfuels_settings = settings["SynfuelsSettings"]
    synfuels_inputs = inputs["SynfuelsInputs"]
    dfGen = synfuels_inputs["dfGen"]

    ## Set of all resources eligible for new capacity and retirements
    NEW_GEN_CAP = synfuels_inputs["NEW_GEN_CAP"]
    RET_GEN_CAP = synfuels_inputs["RET_GEN_CAP"]
    COMMIT = synfuels_inputs["COMMIT"]

    ### Expressions ###
    ## Objective Expressions ##
    ## Startup costs of "generation" for resource "g" during hour "t"
    @expression(
        MESS,
        eSObjVarStartOGT[g in COMMIT, t in 1:T],
        weights[t] *
        dfGen[!, :Start_Cost_per_tonne_per_hr][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vSStart][g, t]
    )
    @expression(MESS, eSObjVarStartOG[g in COMMIT], sum(MESS[:eSObjVarStartOGT][g, t] for t in 1:T))
    @expression(MESS, eSObjVarStart, sum(MESS[:eSObjVarStartOG][g] for g in COMMIT))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eSObj], MESS[:eSObjVarStart])
    ## End Objective Expressions ##

    ## Startup fuel consumption of "generation" for resource "g" during time "t"
    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]
        @expression(
            MESS,
            eSFuelsConsumptionByStart[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vSGen][g, t] *
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
        add_to_expression!.(MESS[:eSFuelsConsumption], MESS[:eSFuelsConsumptionByStart])
    end

    ## Balance Expressions ##
    @expression(
        MESS,
        eSBalanceThermCommit[z in 1:Z, t in 1:T],
        sum(
            MESS[:vSGen][g, t] for g in intersect(COMMIT, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    ## Sub zonal commit generation expressions
    if synfuels_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = synfuels_inputs["SubZones"]
        ## Synfuels sector sub zonal commit generation
        @expression(
            MESS,
            eSGenerationSubZonalCommit[z in SubZones, t = 1:T],
            sum(
                MESS[:vSGen][g, t] for g in intersect(COMMIT, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            ),
        )
    end
    ### End Expressions ###

    ### Constraints ###
    ## Declaration of integer/binary variables
    if synfuels_settings["GenCommit"] == 1
        for g in COMMIT
            set_integer.(MESS[:vSOnline][g, :])
            set_integer.(MESS[:vSStart][g, :])
            set_integer.(MESS[:vSShut][g, :])
            if g in RET_GEN_CAP
                set_integer(MESS[:vSRetCap][g])
            end
            if g in NEW_GEN_CAP
                set_integer(MESS[:vSNewCAP][g])
            end
        end
    end

    ## Capacitated limits on unit commitment decision variables (Constraints #1-3)
    @constraints(
        MESS,
        begin
            cSGenMaxOnline[g in COMMIT, t in 1:T],
            MESS[:vSOnline][g, t] <= MESS[:eSGenCap][g] / dfGen[!, :Cap_Size_tonne_per_hr][g]
            cSGenMaxStart[g in COMMIT, t in 1:T],
            MESS[:vSStart][g, t] <= MESS[:eSGenCap][g] / dfGen[!, :Cap_Size_tonne_per_hr][g]
            cSGenMaxShut[g in COMMIT, t in 1:T],
            MESS[:vSShut][g, t] <= MESS[:eSGenCap][g] / dfGen[!, :Cap_Size_tonne_per_hr][g]
        end
    )

    ## Commitment state constraint linking startup and shutdown decisions (Constraint #4)
    @constraint(
        MESS,
        cSGenOnline[g in COMMIT, t in 1:T],
        MESS[:vSOnline][g, t] ==
        MESS[:vSOnline][g, BS1T[t]] + MESS[:vSStart][g, t] - MESS[:vSShut][g, t]
    )

    ## Maximum ramp up and down between consecutive hours (Constraints #5-6)
    ## Rampup constraints
    @constraint(
        MESS,
        cSGenMaxRampUpCommit[g in COMMIT, t in 1:T],
        MESS[:vSGen][g, t] - MESS[:vSGen][g, BS1T[t]] <=
        dfGen[!, :Ramp_Up_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        (MESS[:vSOnline][g, t] - MESS[:vSStart][g, t]) +
        min(
            synfuels_inputs["P_Max"][g, t],
            max(dfGen[!, :Min_Gen_Percentage][g], dfGen[!, :Ramp_Up_Percentage][g]),
        ) *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vSStart][g, t] -
        dfGen[!, :Min_Gen_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vSShut][g, t]
    )

    ## Rampdown constraints
    @constraint(
        MESS,
        cSGenMaxRampDnCommit[g in COMMIT, t in 1:T],
        MESS[:vSGen][g, BS1T[t]] - MESS[:vSGen][g, t] <=
        dfGen[!, :Ramp_Dn_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        (MESS[:vSOnline][g, t] - MESS[:vSStart][g, t]) -
        dfGen[!, :Min_Gen_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vSStart][g, t] +
        min(
            synfuels_inputs["P_Max"][g, t],
            max(dfGen[!, :Min_Gen_Percentage][g], dfGen[!, :Ramp_Dn_Percentage][g]),
        ) *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vSShut][g, t]
    )

    ### Minimum and maximum synfuels output constraints (Constraints #7-8)
    ## Minimum stable synfuels generated per technology "g" at hour "t" > Min synfuels
    @constraint(
        MESS,
        cSGenMinPowerCommit[g in COMMIT, t = 1:T],
        MESS[:vSGen][g, t] >=
        dfGen[!, :Min_Gen_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vSOnline][g, t]
    )

    ## Maximum synfuels generated per technology "y" at hour "t" < Max synfuels
    @constraint(
        MESS,
        cSGenMaxPowerCommit[g in COMMIT, t = 1:T],
        MESS[:vSGen][g, t] <=
        synfuels_inputs["P_Max"][g, t] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vSOnline][g, t]
    )

    ## Minimum up and down times (Constraints #9-10)
    Up_Time = zeros(Int, size(dfGen, 1))
    Up_Time[COMMIT] .= Int.(floor.(dfGen[COMMIT, :Up_Time]))
    @constraint(
        MESS,
        cSGenRampUpCommit[g in COMMIT, t in 1:T],
        MESS[:vSOnline][g, t] >=
        sum(MESS[:vSStart][g, tau] for tau in hours_before(Period, t, 0:(Up_Time[g] - 1)))
    )

    Down_Time = zeros(Int, size(dfGen, 1))
    Down_Time[COMMIT] .= Int.(floor.(dfGen[COMMIT, :Down_Time]))
    @constraint(
        MESS,
        cSGenRampDnCommit[g in COMMIT, t in 1:T],
        MESS[:eSGenCap][g] / dfGen[g, :Cap_Size_tonne_per_hr] - MESS[:vSOnline][g, t] >=
        sum(MESS[:vSShut][g, tau] for tau in hours_before(Period, t, 0:(Down_Time[g] - 1)))
    )
    ### End Constraints ###

    return MESS
end
