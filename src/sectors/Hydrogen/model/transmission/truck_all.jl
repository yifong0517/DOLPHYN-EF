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

    print_and_log(settings, "i", "Hydrogen Transmission Truck Core Module")

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

    hydrogen_settings = settings["HydrogenSettings"]
    hydrogen_inputs = inputs["HydrogenInputs"]

    dfTru = hydrogen_inputs["dfTru"]
    dfRoute = hydrogen_inputs["dfRoute"]

    Transport_map = hydrogen_inputs["Transport_map"]
    Travel_delay = hydrogen_inputs["Travel_delay"]
    TRUCK_TYPES = hydrogen_inputs["TRUCK_TYPES"]
    TRANSPORT_ZONES = hydrogen_inputs["TRANSPORT_ZONES"]

    R = hydrogen_inputs["R"]

    ### Variables ###
    ## Truck flow volume [tonne] through type "j" at time "t" on zone "z"
    @variable(MESS, vHTruckFlow[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T])

    ## Number of available full truck type "j" in transit at time "t" on zone "z"
    @variable(MESS, vHAvailFull[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of travel, arrive and deaprt full truck type "j" in transit at time "t" from zone 'zz' to "z"
    @variable(MESS, vHTravelFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vHArriveFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vHDepartFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)

    ## Number of available empty truck type "j" in transit at time "t" on zone "z"
    @variable(MESS, vHAvailEmpty[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)

    ## Number of travel, arrive and deaprt empty truck type "j" in transit at time "t" from zone 'zz' to "z"
    @variable(MESS, vHTravelEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vHArriveEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vHDepartEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)

    ## Number of charged truck type "j" at time "t" on zone "z"
    @variable(MESS, vHLoaded[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of discharged truck type "j" at time "t" on zone "z"
    @variable(MESS, vHUnloaded[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of full truck type "j" at time "t"
    @variable(MESS, vHFull[j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of empty truck type "j" at time "t"
    @variable(MESS, vHEmpty[j in TRUCK_TYPES, t = 1:T] >= 0)

    ### Expressions ###
    ## Objective Expressions ##
    @expression(
        MESS,
        eHObjVarTruOJ[j in TRUCK_TYPES],
        sum(
            weights[t] *
            (
                MESS[:vHArriveFull][r, j, d, t] * dfTru[!, :Var_OM_Cost_Full_per_mile][j] +
                MESS[:vHArriveEmpty][r, j, d, t] * dfTru[!, :Var_OM_Cost_Empty_per_mile][j]
            ) *
            dfRoute[!, :Distance][r] for r in 1:R, d in [-1, 1], t in 1:T;
            init = 0.0,
        )
    )
    @expression(MESS, eHObjVarTru, sum(MESS[:eHObjVarTruOJ][j] for j in TRUCK_TYPES))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eHObj], MESS[:eHObjVarTru])

    ## Operating expenditure for truck hydrogen compression
    @expression(
        MESS,
        eHObjVarTruCompOJ[j in TRUCK_TYPES],
        sum(
            weights[t] *
            (MESS[:vHTruckFlow][z, j, t] * dfTru[!, :Truck_Comp_Unit_Opex_per_tonne][j]) for
            z in TRANSPORT_ZONES, t in 1:T;
            init = 0.0,
        )
    )
    @expression(MESS, eHObjVarTruComp, sum(MESS[:eHObjVarTruCompOJ][j] for j in TRUCK_TYPES))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eHObj], MESS[:eHObjVarTruComp])
    ## End Objective Expressions ##

    ## Balance Expressions ##
    ## Hydrogen balance
    @expression(
        MESS,
        eHBalanceTruckFlow[z = 1:Z, t = 1:T],
        begin
            if Zones[z] in TRANSPORT_ZONES
                sum(MESS[:vHTruckFlow][Zones[z], j, t] for j in TRUCK_TYPES; init = 0.0)
            else
                0
            end
        end
    )
    add_to_expression!.(MESS[:eHBalance], MESS[:eHBalanceTruckFlow])
    add_to_expression!.(MESS[:eHTransmission], MESS[:eHBalanceTruckFlow])

    ## Hydrogen truck traveling hydrogen consumption balance - if truck is fueled by hydrogen
    if any(dfTru.H2_tonne_per_mile .> 0)
        @expression(
            MESS,
            eHBalanceTruckTravel[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vHArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vHArriveEmpty][
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

        add_to_expression!.(MESS[:eHBalance], -MESS[:eHBalanceTruckTravel])
        add_to_expression!.(MESS[:eHTransmission], -MESS[:eHBalanceTruckTravel])
    end

    ## Hydrogen truck travelling power consumption balance - if truck is powered by electricity

    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceHTruckTravel[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vHArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vHArriveEmpty][
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
        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceHTruckTravel])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceHTruckTravel])
    else
        @expression(
            MESS,
            eHElectricityConsumptionTruckTravel[
                f in eachindex(Electricity_Index),
                z = 1:Z,
                t = 1:T,
            ],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vHArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vHArriveEmpty][
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
            MESS[:eHElectricityConsumption],
            MESS[:eHElectricityConsumptionTruckTravel],
        )
    end

    ## Hydrogen truck compression power consumption balance
    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceHTruckComp[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        MESS[:vHLoaded][Zones[z], j, t] *
                        dfTru[!, :Truck_Cap_tonne_per_unit][j] *
                        dfTru[!, :Truck_Comp_Energy_MWh_per_tonne][j] for j in TRUCK_TYPES;
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceHTruckComp])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceHTruckComp])
    else
        @expression(
            MESS,
            eHElectricityConsumptionTruckComp[f in eachindex(Electricity_Index), z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        MESS[:vHLoaded][Zones[z], j, t] *
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
            MESS[:eHElectricityConsumption],
            MESS[:eHElectricityConsumptionTruckComp],
        )
    end

    ## Hydrogen truck traveling fuel consumption
    if settings["ModelFuels"] == 1
        @expression(
            MESS,
            eHFuelsConsumptionByTruck[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vHArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vHArriveEmpty][
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
        add_to_expression!.(MESS[:eHFuelsConsumption], MESS[:eHFuelsConsumptionByTruck])

        ## Hydrogen truck emission
        @expression(
            MESS,
            eHEmissionsByTruck[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRANSPORT_ZONES
                    sum(
                        (
                            MESS[:vHArriveFull][
                                r,
                                j,
                                Transport_map[
                                    (Transport_map.Zone .== Zones[z]) .& (Transport_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ] + MESS[:vHArriveEmpty][
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
        add_to_expression!.(MESS[:eHEmissions], MESS[:eHEmissionsByTruck])
    end
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Total number
    @constraint(
        MESS,
        cHTruckTotalNumber[j in TRUCK_TYPES, t in 1:T],
        MESS[:vHFull][j, t] + MESS[:vHEmpty][j, t] == MESS[:eHTruNumber][j]
    )

    ## The number of total full and empty trucks
    @constraints(
        MESS,
        begin
            cHTruckTotalFull[j in TRUCK_TYPES, t in 1:T],
            MESS[:vHFull][j, t] ==
            sum(MESS[:vHTravelFull][r, j, d, t] for r in 1:R, d in [-1, 1]) +
            sum(MESS[:vHAvailFull][z, j, t] for z in TRANSPORT_ZONES)

            cHTruckTotalEmpty[j in TRUCK_TYPES, t in 1:T],
            MESS[:vHEmpty][j, t] ==
            sum(MESS[:vHTravelEmpty][r, j, d, t] for r in 1:R, d in [-1, 1]) +
            sum(MESS[:vHAvailEmpty][z, j, t] for z in TRANSPORT_ZONES)
        end
    )

    ## Change of the number of full available trucks
    @constraint(
        MESS,
        cHTruckChangeFullAvail[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vHAvailFull][z, j, t] - MESS[:vHAvailFull][z, j, BS1T[t]] ==
        MESS[:vHLoaded][z, j, t] -
        MESS[:vHUnloaded][z, j, hours_before(Period, t, dfTru[!, :Unloading_Time][j])] + sum(
            MESS[:vHArriveFull][
                r,
                j,
                Transport_map[(Transport_map.Zone .== z) .& (Transport_map.route_no .== r), :d][1],
                t,
            ] for r in Transport_map[Transport_map.Zone .== z, :route_no]
        ) - sum(
            MESS[:vHDepartFull][
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
        cHTruckChangeEmptyAvail[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vHAvailEmpty][z, j, t] - MESS[:vHAvailEmpty][z, j, BS1T[t]] ==
        -MESS[:vHLoaded][z, j, hours_before(Period, t, dfTru[!, :Loading_Time][j])] +
        MESS[:vHUnloaded][z, j, t] +
        sum(
            MESS[:vHArriveEmpty][
                r,
                j,
                Transport_map[(Transport_map.Zone .== z) .& (Transport_map.route_no .== r), :d][1],
                t,
            ] for r in Transport_map[Transport_map.Zone .== z, :route_no]
        ) - sum(
            MESS[:vHDepartEmpty][
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
        cHTruckChangeFullTravel[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
        MESS[:vHTravelFull][r, j, d, t] - MESS[:vHTravelFull][r, j, d, BS1T[t]] ==
        MESS[:vHDepartFull][r, j, d, t] - MESS[:vHArriveFull][r, j, d, t]
    )

    ## Change of the number of empty traveling trucks
    @constraint(
        MESS,
        cHTruckChangeEmptyTravel[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
        MESS[:vHTravelEmpty][r, j, d, t] - MESS[:vHTravelEmpty][r, j, d, BS1T[t]] ==
        MESS[:vHDepartEmpty][r, j, d, t] - MESS[:vHArriveEmpty][r, j, d, t]
    )

    ## Travel delay
    @constraints(
        MESS,
        begin
            cHTruckTravelDelayArriveFull[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vHTravelFull][r, j, d, t] >= sum(
                MESS[:vHArriveFull][r, j, d, tt] for tt in (t + 1):(t + Travel_delay[j][r]) if
                t + Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t + Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cHTruckTravelDelayArriveEmpty[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vHTravelEmpty][r, j, d, t] >= sum(
                MESS[:vHArriveEmpty][r, j, d, tt] for tt in (t + 1):(t + Travel_delay[j][r]) if
                t + Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t + Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cHTruckTravelDelayDepartFull[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vHTravelFull][r, j, d, t] >= sum(
                MESS[:vHDepartFull][r, j, d, tt] for tt in (t - Travel_delay[j][r] + 1):t if
                t - Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t - Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cHTruckTravelDelayDepartEmpty[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vHTravelEmpty][r, j, d, t] >= sum(
                MESS[:vHDepartEmpty][r, j, d, tt] for tt in (t - Travel_delay[j][r] + 1):t if
                t - Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t - Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
        end
    )

    ## Capacity constraints
    @constraint(
        MESS,
        cHTruckMaxLoadCap[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vHLoaded][z, j, t] * dfTru[!, :Truck_Cap_tonne_per_unit][j] <= MESS[:eHTruComp][z, j]
    )

    ## Hydrogen truck flow balance
    @constraint(
        MESS,
        cHTruckFlow[z in TRANSPORT_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vHTruckFlow][z, j, t] ==
        MESS[:vHUnloaded][z, j, t] *
        dfTru[!, :Truck_Cap_tonne_per_unit][j] *
        (1 - dfTru[!, :Loss_Percentage_per_mile][j]) -
        MESS[:vHLoaded][z, j, t] * dfTru[!, :Truck_Cap_tonne_per_unit][j]
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
