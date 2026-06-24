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

    print_and_log(settings, "i", "Carbon Transmission Truck Core Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    Fuels_Index = inputs["Fuels_Index"]
    fuels_costs = inputs["fuels_costs"]
    fuels_CO2 = inputs["fuels_CO2"]

    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
    end
    if !(settings["ModelHydrogen"] == 1)
        Hydrogen_Index = inputs["Hydrogen_Index"]
    end

    carbon_settings = settings["CarbonSettings"]
    carbon_inputs = inputs["CarbonInputs"]

    dfTru = carbon_inputs["dfTru"]
    dfRoute = carbon_inputs["dfRoute"]

    Transport_map = carbon_inputs["Transport_map"]
    Travel_delay = carbon_inputs["Travel_delay"]
    TRUCK_TYPES = carbon_inputs["TRUCK_TYPES"]
    TRANSPORT_ZONES = carbon_inputs["TRANSPORT_ZONES"]

    R = carbon_inputs["R"]

    ### Variables ###
    ## Truck flow volume [tonne] through type "j" at time "t" on zone "z"
    @variable(MESS, vCTruckFlow[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T])

    ## Number of available full truck type "j" in transit at time "t" on zone "z"
    @variable(MESS, vCAvailFull[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of travel, arrive and deaprt full truck type "j" in transit at time "t" from zone 'zz' to "z"
    @variable(MESS, vCTravelFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vCArriveFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vCDepartFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)

    ## Number of available empty truck type "j" in transit at time "t" on zone "z"
    @variable(MESS, vCAvailEmpty[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)

    ## Number of travel, arrive and deaprt empty truck type "j" in transit at time "t" from zone 'zz' to "z"
    @variable(MESS, vCTravelEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vCArriveEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vCDepartEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)

    ## Number of charged truck type "j" at time "t" on zone "z"
    @variable(MESS, vCLoaded[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of discharged truck type "j" at time "t" on zone "z"
    @variable(MESS, vCUnloaded[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of full truck type "j" at time "t"
    @variable(MESS, vCFull[j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of empty truck type "j" at time "t"
    @variable(MESS, vCEmpty[j in TRUCK_TYPES, t = 1:T] >= 0)

    ### Expressions ###
    ## Objective Expressions ##
    @expression(
        MESS,
        eCObjVarTruOJ[j in TRUCK_TYPES],
        sum(
            weights[t] *
            (
                MESS[:vCArriveFull][r, j, d, t] * dfTru[!, :Var_OM_Cost_Full_per_mile][j] +
                MESS[:vCArriveEmpty][r, j, d, t] * dfTru[!, :Var_OM_Cost_Empty_per_mile][j]
            ) *
            dfRoute[!, :Distance][r] for r in 1:R, d in [-1, 1], t in 1:T;
            init = 0.0,
        )
    )
    @expression(MESS, eCObjVarTru, sum(MESS[:eCObjVarTruOJ][j] for j in TRUCK_TYPES))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eCObj], MESS[:eCObjVarTru])

    ## Operating expenditure for truck carbon compression
    @expression(
        MESS,
        eCObjVarTruCompOJ[j in TRUCK_TYPES],
        sum(
            weights[t] *
            (MESS[:vCTruckFlow][z, j, t] * dfTru[!, :Truck_Comp_Unit_Opex_per_tonne][j]) for
            z in TRANSPORT_ZONES, t in 1:T;
            init = 0.0,
        )
    )
    @expression(MESS, eCObjVarTruComp, sum(MESS[:eCObjVarTruCompOJ][j] for j in TRUCK_TYPES))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eCObj], MESS[:eCObjVarTruComp])
    ## End Objective Expressions ##

    ## Balance Expressions ##
    ## Carbon balance
    @expression(
        MESS,
        eCBalanceTruckFlow[z = 1:Z, t = 1:T],
        begin
            if Zones[z] in TRANSPORT_ZONES
                sum(MESS[:vCTruckFlow][Zones[z], j, t] for j in TRUCK_TYPES; init = 0.0)
            else
                0
            end
        end
    )
    add_to_expression!.(MESS[:eCBalance], MESS[:eCBalanceTruckFlow])
    add_to_expression!.(MESS[:eCTransmission], MESS[:eCBalanceTruckFlow])

    ## Carbon truck traveling hydrogen consumption balance - if truck is fueled by hydrogen
    if settings["ModelHydrogen"] == 1
        @expression(
            MESS,
            eHBalanceCTruckTravel[z = 1:Z, t = 1:T],
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
                        j in TRUCK_TYPES;
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(MESS[:eHBalance], -MESS[:eHBalanceCTruckTravel])
        add_to_expression!.(MESS[:eHDemandAddition], MESS[:eHBalanceCTruckTravel])
    else
        @expression(
            MESS,
            eCHydrogenConsumptionTruckTravel[f in eachindex(Hydrogen_Index), z = 1:Z, t = 1:T],
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
        add_to_expression!.(MESS[:eCHydrogenConsumption], MESS[:eCHydrogenConsumptionTruckTravel])
    end

    ## Carbon truck travelling power consumption balance - if truck is powered by electricity
    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceCTruckTravel[z = 1:Z, t = 1:T],
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
        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceCTruckTravel])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceCTruckTravel])
    else
        @expression(
            MESS,
            eCElectricityConsumptionTruckTravel[
                f in eachindex(Electricity_Index),
                z = 1:Z,
                t = 1:T,
            ],
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
            MESS[:eCElectricityConsumption],
            MESS[:eCElectricityConsumptionTruckTravel],
        )
    end

    ## Carbon truck compression power consumption balance
    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceCTruckComp[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        MESS[:vCLoaded][Zones[z], j, t] *
                        dfTru[!, :Truck_Cap_tonne_per_unit][j] *
                        dfTru[!, :Truck_Comp_Energy_MWh_per_tonne][j] for j in TRUCK_TYPES;
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceCTruckComp])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceCTruckComp])
    else
        @expression(
            MESS,
            eCElectricityConsumptionTruckComp[f in eachindex(Electricity_Index), z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        MESS[:vCLoaded][Zones[z], j, t] *
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
            MESS[:eCElectricityConsumption],
            MESS[:eCElectricityConsumptionTruckComp],
        )
    end

    ## Carbon truck traveling fuel consumption
    @expression(
        MESS,
        eCFuelsConsumptionByTruck[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
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
    add_to_expression!.(MESS[:eCFuelsConsumption], MESS[:eCFuelsConsumptionByTruck])

    ## Carbon truck emission
    @expression(
        MESS,
        eCEmissionsByTruck[z = 1:Z, t = 1:T],
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
    add_to_expression!.(MESS[:eCEmissions], MESS[:eCEmissionsByTruck])
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Total number
    @constraint(
        MESS,
        cCTruckTotalNumber[j in TRUCK_TYPES, t in 1:T],
        MESS[:vCFull][j, t] + MESS[:vCEmpty][j, t] == MESS[:eCTruNumber][j]
    )

    ## The number of total full and empty trucks
    @constraints(
        MESS,
        begin
            cCTruckTotalFull[j in TRUCK_TYPES, t in 1:T],
            MESS[:vCFull][j, t] ==
            sum(MESS[:vCTravelFull][r, j, d, t] for r in 1:R, d in [-1, 1]) +
            sum(MESS[:vCAvailFull][z, j, t] for z in TRANSPORT_ZONES)

            cCTruckTotalEmpty[j in TRUCK_TYPES, t in 1:T],
            MESS[:vCEmpty][j, t] ==
            sum(MESS[:vCTravelEmpty][r, j, d, t] for r in 1:R, d in [-1, 1]) +
            sum(MESS[:vCAvailEmpty][z, j, t] for z in TRANSPORT_ZONES)
        end
    )

    ## Change of the number of full available trucks
    @constraint(
        MESS,
        cCTruckChangeFullAvail[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vCAvailFull][z, j, t] - MESS[:vCAvailFull][z, j, BS1T[t]] ==
        MESS[:vCLoaded][z, j, t] -
        MESS[:vCUnloaded][z, j, hours_before(Period, t, dfTru[!, :Unloading_Time][j])] + sum(
            MESS[:vCArriveFull][
                r,
                j,
                Transport_map[(Transport_map.Zone .== z) .& (Transport_map.route_no .== r), :d][1],
                t,
            ] for r in Transport_map[Transport_map.Zone .== z, :route_no]
        ) - sum(
            MESS[:vCDepartFull][
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
        cCTruckChangeEmptyAvail[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vCAvailEmpty][z, j, t] - MESS[:vCAvailEmpty][z, j, BS1T[t]] ==
        -MESS[:vCLoaded][z, j, hours_before(Period, t, dfTru[!, :Loading_Time][j])] +
        MESS[:vCUnloaded][z, j, t] +
        sum(
            MESS[:vCArriveEmpty][
                r,
                j,
                Transport_map[(Transport_map.Zone .== z) .& (Transport_map.route_no .== r), :d][1],
                t,
            ] for r in Transport_map[Transport_map.Zone .== z, :route_no]
        ) - sum(
            MESS[:vCDepartEmpty][
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
        cCTruckChangeFullTravel[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
        MESS[:vCTravelFull][r, j, d, t] - MESS[:vCTravelFull][r, j, d, BS1T[t]] ==
        MESS[:vCDepartFull][r, j, d, t] - MESS[:vCArriveFull][r, j, d, t]
    )

    ## Change of the number of empty traveling trucks
    @constraint(
        MESS,
        cCTruckChangeEmptyTravel[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
        MESS[:vCTravelEmpty][r, j, d, t] - MESS[:vCTravelEmpty][r, j, d, BS1T[t]] ==
        MESS[:vCDepartEmpty][r, j, d, t] - MESS[:vCArriveEmpty][r, j, d, t]
    )

    ## Travel delay
    @constraints(
        MESS,
        begin
            cCTruckTravelDelayArriveFull[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vCTravelFull][r, j, d, t] >= sum(
                MESS[:vCArriveFull][r, j, d, tt] for tt in (t + 1):(t + Travel_delay[j][r]) if
                t + Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t + Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cCTruckTravelDelayArriveEmpty[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vCTravelEmpty][r, j, d, t] >= sum(
                MESS[:vCArriveEmpty][r, j, d, tt] for tt in (t + 1):(t + Travel_delay[j][r]) if
                t + Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t + Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cCTruckTravelDelayDepartFull[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vCTravelFull][r, j, d, t] >= sum(
                MESS[:vCDepartFull][r, j, d, tt] for tt in (t - Travel_delay[j][r] + 1):t if
                t - Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t - Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cCTruckTravelDelayDepartEmpty[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vCTravelEmpty][r, j, d, t] >= sum(
                MESS[:vCDepartEmpty][r, j, d, tt] for tt in (t - Travel_delay[j][r] + 1):t if
                t - Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t - Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
        end
    )

    ## Capacity constraints
    @constraint(
        MESS,
        cCTruckMaxLoadCap[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vCLoaded][z, j, t] * dfTru[!, :Truck_Cap_tonne_per_unit][j] <= MESS[:eCTruComp][z, j]
    )

    ## Carbon truck flow balance
    @constraint(
        MESS,
        cCTruckFlow[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vCTruckFlow][z, j, t] ==
        MESS[:vCUnloaded][z, j, t] *
        dfTru[!, :Truck_Cap_tonne_per_unit][j] *
        (1 - dfTru[!, :Loss_Percentage_per_mile][j]) -
        MESS[:vCLoaded][z, j, t] * dfTru[!, :Truck_Cap_tonne_per_unit][j]
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
