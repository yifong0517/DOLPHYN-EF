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
    capture_commit(settings::Dict, inputs::Dict, MESS::Model)

"""
function capture_commit(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Carbon Capture Direct Air Unit Commitment Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    Fuels_Index = inputs["Fuels_Index"]

    carbon_settings = settings["CarbonSettings"]
    carbon_inputs = inputs["CarbonInputs"]
    dfGen = carbon_inputs["dfGen"]

    ## Set of all resources eligible for new capacity and retirements
    NEW_CAPTURE_CAP = carbon_inputs["NEW_CAPTURE_CAP"]
    RET_CAPTURE_CAP = carbon_inputs["RET_CAPTURE_CAP"]
    COMMIT = carbon_inputs["COMMIT"]

    ### Expressions ###
    ## Objective Expressions ##
    ## Startup costs of "generation" for resource "g" during hour "t"
    @expression(
        MESS,
        eCObjVarStartOGT[g in COMMIT, t in 1:T],
        weights[t] *
        dfGen[!, :Start_Cost_per_tonne_per_hr][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vCStart][g, t]
    )

    ## Add total variable start cost contribution to objective function
    @expression(
        MESS,
        eCObjVarStartOG[g in COMMIT],
        sum(MESS[:eCObjVarStartOGT][g, t] for t in 1:T; init = 0.0)
    )
    @expression(MESS, eCObjVarStart, sum(MESS, eCObjVarStartOG[g] for g in COMMIT; init = 0.0))
    add_to_expression!(MESS[:eCObj], MESS[:eCObjVarStart])

    ## Startup fuel consumption of "generation" for resource "g" during time "t"
    @expression(
        MESS,
        eCFuelsConsumptionByStart[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
        sum(
            MESS[:vCCap][g, t] *
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
    add_to_expression!.(MESS[:eCFuelsConsumption], MESS[:eCFuelsConsumptionByStart])

    ## Balance Expressions ##
    @expression(
        MESS,
        eCBalanceCommit[z in 1:Z, t in 1:T],
        sum(
            MESS[:vCCap][g, t] for g in intersect(COMMIT, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    ## Sub zonal commit capture expressions
    if carbon_settings["SubZone"] == 1
        SubZones = carbon_inputs["SubZones"]
        ## Carbon sector sub zonal commit capture
        @expression(
            MESS,
            eCCaptureSubZonalCommit[z in SubZones, t = 1:T],
            sum(
                MESS[:vCCap][g, t] for g in intersect(COMMIT, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            ),
        )
    end
    ### End Expressions ###

    ### Constraints ###
    ## Declaration of integer/binary variables
    if carbon_settings["CapCommit"] == 1
        for g in COMMIT
            set_integer.(MESS[:vCOnline][g, :])
            set_integer.(MESS[:vCStart][g, :])
            set_integer.(MESS[:vCShut][g, :])
            if g in RET_CAPTURE_CAP
                set_integer(MESS[:vCRetCaptureCap][g])
            end
            if g in NEW_CAPTURE_CAP
                set_integer(MESS[:vCNewCaptureCap][g])
            end
        end
    end

    ## Capacitated limits on unit commitment decision variables (Constraints #1-3)
    @constraints(
        MESS,
        begin
            cCCaptureMaxOnline[g in COMMIT, t in 1:T],
            MESS[:vCOnline][g, t] <= MESS[:eCCaptureCap][g] / dfGen[!, :Cap_Size_tonne_per_hr][g]
            cCCaptureMaxStart[g in COMMIT, t in 1:T],
            MESS[:vCStart][g, t] <= MESS[:eCCaptureCap][g] / dfGen[!, :Cap_Size_tonne_per_hr][g]
            cCCaptureMaxShut[g in COMMIT, t in 1:T],
            MESS[:vCShut][g, t] <= MESS[:eCCaptureCap][g] / dfGen[!, :Cap_Size_tonne_per_hr][g]
        end
    )

    ## Commitment state constraint linking startup and shutdown decisions (Constraint #4)
    @constraint(
        MESS,
        cCCaptureOnline[g in COMMIT, t in 1:T],
        MESS[:vCOnline][g, t] ==
        MESS[:vCOnline][g, BS1T[t]] + MESS[:vCOnline][g, t] - MESS[:vCShut][g, t]
    )

    ## Maximum ramp up and down between consecutive hours (Constraints #5-6)
    ## Rampup constraints
    @constraint(
        MESS,
        cCCaptureMaxRampUpCommit[g in COMMIT, t in 1:T],
        MESS[:vCCap][g, t] - MESS[:vCCap][g, BS1T[t]] <=
        dfGen[!, :Ramp_Up_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        (MESS[:vCOnline][g, t] - MESS[:vCOnline][g, t]) +
        min(
            carbon_inputs["P_Max"][g, t],
            max(dfGen[!, :Min_Cap_Percentage][g], dfGen[!, :Ramp_Up_Percentage][g]),
        ) *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vCOnline][g, t] -
        dfGen[!, :Min_Cap_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vCShut][g, t]
    )

    ## Rampdown constraints
    @constraint(
        MESS,
        cCCaptureMaxRampDnCommit[g in COMMIT, t in 1:T],
        MESS[:vCCap][g, BS1T[t]] - MESS[:vCCap][g, t] <=
        dfGen[!, :Ramp_Dn_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        (MESS[:vCOnline][g, t] - MESS[:vCOnline][g, t]) -
        dfGen[!, :Min_Cap_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vCOnline][g, t] +
        min(
            carbon_inputs["P_Max"][g, t],
            max(dfGen[!, :Min_Cap_Percentage][g], dfGen[!, :Ramp_Dn_Percentage][g]),
        ) *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vCShut][g, t]
    )

    ## Minimum and maximum power output constraints (Constraints #7-8)
    ## Minimum stable power generated per technology "g" at hour "t" > Min power
    @constraint(
        MESS,
        cCCaptureMinPowerCommit[g in COMMIT, t = 1:T],
        MESS[:vCCap][g, t] >=
        dfGen[!, :Min_Cap_Percentage][g] *
        dfGen[!, :Cap_Size_tonne_per_hr][g] *
        MESS[:vCOnline][g, t]
    )

    ## Maximum power generated per technology "y" at hour "t" < Max power
    @constraint(
        MESS,
        cCCaptureMaxPowerCommit[g in COMMIT, t = 1:T],
        MESS[:vCCap][g, t] <=
        carbon_inputs["P_Max"][g, t] * dfGen[!, :Cap_Size_tonne_per_hr][g] * MESS[:vCOnline][g, t]
    )

    ## Minimum up and down times (Constraints #9-10)
    Up_Time = zeros(Int, size(dfGen, 1))
    Up_Time[COMMIT] .= Int.(floor.(dfGen[COMMIT, :Up_Time]))
    @constraint(
        MESS,
        cCCaptureRampUpCommit[g in COMMIT, t in 1:T],
        MESS[:vCOnline][g, t] >=
        sum(MESS[:vCOnline][g, tau] for tau in hours_before(Period, t, 0:(Up_Time[g] - 1)))
    )

    Down_Time = zeros(Int, size(dfGen, 1))
    Down_Time[COMMIT] .= Int.(floor.(dfGen[COMMIT, :Down_Time]))
    @constraint(
        MESS,
        cCCaptureRampDnCommit[g in COMMIT, t in 1:T],
        MESS[:eCCaptureCap][g] / dfGen[g, :Cap_Size_tonne_per_hr] - MESS[:vCOnline][g, t] >=
        sum(MESS[:vCShut][g, tau] for tau in hours_before(Period, t, 0:(Down_Time[g] - 1)))
    )
    ### End Constraints ###

    return MESS
end
