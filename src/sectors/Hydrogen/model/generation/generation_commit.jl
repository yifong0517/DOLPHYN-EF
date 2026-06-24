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

    print_and_log(settings, "i", "Hydrogen Generation Unit Commitment Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    hydrogen_settings = settings["HydrogenSettings"]
    hydrogen_inputs = inputs["HydrogenInputs"]
    dfGen = hydrogen_inputs["dfGen"]

    ## Set of all resources eligible for new capacity and retirements
    NEW_GEN_CAP = hydrogen_inputs["NEW_GEN_CAP"]
    RET_GEN_CAP = hydrogen_inputs["RET_GEN_CAP"]
    COMMIT = hydrogen_inputs["COMMIT"]

    ### Expressions ###
    ## Objective Expressions ##
    ## Startup costs of "generation" for resource "g" during hour "t"
    @expression(
        MESS,
        eHObjVarStartOGT[g in COMMIT, t in 1:T],
        weights[t] *
        dfGen[!, :Start_Cost_per_tonne_per_hr][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vHStart][g, t]
    )
    @expression(
        MESS,
        eHObjVarStartOG[g in COMMIT],
        sum(MESS[:eHObjVarStartOGT][g, t] for t in 1:T; init = 0.0)
    )
    @expression(MESS, eHObjVarStart, sum(MESS[:eHObjVarStartOG][g] for g in COMMIT))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eHObj], MESS[:eHObjVarStart])
    ## End Objective Expressions ##

    ## Startup fuel consumption of "generation" for resource "g" during time "t"
    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]

        @expression(
            MESS,
            eHFuelsConsumptionByStart[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vHGen][g, t] *
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
        add_to_expression!.(MESS[:eHFuelsConsumption], MESS[:eHFuelsConsumptionByStart])
    end

    ## Balance Expressions ##
    @expression(
        MESS,
        eHBalanceCommit[z in 1:Z, t in 1:T],
        sum(
            MESS[:vHGen][g, t] for g in intersect(COMMIT, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )
    ## End Balance Expressions ##

    ## Sub zonal commit generation expressions
    if hydrogen_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = hydrogen_inputs["SubZones"]
        ## Hydrogen sector sub zonal commit generation
        @expression(
            MESS,
            eHGenerationSubZonalCommit[z in SubZones, t = 1:T],
            sum(
                MESS[:vHGen][g, t] for g in intersect(COMMIT, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            ),
        )
    end
    ### End Expressions ###

    ### Constraints ###
    ## Declaration of integer/binary variables
    if hydrogen_settings["GenCommit"] == 1
        for g in COMMIT
            set_integer.(MESS[:vHOnline][g, :])
            set_integer.(MESS[:vHStart][g, :])
            set_integer.(MESS[:vHShut][g, :])
            if g in RET_GEN_CAP
                set_integer(MESS[:vHRetGenCap][g])
            end
            if g in NEW_GEN_CAP
                set_integer(MESS[:vHNewGenCap][g])
            end
        end
    end

    ## Capacitated limits on unit commitment decision variables (Constraints #1-3)
    @constraints(
        MESS,
        begin
            cHGenMaxOnline[g in COMMIT, t in 1:T],
            MESS[:vHOnline][g, t] <= MESS[:eHGenCap][g] / dfGen[!, :Cap_Size_tonne_per_hr][g]
            cHGenMaxStart[g in COMMIT, t in 1:T],
            MESS[:vHStart][g, t] <= MESS[:eHGenCap][g] / dfGen[!, :Cap_Size_tonne_per_hr][g]
            cHGenMaxShut[g in COMMIT, t in 1:T],
            MESS[:vHShut][g, t] <= MESS[:eHGenCap][g] / dfGen[!, :Cap_Size_tonne_per_hr][g]
        end
    )

    ## Commitment state constraint linking startup and shutdown decisions (Constraint #4)
    @constraint(
        MESS,
        cHGenOnline[g in COMMIT, t in 1:T],
        MESS[:vHOnline][g, t] ==
        MESS[:vHOnline][g, BS1T[t]] + MESS[:vHStart][g, t] - MESS[:vHShut][g, t]
    )

    ## Maximum ramp up and down between consecutive hours (Constraints #5-6)
    ## Rampup constraints
    @constraint(
        MESS,
        cHGenCommitMaxRampUp[g in COMMIT, t in 1:T],
        MESS[:vHGen][g, t] - MESS[:vHGen][g, BS1T[t]] <=
        dfGen[!, :Ramp_Up_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        (MESS[:vHOnline][g, t] - MESS[:vHStart][g, t]) +
        min(
            hydrogen_inputs["P_Max"][g, t],
            max(dfGen[!, :Min_Gen_Percentage][g], dfGen[!, :Ramp_Up_Percentage][g]),
        ) *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vHStart][g, t] -
        dfGen[!, :Min_Gen_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vHShut][g, t]
    )

    ## Rampdown constraints
    @constraint(
        MESS,
        cHGenCommitMaxRampDn[g in COMMIT, t in 1:T],
        MESS[:vHGen][g, BS1T[t]] - MESS[:vHGen][g, t] <=
        dfGen[!, :Ramp_Dn_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        (MESS[:vHOnline][g, t] - MESS[:vHStart][g, t]) -
        dfGen[!, :Min_Gen_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vHStart][g, t] +
        min(
            hydrogen_inputs["P_Max"][g, t],
            max(dfGen[!, :Min_Gen_Percentage][g], dfGen[!, :Ramp_Dn_Percentage][g]),
        ) *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vHShut][g, t]
    )

    ## Minimum and maximum hydrogen output constraints (Constraints #7-8)
    ## Minimum stable hydrogen generated per technology "y" at hour "t" > Min hydrogen
    @constraint(
        MESS,
        cHGenCommitMinPower[g in COMMIT, t = 1:T],
        MESS[:vHGen][g, t] >=
        dfGen[!, :Min_Gen_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vHOnline][g, t]
    )

    ## Maximum hydrogen generated per technology "y" at hour "t" < Max hydrogen
    @constraint(
        MESS,
        cHGenCommitMaxPower[g in COMMIT, t = 1:T],
        MESS[:vHGen][g, t] <=
        hydrogen_inputs["P_Max"][g, t] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vHOnline][g, t]
    )

    ## Minimum up and down times (Constraints #9-10)
    Up_Time = zeros(Int, size(dfGen, 1))
    Up_Time[COMMIT] .= Int.(floor.(dfGen[COMMIT, :Up_Time]))
    @constraint(
        MESS,
        cHGenCommitRampUp[g in COMMIT, t in 1:T],
        MESS[:vHOnline][g, t] >=
        sum(MESS[:vHStart][g, tau] for tau in hours_before(Period, t, 0:(Up_Time[g] - 1)))
    )

    Down_Time = zeros(Int, size(dfGen, 1))
    Down_Time[COMMIT] .= Int.(floor.(dfGen[COMMIT, :Down_Time]))
    @constraint(
        MESS,
        cHGenCommitRampDn[g in COMMIT, t in 1:T],
        MESS[:eHGenCap][g] / dfGen[g, :Cap_Size_tonne_per_hr] - MESS[:vHOnline][g, t] >=
        sum(MESS[:vHShut][g, tau] for tau in hours_before(Period, t, 0:(Down_Time[g] - 1)))
    )
    ### End Constraints ###

    return MESS
end
