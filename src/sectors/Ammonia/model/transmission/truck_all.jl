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

    print_and_log(settings, "i", "Ammonia Transmission Truck Core Module")

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

    ammonia_settings = settings["AmmoniaSettings"]
    ammonia_inputs = inputs["AmmoniaInputs"]

    dfTru = ammonia_inputs["dfTru"]
    dfRoute = ammonia_inputs["dfRoute"]

    Transport_map = ammonia_inputs["Transport_map"]
    Travel_delay = ammonia_inputs["Travel_delay"]
    TRUCK_TYPES = ammonia_inputs["TRUCK_TYPES"]
    TRANSPORT_ZONES = ammonia_inputs["TRANSPORT_ZONES"]

    R = ammonia_inputs["R"]

    ### Variables ###
    ## Truck flow volume [tonne] through type "j" at time "t" on zone "z"
    @variable(MESS, vATruckFlow[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T])

    ## Number of available full truck type "j" in transit at time "t" on zone "z"
    @variable(MESS, vAAvailFull[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of travel, arrive and deaprt full truck type "j" in transit at time "t" from zone 'zz' to "z"
    @variable(MESS, vATravelFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vAArriveFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vADepartFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)

    ## Number of available empty truck type "j" in transit at time "t" on zone "z"
    @variable(MESS, vAAvailEmpty[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)

    ## Number of travel, arrive and deaprt empty truck type "j" in transit at time "t" from zone 'zz' to "z"
    @variable(MESS, vATravelEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vAArriveEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vADepartEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)

    ## Number of charged truck type "j" at time "t" on zone "z"
    @variable(MESS, vALoaded[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of discharged truck type "j" at time "t" on zone "z"
    @variable(MESS, vAUnloaded[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of full truck type "j" at time "t"
    @variable(MESS, vAFull[j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of empty truck type "j" at time "t"
    @variable(MESS, vAEmpty[j in TRUCK_TYPES, t = 1:T] >= 0)

    ### Expressions ###
    ## Objective Expressions ##
    @expression(
        MESS,
        eAObjVarTruOJ[j in TRUCK_TYPES],
        sum(
            weights[t] *
            (
                MESS[:vAArriveFull][r, j, d, t] * dfTru[!, :Var_OM_Cost_Full_per_mile][j] +
                MESS[:vAArriveEmpty][r, j, d, t] * dfTru[!, :Var_OM_Cost_Empty_per_mile][j]
            ) *
            dfRoute[!, :Distance][r] for r in 1:R, d in [-1, 1], t in 1:T;
            init = 0.0,
        )
    )
    @expression(MESS, eAObjVarTru, sum(MESS[:eAObjVarTruOJ][j] for j in TRUCK_TYPES))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eAObj], MESS[:eAObjVarTru])

    ## Operating expenditure for truck ammonia compression
    @expression(
        MESS,
        eAObjVarTruCompOJ[j in TRUCK_TYPES],
        sum(
            weights[t] *
            (MESS[:vATruckFlow][z, j, t] * dfTru[!, :Truck_Comp_Unit_Opex_per_tonne][j]) for
            z in TRANSPORT_ZONES, t in 1:T;
            init = 0.0,
        )
    )
    @expression(MESS, eAObjVarTruComp, sum(MESS[:eAObjVarTruCompOJ][j] for j in TRUCK_TYPES))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eAObj], MESS[:eAObjVarTruComp])
    ## End Objective Expressions ##

    ## Balance Expressions ##
    ## Ammonia balance
    @expression(
        MESS,
        eABalanceTruckFlow[z = 1:Z, t = 1:T],
        begin
            if Zones[z] in TRANSPORT_ZONES
                sum(MESS[:vATruckFlow][Zones[z], j, t] for j in TRUCK_TYPES; init = 0.0)
            else
                0
            end
        end
    )
    add_to_expression!.(MESS[:eABalance], MESS[:eABalanceTruckFlow])
    add_to_expression!.(MESS[:eATransmission], MESS[:eABalanceTruckFlow])

    ## Ammonia truck traveling hydrogen consumption balance - if truck is fueled by hydrogen
    if settings["ModelHydrogen"] == 1
        @expression(
            MESS,
            eHBalanceATruckTravel[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vAArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vAArriveEmpty][
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
        add_to_expression!.(MESS[:eHBalance], -MESS[:eHBalanceATruckTravel])
        add_to_expression!.(MESS[:eHDemandAddition], MESS[:eHBalanceATruckTravel])
    else
        @expression(
            MESS,
            eAHydrogenConsumptionTruckTravel[f in eachindex(Hydrogen_Index), z = 1:Z, t = 1:T],
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
        add_to_expression!.(MESS[:eAHydrogenConsumption], MESS[:eAHydrogenConsumptionTruckTravel])
    end

    ## Ammonia truck travelling power consumption balance - if truck is powered by electricity
    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceATruckTravel[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vAArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vAArriveEmpty][
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
        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceATruckTravel])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceATruckTravel])
    else
        @expression(
            MESS,
            eAElectricityConsumptionTruckTravel[
                f in eachindex(Electricity_Index),
                z = 1:Z,
                t = 1:T,
            ],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vAArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vAArriveEmpty][
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
            MESS[:eAElectricityConsumption],
            MESS[:eAElectricityConsumptionTruckTravel],
        )
    end

    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceATruckComp[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        MESS[:vALoaded][Zones[z], j, t] *
                        dfTru[!, :Truck_Cap_tonne_per_unit][j] *
                        dfTru[!, :Truck_Comp_Energy_MWh_per_tonne][j] for j in TRUCK_TYPES;
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceATruckComp])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceATruckComp])
    else
        @expression(
            MESS,
            eAElectricityConsumptionTruckComp[f in eachindex(Electricity_Index), z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        MESS[:vALoaded][Zones[z], j, t] *
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
            MESS[:eAElectricityConsumption],
            MESS[:eAElectricityConsumptionTruckComp],
        )
    end

    ## Ammonia truck traveling fuel consumption
    if settings["ModelFuels"] == 1
        @expression(
            MESS,
            eAFuelsConsumptionByTruck[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vAArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vAArriveEmpty][
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
        add_to_expression!.(MESS[:eAFuelsConsumption], MESS[:eAFuelsConsumptionByTruck])

        ## Ammonia truck emission
        @expression(
            MESS,
            eAEmissionsByTruck[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vAArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vAArriveEmpty][
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
        add_to_expression!.(MESS[:eAEmissions], MESS[:eAEmissionsByTruck])
    end
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Total number
    @constraint(
        MESS,
        cATruckTotalNumber[j in TRUCK_TYPES, t in 1:T],
        MESS[:vAFull][j, t] + MESS[:vAEmpty][j, t] == MESS[:eATruNumber][j]
    )

    ## The number of total full and empty trucks
    @constraints(
        MESS,
        begin
            cATruckTotalFull[j in TRUCK_TYPES, t in 1:T],
            MESS[:vAFull][j, t] ==
            sum(MESS[:vATravelFull][r, j, d, t] for r in 1:R, d in [-1, 1]) +
            sum(MESS[:vAAvailFull][z, j, t] for z in TRANSPORT_ZONES)

            cA2TruckTotalEmpty[j in TRUCK_TYPES, t in 1:T],
            MESS[:vAEmpty][j, t] ==
            sum(MESS[:vATravelEmpty][r, j, d, t] for r in 1:R, d in [-1, 1]) +
            sum(MESS[:vAAvailEmpty][z, j, t] for z in TRANSPORT_ZONES)
        end
    )

    ## Change of the number of full available trucks
    @constraint(
        MESS,
        cATruckChangeFullAvail[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vAAvailFull][z, j, t] - MESS[:vAAvailFull][z, j, BS1T[t]] ==
        MESS[:vALoaded][z, j, t] -
        MESS[:vAUnloaded][z, j, hours_before(Period, t, dfTru[!, :Unloading_Time][j])] + sum(
            MESS[:vAArriveFull][
                r,
                j,
                Transport_map[(Transport_map.Zone .== z) .& (Transport_map.route_no .== r), :d][1],
                t,
            ] for r in Transport_map[Transport_map.Zone .== z, :route_no]
        ) - sum(
            MESS[:vADepartFull][
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
        cATruckChangeEmptyAvail[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vAAvailEmpty][z, j, t] - MESS[:vAAvailEmpty][z, j, BS1T[t]] ==
        -MESS[:vALoaded][z, j, hours_before(Period, t, dfTru[!, :Loading_Time][j])] +
        MESS[:vAUnloaded][z, j, t] +
        sum(
            MESS[:vAArriveEmpty][
                r,
                j,
                Transport_map[(Transport_map.Zone .== z) .& (Transport_map.route_no .== r), :d][1],
                t,
            ] for r in Transport_map[Transport_map.Zone .== z, :route_no]
        ) - sum(
            MESS[:vADepartEmpty][
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
        cATruckChangeFullTravel[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
        MESS[:vATravelFull][r, j, d, t] - MESS[:vATravelFull][r, j, d, BS1T[t]] ==
        MESS[:vADepartFull][r, j, d, t] - MESS[:vAArriveFull][r, j, d, t]
    )

    ## Change of the number of empty traveling trucks
    @constraint(
        MESS,
        cATruckChangeEmptyTravel[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
        MESS[:vATravelEmpty][r, j, d, t] - MESS[:vATravelEmpty][r, j, d, BS1T[t]] ==
        MESS[:vADepartEmpty][r, j, d, t] - MESS[:vAArriveEmpty][r, j, d, t]
    )

    ## Travel delay
    @constraints(
        MESS,
        begin
            cATruckTravelDelayArriveFull[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vATravelFull][r, j, d, t] >= sum(
                MESS[:vAArriveFull][r, j, d, tt] for tt in (t + 1):(t + Travel_delay[j][r]) if
                t + Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t + Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cATruckTravelDelayArriveEmpty[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vATravelEmpty][r, j, d, t] >= sum(
                MESS[:vAArriveEmpty][r, j, d, tt] for tt in (t + 1):(t + Travel_delay[j][r]) if
                t + Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t + Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cATruckTravelDelayDepartFull[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vATravelFull][r, j, d, t] >= sum(
                MESS[:vADepartFull][r, j, d, tt] for tt in (t - Travel_delay[j][r] + 1):t if
                t - Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t - Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cATruckTravelDelayDepartEmpty[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vATravelEmpty][r, j, d, t] >= sum(
                MESS[:vADepartEmpty][r, j, d, tt] for tt in (t - Travel_delay[j][r] + 1):t if
                t - Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t - Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
        end
    )

    ## Capacity constraints
    @constraint(
        MESS,
        cATruckMaxLoadCap[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vALoaded][z, j, t] * dfTru[!, :Truck_Cap_tonne_per_unit][j] <= MESS[:eATruComp][z, j]
    )

    ## Ammonia truck flow balance
    @constraint(
        MESS,
        cATruckFlow[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vATruckFlow][z, j, t] ==
        MESS[:vAUnloaded][z, j, t] *
        dfTru[!, :Truck_Cap_tonne_per_unit][j] *
        (1 - dfTru[!, :Loss_Percentage_per_mile][j]) -
        MESS[:vALoaded][z, j, t] * dfTru[!, :Truck_Cap_tonne_per_unit][j]
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
