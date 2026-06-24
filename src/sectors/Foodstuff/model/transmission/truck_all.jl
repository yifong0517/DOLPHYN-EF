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

    print_and_log(settings, "i", "Foodstuff Transmission Truck Core Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    ## Feedstock list
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

    foodstuff_settings = settings["FoodstuffSettings"]
    foodstuff_inputs = inputs["FoodstuffInputs"]

    Foods = foodstuff_inputs["Foods"]

    dfTru = foodstuff_inputs["dfTru"]
    dfRoute = foodstuff_inputs["dfRoute"]

    Truck_map = foodstuff_inputs["Truck_map"]
    Travel_delay = foodstuff_inputs["Travel_delay"]
    TRUCK_TYPES = foodstuff_inputs["TRUCK_TYPES"]
    TRUCK_ZONES = foodstuff_inputs["TRUCK_ZONES"]

    R = foodstuff_inputs["R"]

    ### Variables ###
    ## Truck flow volume [tonne] through type "j" at time "t" on zone "z"
    @variable(
        MESS,
        vFTruckFlow[z in TRUCK_ZONES, j in TRUCK_TYPES, fs in eachindex(Foods), t = 1:T]
    )

    ## Number of available full truck type "j" in transit at time "t" on zone "z"
    @variable(
        MESS,
        vFAvailFull[z in TRUCK_ZONES, j in TRUCK_TYPES, fs in eachindex(Foods), t = 1:T] >= 0
    )
    ## Number of travel, arrive and deaprt full truck type "j" in transit at time "t" from zone 'zz' to "z"
    @variable(
        MESS,
        vFTravelFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], fs in eachindex(Foods), t = 1:T] >= 0
    )
    @variable(
        MESS,
        vFArriveFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], fs in eachindex(Foods), t = 1:T] >= 0
    )
    @variable(
        MESS,
        vFDepartFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], fs in eachindex(Foods), t = 1:T] >= 0
    )

    ## Number of available empty truck type "j" in transit at time "t" on zone "z"
    @variable(MESS, vFAvailEmpty[z in TRUCK_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)

    ## Number of travel, arrive and deaprt empty truck type "j" in transit at time "t" from zone 'zz' to "z"
    @variable(MESS, vFTravelEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vFArriveEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vFDepartEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)

    ## Number of loaded truck type "j" at time "t" on zone "z"
    @variable(
        MESS,
        vFLoaded[z in TRUCK_ZONES, j in TRUCK_TYPES, fs in eachindex(Foods), t = 1:T] >= 0
    )
    ## Number of unloaded truck type "j" at time "t" on zone "z"
    @variable(MESS, vFUnloaded[z in TRUCK_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of full truck type "j" at time "t"
    @variable(MESS, vFFull[j in TRUCK_TYPES, fs in eachindex(Foods), t = 1:T] >= 0)
    ## Number of empty truck type "j" at time "t"
    @variable(MESS, vFEmpty[j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of unloaded truck type "j" at time "t" on zone "z" from food "fs"
    @variable(
        MESS,
        vFUnloadedOverCrops[z in TRUCK_ZONES, j in TRUCK_TYPES, fs in eachindex(Foods), t in 1:T] >=
        0
    )

    ### Expressions ###
    ## Objective Expressions ##
    ## Variable cost of trucks
    @expression(
        MESS,
        eFObjVarTru,
        sum(
            weights[t] *
            (
                sum(MESS[:vFArriveFull][r, j, d, fs, t] for fs in eachindex(Foods)) *
                dfTru[!, :Var_OM_Cost_Full_per_mile][j] +
                MESS[:vFArriveEmpty][r, j, d, t] * dfTru[!, :Var_OM_Cost_Empty_per_mile][j]
            ) *
            dfRoute[!, :Distance][r] for r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T;
            init = 0.0,
        )
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eFObj], MESS[:eFObjVarTru])
    ## End Objective Expressions ##

    ## Balance Expressions ##
    ## Food balance
    @expression(
        MESS,
        eFBalanceTruckZonalFlow[z = 1:Z, fs in eachindex(Foods), t = 1:T],
        begin
            if Zones[z] in TRUCK_ZONES
                sum(MESS[:vFTruckFlow][Zones[z], j, fs, t] for j in TRUCK_TYPES; init = 0.0)
            else
                0
            end
        end
    )
    add_to_expression!.(MESS[:eFBalance], MESS[:eFBalanceTruckZonalFlow])
    add_to_expression!.(MESS[:eFTransmission], MESS[:eFBalanceTruckZonalFlow])
    ## End Balance Expressions ##

    ## Food truck traveling hydrogen consumption balance - if truck is fueled by hydrogen
    if settings["ModelHydrogen"] == 1
        @expression(
            MESS,
            eHBalanceFTruckTravel[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRUCK_ZONES
                    sum(
                        (
                            sum(
                                MESS[:vFArriveFull][
                                    r,
                                    j,
                                    Truck_map[
                                        (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                        :d,
                                    ][1],
                                    fs,
                                    t,
                                ] for fs in eachindex(Foods)
                            ) + MESS[:vFArriveEmpty][
                                r,
                                j,
                                Truck_map[
                                    (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ]
                        ) *
                        dfTru[!, :H2_tonne_per_mile][j] *
                        dfRoute[!, :Distance][r] for
                        r in Truck_map[Truck_map.Zone .== Zones[z], :route_no], j in TRUCK_TYPES;
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(MESS[:eHBalance], -MESS[:eHBalanceFTruckTravel])
        add_to_expression!.(MESS[:eHDemandAddition], MESS[:eHBalanceFTruckTravel])
    else
        @expression(
            MESS,
            eFHydrogenConsumptionTruckTravel[f in eachindex(Hydrogen_Index), z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRUCK_ZONES
                    sum(
                        (
                            sum(
                                MESS[:vFArriveFull][
                                    r,
                                    j,
                                    Truck_map[
                                        (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                        :d,
                                    ][1],
                                    fs,
                                    t,
                                ] for fs in eachindex(Foods)
                            ) + MESS[:vFArriveEmpty][
                                r,
                                j,
                                Truck_map[
                                    (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ]
                        ) *
                        dfTru[!, :H2_tonne_per_mile][j] *
                        dfRoute[!, :Distance][r] for
                        r in Truck_map[Truck_map.Zone .== Zones[z], :route_no],
                        j in dfTru[dfTru.Hydrogen .== Hydrogen_Index[f], :T_ID];
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(MESS[:eFHydrogenConsumption], MESS[:eFHydrogenConsumptionTruckTravel])
    end

    ## Food truck travelling power consumption balance - if truck is powered by electricity
    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceFTruckTravel[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRUCK_ZONES
                    sum(
                        (
                            sum(
                                MESS[:vFArriveFull][
                                    r,
                                    j,
                                    Truck_map[
                                        (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                        :d,
                                    ][1],
                                    fs,
                                    t,
                                ] for fs in eachindex(Foods)
                            ) + MESS[:vFArriveEmpty][
                                r,
                                j,
                                Truck_map[
                                    (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ]
                        ) *
                        dfTru[!, :Electricity_MWh_per_mile][j] *
                        dfRoute[!, :Distance][r] for
                        r in Truck_map[Truck_map.Zone .== Zones[z], :route_no], j in TRUCK_TYPES;
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceFTruckTravel])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceFTruckTravel])
    else
        @expression(
            MESS,
            eFElectricityConsumptionTruckTravel[
                f in eachindex(Electricity_Index),
                z = 1:Z,
                t = 1:T,
            ],
            begin
                if Zones[z] in TRUCK_ZONES
                    sum(
                        (
                            sum(
                                MESS[:vFArriveFull][
                                    r,
                                    j,
                                    Truck_map[
                                        (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                        :d,
                                    ][1],
                                    fs,
                                    t,
                                ] for fs in eachindex(Foods)
                            ) + MESS[:vFArriveEmpty][
                                r,
                                j,
                                Truck_map[
                                    (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ]
                        ) *
                        dfTru[!, :Electricity_MWh_per_mile][j] *
                        dfRoute[!, :Distance][r] for
                        r in Truck_map[Truck_map.Zone .== Zones[z], :route_no],
                        j in dfTru[dfTru.Electricity .== Electricity_Index[f], :T_ID];
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(
            MESS[:eFElectricityConsumption],
            MESS[:eFElectricityConsumptionTruckTravel],
        )
    end

    ## Food truck traveling fuel consumption
    if settings["ModelFuels"] == 1
        @expression(
            MESS,
            eFFuelsConsumptionByTruck[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            begin
                if Zones[z] in TRUCK_ZONES
                    sum(
                        (
                            sum(
                                MESS[:vFArriveFull][
                                    r,
                                    j,
                                    Truck_map[
                                        (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                        :d,
                                    ][1],
                                    f,
                                    t,
                                ],
                            ) + MESS[:vFArriveEmpty][
                                r,
                                j,
                                Truck_map[
                                    (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ]
                        ) *
                        dfTru[!, :Fuel_MMBTU_per_mile][j] *
                        dfRoute[!, :Distance][r] for
                        r in Truck_map[Truck_map.Zone .== Zones[z], :route_no],
                        j in dfTru[dfTru.Fuel .== Fuels_Index[f], :T_ID];
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(MESS[:eFFuelsConsumption], MESS[:eFFuelsConsumptionByTruck])

        ## Food truck emission
        @expression(
            MESS,
            eFEmissionsFoodTruckTravel[z in 1:Z, t = 1:T],
            begin
                if Zones[z] in TRUCK_ZONES
                    sum(
                        (
                            sum(
                                MESS[:vFArriveFull][
                                    r,
                                    j,
                                    Truck_map[
                                        (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                        :d,
                                    ][1],
                                    fs,
                                    t,
                                ] for fs in eachindex(Foods)
                            ) + MESS[:vFArriveEmpty][
                                r,
                                j,
                                Truck_map[
                                    (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                    :d,
                                ][1],
                                t,
                            ]
                        ) *
                        fuels_CO2[dfTru[!, :Fuel][j]] *
                        dfTru[!, :Fuel_MMBTU_per_mile][j] *
                        dfRoute[!, :Distance][r] for
                        r in Truck_map[Truck_map.Zone .== Zones[z], :route_no],
                        j in filter(:Fuel => in(Fuels_Index), dfTru)[!, :T_ID];
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(MESS[:eFEmissions], MESS[:eFEmissionsFoodTruckTravel])
    end
    ### End Expressions ###

    ### Constraints ###
    ## Total number
    @constraint(
        MESS,
        cFTruckTotalNumber[j in TRUCK_TYPES, t in 1:T],
        sum(MESS[:vFFull][j, fs, t] for fs in eachindex(Foods)) + MESS[:vFEmpty][j, t] ==
        MESS[:eFTruNumber][j]
    )

    ## The number of total full and empty trucks.
    @constraints(
        MESS,
        begin
            cFTruckTotalFull[j in TRUCK_TYPES, fs in eachindex(Foods), t in 1:T],
            MESS[:vFFull][j, fs, t] ==
            sum(MESS[:vFTravelFull][r, j, d, fs, t] for r in 1:R, d in [-1, 1]) +
            sum(MESS[:vFAvailFull][z, j, fs, t] for z in TRUCK_ZONES)

            cFTruckTotalEmpty[j in TRUCK_TYPES, t in 1:T],
            MESS[:vFEmpty][j, t] ==
            sum(MESS[:vFTravelEmpty][r, j, d, t] for r in 1:R, d in [-1, 1]) +
            sum(MESS[:vFAvailEmpty][z, j, t] for z in TRUCK_ZONES)
        end
    )

    ## Change of the number of full available trucks
    @constraint(
        MESS,
        cFTruckChangeFullAvail[
            z in TRUCK_ZONES,
            j in TRUCK_TYPES,
            fs in eachindex(Foods),
            t in 1:T,
        ],
        MESS[:vFAvailFull][z, j, fs, t] - MESS[:vFAvailFull][z, j, fs, BS1T[t]] ==
        MESS[:vFLoaded][z, j, fs, t] - MESS[:vFUnloadedOverCrops][
            z,
            j,
            fs,
            hours_before(Period, t, dfTru[!, :Unloading_Time][j]),
        ] + sum(
            MESS[:vFArriveFull][
                r,
                j,
                Truck_map[(Truck_map.Zone .== z) .& (Truck_map.route_no .== r), :d][1],
                fs,
                t,
            ] for r in Truck_map[Truck_map.Zone .== z, :route_no]
        ) - sum(
            MESS[:vFDepartFull][
                r,
                j,
                Truck_map[(Truck_map.Zone .== z) .& (Truck_map.route_no .== r), :d][1],
                fs,
                t,
            ] for r in Truck_map[Truck_map.Zone .== z, :route_no]
        )
    )

    ## Unloaded truck from crop type "cs" will be available for other type of crops
    @constraint(
        MESS,
        cFTotalUnloaded[z in TRUCK_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vFUnloaded][z, j, t] ==
        sum(MESS[:vFUnloadedOverCrops][z, j, fs, t] for fs in eachindex(Foods))
    )

    ## Change of the number of empty available trucks
    @constraint(
        MESS,
        cFTruckChangeEmptyAvail[z in TRUCK_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vFAvailEmpty][z, j, t] - MESS[:vFAvailEmpty][z, j, BS1T[t]] ==
        -sum(
            MESS[:vFLoaded][z, j, fs, hours_before(Period, t, dfTru[!, :Loading_Time][j])] for
            fs in eachindex(Foods)
        ) +
        MESS[:vFUnloaded][z, j, t] +
        sum(
            MESS[:vFArriveEmpty][
                r,
                j,
                Truck_map[(Truck_map.Zone .== z) .& (Truck_map.route_no .== r), :d][1],
                t,
            ] for r in Truck_map[Truck_map.Zone .== z, :route_no]
        ) - sum(
            MESS[:vFDepartEmpty][
                r,
                j,
                Truck_map[(Truck_map.Zone .== z) .& (Truck_map.route_no .== r), :d][1],
                t,
            ] for r in Truck_map[Truck_map.Zone .== z, :route_no]
        )
    )

    ## Change of the number of full traveling trucks
    @constraint(
        MESS,
        cFTruckChangeFullTravel[
            r in 1:R,
            j in TRUCK_TYPES,
            d in [-1, 1],
            fs in eachindex(Foods),
            t in 1:T,
        ],
        MESS[:vFTravelFull][r, j, d, fs, t] - MESS[:vFTravelFull][r, j, d, fs, BS1T[t]] ==
        MESS[:vFDepartFull][r, j, d, fs, t] - MESS[:vFArriveFull][r, j, d, fs, t]
    )

    ## Change of the number of empty traveling trucks
    @constraint(
        MESS,
        cFTruckChangeEmptyTravel[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
        MESS[:vFTravelEmpty][r, j, d, t] - MESS[:vFTravelEmpty][r, j, d, BS1T[t]] ==
        MESS[:vFDepartEmpty][r, j, d, t] - MESS[:vFArriveEmpty][r, j, d, t]
    )

    ## Travel delay
    @constraints(
        MESS,
        begin
            cFTruckTravelDelayArriveFull[
                r in 1:R,
                j in TRUCK_TYPES,
                d in [-1, 1],
                fs in eachindex(Foods),
                t in 1:T,
            ],
            MESS[:vFTravelFull][r, j, d, fs, t] >= sum(
                MESS[:vFArriveFull][r, j, d, fs, tt] for tt in (t + 1):(t + Travel_delay[j][r]) if
                t + Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t + Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cFTruckTravelDelayArriveEmpty[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vFTravelEmpty][r, j, d, t] >= sum(
                MESS[:vFArriveEmpty][r, j, d, tt] for tt in (t + Travel_delay[j][r] + 1):t if
                t + Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t + Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cFTruckTravelDelayDepartFull[
                r in 1:R,
                j in TRUCK_TYPES,
                d in [-1, 1],
                fs in eachindex(Foods),
                t in 1:T,
            ],
            MESS[:vFTravelFull][r, j, d, fs, t] >= sum(
                MESS[:vFDepartFull][r, j, d, fs, tt] for tt in (t + 1):(t - Travel_delay[j][r]) if
                t - Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t - Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cFTruckTravelDelayDepartEmpty[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vFTravelEmpty][r, j, d, t] >= sum(
                MESS[:vFDepartEmpty][r, j, d, tt] for tt in (t - Travel_delay[j][r] + 1):t if
                t - Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t - Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
        end
    )

    ## Food truck flow balance.
    @constraint(
        MESS,
        cFFoodTruckFlow[z in TRUCK_ZONES, j in TRUCK_TYPES, fs in eachindex(Foods), t in 1:T],
        MESS[:vFTruckFlow][z, j, fs, t] ==
        MESS[:vFUnloadedOverCrops][z, j, fs, t] *
        dfTru[!, :Truck_Cap_tonne_per_unit][j] *
        (1 - dfTru[!, :Loss_Percentage_per_mile][j]) -
        MESS[:vFLoaded][z, j, fs, t] * dfTru[!, :Truck_Cap_tonne_per_unit][j]
    )
    ### End Constraints ###

    return MESS
end
