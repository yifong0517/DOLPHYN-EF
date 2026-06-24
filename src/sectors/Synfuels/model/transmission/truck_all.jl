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
function truck_all(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Synfuels Transmission Truck Core Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]
        fuels_CO2 = inputs["fuels_CO2"]
    end
    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
    end
    if !(settings["ModelHydrogen"] == 1)
        Hydrogen_Index = inputs["Hydrogen_Index"]
    end

    synfuels_settings = settings["SynfuelsSettings"]
    synfuels_inputs = inputs["SynfuelsInputs"]

    dfTru = synfuels_inputs["dfTru"]
    dfRoute = synfuels_inputs["dfRoute"]

    Transport_map = synfuels_inputs["Transport_map"]
    Travel_delay = synfuels_inputs["Travel_delay"]
    TRUCK_TYPES = synfuels_inputs["TRUCK_TYPES"]
    TRANSPORT_ZONES = synfuels_inputs["TRANSPORT_ZONES"]

    R = synfuels_inputs["R"]

    ### Variables ###
    ## Truck flow volume [tonne] through type "j" at time "t" on zone "z"
    @variable(MESS, vSTruckFlow[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T])

    ## Number of available full truck type "j" in transit at time "t" on zone "z"
    @variable(MESS, vSAvailFull[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of travel, arrive and deaprt full truck type "j" in transit at time "t" from zone 'zz' to "z"
    @variable(MESS, vSTravelFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vSArriveFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vSDepartFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)

    ## Number of available empty truck type "j" in transit at time "t" on zone "z"
    @variable(MESS, vSAvailEmpty[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)

    ## Number of travel, arrive and deaprt empty truck type "j" in transit at time "t" from zone 'zz' to "z"
    @variable(MESS, vSTravelEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vSArriveEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vSDepartEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)

    ## Number of charged truck type "j" at time "t" on zone "z"
    @variable(MESS, vSLoaded[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of discharged truck type "j" at time "t" on zone "z"
    @variable(MESS, vSUnloaded[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of full truck type "j" at time "t"
    @variable(MESS, vSFull[j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of empty truck type "j" at time "t"
    @variable(MESS, vSEmpty[j in TRUCK_TYPES, t = 1:T] >= 0)

    ### Expressions ###
    ## Objective Expressions ##
    @expression(
        MESS,
        eSObjVarTruOJ[j in TRUCK_TYPES],
        sum(
            weights[t] *
            (
                MESS[:vSArriveFull][r, j, d, t] * dfTru[!, :Var_OM_Cost_Full_per_mile][j] +
                MESS[:vSArriveEmpty][r, j, d, t] * dfTru[!, :Var_OM_Cost_Empty_per_mile][j]
            ) *
            dfRoute[!, :Distance][r] for r in 1:R, d in [-1, 1], t in 1:T;
            init = 0.0,
        )
    )
    @expression(MESS, eSObjVarTru, sum(MESS[:eSObjVarTruOJ][j] for j in TRUCK_TYPES))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eSObj], MESS[:eSObjVarTru])

    ## Operating expenditure for truck synfuels compression
    @expression(
        MESS,
        eSObjVarTruCompOJ[j in TRUCK_TYPES],
        sum(
            weights[t] *
            (MESS[:vSTruckFlow][z, j, t] * dfTru[!, :Truck_Comp_Unit_Opex_per_tonne][j]) for
            z in TRANSPORT_ZONES, t in 1:T;
            init = 0.0,
        )
    )
    @expression(MESS, eSObjVarTruComp, sum(MESS[:eSObjVarTruCompOJ][j] for j in TRUCK_TYPES))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eSObj], MESS[:eSObjVarTruComp])
    ## End Objective Expressions ##

    ## Balance Expressions ##
    ## Synfuels balance
    @expression(
        MESS,
        eSBalanceTruckFlow[z = 1:Z, t = 1:T],
        begin
            if Zones[z] in TRANSPORT_ZONES
                sum(MESS[:vSTruckFlow][Zones[z], j, t] for j in TRUCK_TYPES; init = 0.0)
            else
                0
            end
        end
    )
    add_to_expression!.(MESS[:eSBalance], MESS[:eSBalanceTruckFlow])
    add_to_expression!.(MESS[:eSTransmission], MESS[:eSBalanceTruckFlow])

    ## Synfuels truck traveling hydrogen consumption balance - if truck is fueled by hydrogen
    if settings["ModelHydrogen"] == 1
        @expression(
            MESS,
            eHBalanceSTruckTravel[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vSArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vSArriveEmpty][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ]
                        ) *
                        dfTru[!, :H2_tonne_per_mile][j] *
                        dfRoute[!, :Distance][r] for
                        r in Transport_map[Transport_map.Zone .== Zones[z], :route_no],
                        j in TRUCK_TYPES;
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(MESS[:eHBalance], -MESS[:eHBalanceSTruckTravel])
        add_to_expression!.(MESS[:eHDemandAddition], MESS[:eHBalanceSTruckTravel])
    else
        @expression(
            MESS,
            eSHydrogenConsumptionTruckTravel[f in eachindex(Hydrogen_Index), z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vCArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vCArriveEmpty][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ]
                        ) *
                        dfTru[!, :H2_tonne_per_mile][j] *
                        dfRoute[!, :Distance][r] for
                        r in Transport_map[Transport_map.Zone .== Zones[z], :route_no],
                        j in dfTru[dfTru.Hydrogen .== Hydrogen_Index[f], :T_ID];
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(MESS[:eSHydrogenConsumption], MESS[:eSHydrogenConsumptionTruckTravel])
    end

    ## Synfuels truck travelling power consumption balance - if truck is powered by electricity
    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceSTruckTravel[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vSArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vSArriveEmpty][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ]
                        ) *
                        dfTru[!, :Electricity_MWh_per_mile][j] *
                        dfRoute[!, :Distance][r] for
                        r in Transport_map[Transport_map.Zone .== Zones[z], :route_no],
                        j in TRUCK_TYPES;
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceSTruckTravel])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceSTruckTravel])
    else
        @expression(
            MESS,
            eSElectricityConsumptionTruckTravel[
                f in eachindex(Electricity_Index),
                z = 1:Z,
                t = 1:T,
            ],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vSArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vSArriveEmpty][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ]
                        ) *
                        dfTru[!, :Electricity_MWh_per_mile][j] *
                        dfRoute[!, :Distance][r] for
                        r in Transport_map[Transport_map.Zone .== Zones[z], :route_no],
                        j in dfTru[dfTru.Electricity .== Electricity_Index[f], :T_ID];
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(
            MESS[:eSElectricityConsumption],
            MESS[:eSElectricityConsumptionTruckTravel],
        )
    end

    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceSTruckComp[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        MESS[:vSLoaded][Zones[z], j, t] *
                        dfTru[!, :Truck_Cap_tonne_per_unit][j] *
                        dfTru[!, :Truck_Comp_Energy_MWh_per_tonne][j] for j in TRUCK_TYPES;
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceSTruckComp])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceSTruckComp])
    else
        @expression(
            MESS,
            eSElectricityConsumptionTruckComp[f in eachindex(Electricity_Index), z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        MESS[:vSLoaded][Zones[z], j, t] *
                        dfTru[!, :Truck_Cap_tonne_per_unit][j] *
                        dfTru[!, :Truck_Comp_Energy_MWh_per_tonne][j] for
                        j in dfTru[dfTru.Electricity .== Electricity_Index[f], :T_ID];
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(
            MESS[:eSElectricityConsumption],
            MESS[:eSElectricityConsumptionTruckComp],
        )
    end

    ## Synfuels truck traveling fuel consumption
    if settings["ModelFuels"] == 1
        @expression(
            MESS,
            eSFuelsConsumptionByTruck[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vSArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vSArriveEmpty][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ]
                        ) *
                        dfTru[!, :Fuel_MMBTU_per_mile][j] *
                        dfRoute[!, :Distance][r] for
                        r in Transport_map[Transport_map.Zone .== Zones[z], :route_no],
                        j in dfTru[dfTru.Fuel .== Fuels_Index[f], :T_ID];
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(MESS[:eSFuelsConsumption], MESS[:eSFuelsConsumptionByTruck])

        ## Synfuels truck emission
        @expression(
            MESS,
            eSEmissionsByTruck[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vSArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vSArriveEmpty][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ]
                        ) *
                        fuels_CO2[dfTru[!, :Fuel][j]] *
                        dfTru[!, :Fuel_MMBTU_per_mile][j] *
                        dfRoute[!, :Distance][r] for
                        r in Transport_map[Transport_map.Zone .== Zones[z], :route_no],
                        j in filter(:Fuel => in(Fuels_Index), dfTru)[!, :T_ID];
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(MESS[:eSEmissions], MESS[:eSEmissionsByTruck])
    end
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###

    ## Total number
    @constraint(
        MESS,
        cSTruckTotalNumber[j in TRUCK_TYPES, t in 1:T],
        MESS[:vSFull][j, t] + MESS[:vSEmpty][j, t] == MESS[:eSTruNumber][j]
    )

    ## The number of total full and empty trucks
    @constraints(
        MESS,
        begin
            cSTruckTotalFull[j in TRUCK_TYPES, t in 1:T],
            MESS[:vSFull][j, t] ==
            sum(MESS[:vSTravelFull][r, j, d, t] for r in 1:R, d in [-1, 1]) +
            sum(MESS[:vSAvailFull][z, j, t] for z in TRANSPORT_ZONES)

            cS2TruckTotalEmpty[j in TRUCK_TYPES, t in 1:T],
            MESS[:vSEmpty][j, t] ==
            sum(MESS[:vSTravelEmpty][r, j, d, t] for r in 1:R, d in [-1, 1]) +
            sum(MESS[:vSAvailEmpty][z, j, t] for z in TRANSPORT_ZONES)
        end
    )

    ## Change of the number of full available trucks
    @constraint(
        MESS,
        cSTruckChangeFullAvail[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vSAvailFull][z, j, t] - MESS[:vSAvailFull][z, j, BS1T[t]] ==
        MESS[:vSLoaded][z, j, t] -
        MESS[:vSUnloaded][z, j, hours_before(Period, t, dfTru[!, :Unloading_Time][j])] + sum(
            MESS[:vSArriveFull][
                r,
                j,
                Transport_map[(Transport_map.Zone .== z) .& (Transport_map.route_no .== r), :d][1],
                t,
            ] for r in Transport_map[Transport_map.Zone .== z, :route_no]
        ) - sum(
            MESS[:vSDepartFull][
                r,
                j,
                Transport_map[(Transport_map.Zone .== z) .& (Transport_map.route_no .== r), :d][1],
                t,
            ] for r in Transport_map[Transport_map.Zone .== z, :route_no]
        )
    )

    ## Change of the number of empty available trucks
    @constraint(
        MESS,
        cSTruckChangeEmptyAvail[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vSAvailEmpty][z, j, t] - MESS[:vSAvailEmpty][z, j, BS1T[t]] ==
        -MESS[:vSLoaded][z, j, hours_before(Period, t, dfTru[!, :Loading_Time][j])] +
        MESS[:vSUnloaded][z, j, t] +
        sum(
            MESS[:vSArriveEmpty][
                r,
                j,
                Transport_map[(Transport_map.Zone .== z) .& (Transport_map.route_no .== r), :d][1],
                t,
            ] for r in Transport_map[Transport_map.Zone .== z, :route_no]
        ) - sum(
            MESS[:vSDepartEmpty][
                r,
                j,
                Transport_map[(Transport_map.Zone .== z) .& (Transport_map.route_no .== r), :d][1],
                t,
            ] for r in Transport_map[Transport_map.Zone .== z, :route_no]
        )
    )

    ## Change of the number of full traveling trucks
    @constraint(
        MESS,
        cSTruckChangeFullTravel[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
        MESS[:vSTravelFull][r, j, d, t] - MESS[:vSTravelFull][r, j, d, BS1T[t]] ==
        MESS[:vSDepartFull][r, j, d, t] - MESS[:vSArriveFull][r, j, d, t]
    )

    ## Change of the number of empty traveling trucks
    @constraint(
        MESS,
        cSTruckChangeEmptyTravel[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
        MESS[:vSTravelEmpty][r, j, d, t] - MESS[:vSTravelEmpty][r, j, d, BS1T[t]] ==
        MESS[:vSDepartEmpty][r, j, d, t] - MESS[:vSArriveEmpty][r, j, d, t]
    )

    ## Travel delay
    @constraints(
        MESS,
        begin
            cSTruckTravelDelayArriveFull[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vSTravelFull][r, j, d, t] >= sum(
                MESS[:vSArriveFull][r, j, d, tt] for tt in (t + 1):(t + Travel_delay[j][r]) if
                t + Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t + Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cSTruckTravelDelayArriveEmpty[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vSTravelEmpty][r, j, d, t] >= sum(
                MESS[:vSArriveEmpty][r, j, d, tt] for tt in (t + 1):(t + Travel_delay[j][r]) if
                t + Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t + Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cSTruckTravelDelayDepartFull[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vSTravelFull][r, j, d, t] >= sum(
                MESS[:vSDepartFull][r, j, d, tt] for tt in (t - Travel_delay[j][r] + 1):t if
                t - Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t - Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cSTruckTravelDelayDepartEmpty[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vSTravelEmpty][r, j, d, t] >= sum(
                MESS[:vSDepartEmpty][r, j, d, tt] for tt in (t - Travel_delay[j][r] + 1):t if
                t - Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t - Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
        end
    )

    ## Capacity constraints
    @constraint(
        MESS,
        cSTruckMaxLoadCap[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vSLoaded][z, j, t] * dfTru[!, :Truck_Cap_tonne_per_unit][j] <= MESS[:eSTruComp][z, j]
    )

    ## Synfuels truck flow balance
    @constraint(
        MESS,
        cSTruckFlow[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vSTruckFlow][z, j, t] ==
        MESS[:vSUnloaded][z, j, t] *
        dfTru[!, :Truck_Cap_tonne_per_unit][j] *
        (1 - dfTru[!, :Loss_Percentage_per_mile][j]) -
        MESS[:vSLoaded][z, j, t] * dfTru[!, :Truck_Cap_tonne_per_unit][j]
    )
    ### End Constraints ###

    return MESS
end

# # Truck travel delay - reserved for backup
# if t + Travel_delay[j][zz, z] >=
#    ((t - 1) ÷ Period) * Period + 1 &&
#    t + Travel_delay[j][zz, z] <= t + Period - 1 &&
#    t + 1 <= t + Travel_delay[j][zz, z]
#     nothing
# end
