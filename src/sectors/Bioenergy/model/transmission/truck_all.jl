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

    print_and_log(settings, "i", "Bioenergy Transmission Truck Core Module")

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

    bioenergy_settings = settings["BioenergySettings"]
    bioenergy_inputs = inputs["BioenergyInputs"]

    Residuals = bioenergy_inputs["Residuals"]

    dfTru = bioenergy_inputs["dfTru"]
    dfRoute = bioenergy_inputs["dfRoute"]

    Truck_map = bioenergy_inputs["Truck_map"]
    Travel_delay = bioenergy_inputs["Travel_delay"]
    TRUCK_TYPES = bioenergy_inputs["TRUCK_TYPES"]
    TRUCK_ZONES = bioenergy_inputs["TRUCK_ZONES"]

    R = bioenergy_inputs["R"]
    ### Variables ###
    ## Truck flow volume [tonne] through type "j" at time "t" on zone "z"
    @variable(
        MESS,
        vBTruckFlow[z in TRUCK_ZONES, j in TRUCK_TYPES, rs in eachindex(Residuals), t = 1:T]
    )

    ## Number of available full truck type "j" in transit at time "t" on zone "z"
    @variable(
        MESS,
        vBAvailFull[z in TRUCK_ZONES, j in TRUCK_TYPES, rs in eachindex(Residuals), t = 1:T] >= 0
    )
    ## Number of travel, arrive and deaprt full truck type "j" in transit at time "t" from zone 'zz' to "z"
    @variable(
        MESS,
        vBTravelFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], rs in eachindex(Residuals), t = 1:T] >=
        0
    )
    @variable(
        MESS,
        vBArriveFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], rs in eachindex(Residuals), t = 1:T] >=
        0
    )
    @variable(
        MESS,
        vBDepartFull[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], rs in eachindex(Residuals), t = 1:T] >=
        0
    )

    ## Number of available empty truck type "j" in transit at time "t" on zone "z"
    @variable(MESS, vBAvailEmpty[z in TRUCK_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)

    ## Number of travel, arrive and deaprt empty truck type "j" in transit at time "t" from zone 'zz' to "z"
    @variable(MESS, vBTravelEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vBArriveEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)
    @variable(MESS, vBDepartEmpty[r = 1:R, j in TRUCK_TYPES, d = [-1, 1], t = 1:T] >= 0)

    ## Number of loaded truck type "j" at time "t" on zone "z"
    @variable(
        MESS,
        vBLoaded[z in TRUCK_ZONES, j in TRUCK_TYPES, rs in eachindex(Residuals), t = 1:T] >= 0
    )
    ## Number of unloaded truck type "j" at time "t" on zone "z"
    @variable(MESS, vBUnloaded[z in TRUCK_ZONES, j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of full truck type "j" at time "t"
    @variable(MESS, vBFull[j in TRUCK_TYPES, rs in eachindex(Residuals), t = 1:T] >= 0)
    ## Number of empty truck type "j" at time "t"
    @variable(MESS, vBEmpty[j in TRUCK_TYPES, t = 1:T] >= 0)
    ## Number of unloaded truck type "j" at time "t" on zone "z" from residual 'rs'
    @variable(
        MESS,
        vBUnloadedOverCrops[
            z in TRUCK_ZONES,
            j in TRUCK_TYPES,
            rs in eachindex(Residuals),
            t in 1:T,
        ] >= 0
    )

    ### Expressions ###
    ## Objective Expressions ##
    ## Variable cost of trucks
    @expression(
        MESS,
        eBObjVarTru,
        sum(
            weights[t] *
            (
                sum(MESS[:vBArriveFull][r, j, d, rs, t] for rs in eachindex(Residuals)) *
                dfTru[!, :Var_OM_Cost_Full_per_mile][j] +
                MESS[:vBArriveEmpty][r, j, d, t] * dfTru[!, :Var_OM_Cost_Empty_per_mile][j]
            ) *
            dfRoute[!, :Distance][r] for r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T;
            init = 0.0,
        )
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eBObj], MESS[:eBObjVarTru])
    ## End Objective Expressions ##

    ## Balance Expressions ##
    ## Residual balance
    @expression(
        MESS,
        eBBalanceTruckZonalFlow[z = 1:Z, rs in eachindex(Residuals), t = 1:T],
        begin
            if Zones[z] in TRUCK_ZONES
                sum(MESS[:vBTruckFlow][Zones[z], j, rs, t] for j in TRUCK_TYPES; init = 0.0)
            else
                0
            end
        end
    )
    add_to_expression!.(MESS[:eBBalance], MESS[:eBBalanceTruckZonalFlow])
    add_to_expression!.(MESS[:eBTransmission], MESS[:eBBalanceTruckZonalFlow])

    ## Residual truck traveling hydrogen consumption balance - if truck is fueled by hydrogen
    if settings["ModelHydrogen"] == 1
        @expression(
            MESS,
            eHBalanceBTruckTravel[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRUCK_ZONES
                    sum(
                        (
                            sum(
                                MESS[:vBArriveFull][
                                    r,
                                    j,
                                    Truck_map[
                                        (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                        :d,
                                    ][1],
                                    rs,
                                    t,
                                ] for rs in eachindex(Residuals)
                            ) + MESS[:vBArriveEmpty][
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
        add_to_expression!.(MESS[:eHBalance], -MESS[:eHBalanceBTruckTravel])
        add_to_expression!.(MESS[:eHDemandAddition], MESS[:eHBalanceBTruckTravel])
    else
        @expression(
            MESS,
            eBHydrogenConsumptionTruckTravel[f in eachindex(Hydrogen_Index), z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRUCK_ZONES
                    sum(
                        (
                            sum(
                                MESS[:vBArriveFull][
                                    r,
                                    j,
                                    Truck_map[
                                        (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                        :d,
                                    ][1],
                                    rs,
                                    t,
                                ] for rs in eachindex(Residuals)
                            ) + MESS[:vBArriveEmpty][
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
        add_to_expression!.(MESS[:eBHydrogenConsumption], MESS[:eBHydrogenConsumptionTruckTravel])
    end

    ## Residual truck travelling power consumption balance - if truck is powered by electricity
    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceBTruckTravel[z = 1:Z, t = 1:T],
            begin
                if Zones[z] in TRUCK_ZONES
                    sum(
                        (
                            sum(
                                MESS[:vBArriveFull][
                                    r,
                                    j,
                                    Truck_map[
                                        (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                        :d,
                                    ][1],
                                    rs,
                                    t,
                                ] for rs in eachindex(Residuals)
                            ) + MESS[:vBArriveEmpty][
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
        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceBTruckTravel])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceBTruckTravel])
    else
        @expression(
            MESS,
            eBElectricityConsumptionTruckTravel[
                f in eachindex(Electricity_Index),
                z = 1:Z,
                t = 1:T,
            ],
            begin
                if Zones[z] in TRUCK_ZONES
                    sum(
                        (
                            sum(
                                MESS[:vBArriveFull][
                                    r,
                                    j,
                                    Truck_map[
                                        (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                        :d,
                                    ][1],
                                    rs,
                                    t,
                                ] for rs in eachindex(Residuals)
                            ) + MESS[:vBArriveEmpty][
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
            MESS[:eBElectricityConsumption],
            MESS[:eBElectricityConsumptionTruckTravel],
        )
    end

    ## Residual truck traveling fuel consumption
    if settings["ModelFuels"] == 1
        @expression(
            MESS,
            eBFuelsConsumptionByTruck[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            begin
                if Zones[z] in TRUCK_ZONES
                    sum(
                        (
                            sum(
                                MESS[:vBArriveFull][
                                    r,
                                    j,
                                    Truck_map[
                                        (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                        :d,
                                    ][1],
                                    f,
                                    t,
                                ],
                            ) + MESS[:vBArriveEmpty][
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
        add_to_expression!.(MESS[:eBFuelsConsumption], MESS[:eBFuelsConsumptionByTruck])

        ## Residual truck emission
        @expression(
            MESS,
            eBEmissionsResidualTruckTravel[z in 1:Z, t = 1:T],
            begin
                if Zones[z] in TRUCK_ZONES
                    sum(
                        (
                            sum(
                                MESS[:vBArriveFull][
                                    r,
                                    j,
                                    Truck_map[
                                        (Truck_map.Zone .== Zones[z]) .& (Truck_map.route_no .== r),
                                        :d,
                                    ][1],
                                    rs,
                                    t,
                                ] for rs in eachindex(Residuals)
                            ) + MESS[:vBArriveEmpty][
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
        add_to_expression!.(MESS[:eBEmissions], MESS[:eBEmissionsResidualTruckTravel])
    end
    ### End Expressions ###

    ### Constraints ###
    ## Total number
    @constraint(
        MESS,
        cBTruckTotalNumber[j in TRUCK_TYPES, t in 1:T],
        sum(MESS[:vBFull][j, rs, t] for rs in eachindex(Residuals)) + MESS[:vBEmpty][j, t] ==
        MESS[:eBTruNumber][j]
    )

    ## The number of total full and empty trucks.
    @constraints(
        MESS,
        begin
            cBTruckTotalFull[j in TRUCK_TYPES, rs in eachindex(Residuals), t in 1:T],
            MESS[:vBFull][j, rs, t] ==
            sum(MESS[:vBTravelFull][r, j, d, rs, t] for r in 1:R, d in [-1, 1]) +
            sum(MESS[:vBAvailFull][z, j, rs, t] for z in TRUCK_ZONES)

            cBTruckTotalEmpty[j in TRUCK_TYPES, t in 1:T],
            MESS[:vBEmpty][j, t] ==
            sum(MESS[:vBTravelEmpty][r, j, d, t] for r in 1:R, d in [-1, 1]) +
            sum(MESS[:vBAvailEmpty][z, j, t] for z in TRUCK_ZONES)
        end
    )

    ## Change of the number of full available trucks
    @constraint(
        MESS,
        cBTruckChangeFullAvail[
            z in TRUCK_ZONES,
            j in TRUCK_TYPES,
            rs in eachindex(Residuals),
            t in 1:T,
        ],
        MESS[:vBAvailFull][z, j, rs, t] - MESS[:vBAvailFull][z, j, rs, BS1T[t]] ==
        MESS[:vBLoaded][z, j, rs, t] - MESS[:vBUnloadedOverCrops][
            z,
            j,
            rs,
            hours_before(Period, t, dfTru[!, :Unloading_Time][j]),
        ] + sum(
            MESS[:vBArriveFull][
                r,
                j,
                Truck_map[(Truck_map.Zone .== z) .& (Truck_map.route_no .== r), :d][1],
                rs,
                t,
            ] for r in Truck_map[Truck_map.Zone .== z, :route_no]
        ) - sum(
            MESS[:vBDepartFull][
                r,
                j,
                Truck_map[(Truck_map.Zone .== z) .& (Truck_map.route_no .== r), :d][1],
                rs,
                t,
            ] for r in Truck_map[Truck_map.Zone .== z, :route_no]
        )
    )

    ## Unloaded truck from residual type 'rs' will be available for other type of residuals
    @constraint(
        MESS,
        cBTotalUnloaded[z in TRUCK_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vBUnloaded][z, j, t] ==
        sum(MESS[:vBUnloadedOverCrops][z, j, rs, t] for rs in eachindex(Residuals))
    )

    ## Change of the number of empty available trucks
    @constraint(
        MESS,
        cBTruckChangeEmptyAvail[z in TRUCK_ZONES, j in TRUCK_TYPES, t in 1:T],
        MESS[:vBAvailEmpty][z, j, t] - MESS[:vBAvailEmpty][z, j, BS1T[t]] ==
        -sum(
            MESS[:vBLoaded][z, j, rs, hours_before(Period, t, dfTru[!, :Loading_Time][j])] for
            rs in eachindex(Residuals)
        ) +
        MESS[:vBUnloaded][z, j, t] +
        sum(
            MESS[:vBArriveEmpty][
                r,
                j,
                Truck_map[(Truck_map.Zone .== z) .& (Truck_map.route_no .== r), :d][1],
                t,
            ] for r in Truck_map[Truck_map.Zone .== z, :route_no]
        ) - sum(
            MESS[:vBDepartEmpty][
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
        cBTruckChangeFullTravel[
            r in 1:R,
            j in TRUCK_TYPES,
            d in [-1, 1],
            rs in eachindex(Residuals),
            t in 1:T,
        ],
        MESS[:vBTravelFull][r, j, d, rs, t] - MESS[:vBTravelFull][r, j, d, rs, BS1T[t]] ==
        MESS[:vBDepartFull][r, j, d, rs, t] - MESS[:vBArriveFull][r, j, d, rs, t]
    )

    ## Change of the number of empty traveling trucks
    @constraint(
        MESS,
        cBTruckChangeEmptyTravel[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
        MESS[:vBTravelEmpty][r, j, d, t] - MESS[:vBTravelEmpty][r, j, d, BS1T[t]] ==
        MESS[:vBDepartEmpty][r, j, d, t] - MESS[:vBArriveEmpty][r, j, d, t]
    )

    ## Travel delay
    @constraints(
        MESS,
        begin
            cBTruckTravelDelayArriveFull[
                r in 1:R,
                j in TRUCK_TYPES,
                d in [-1, 1],
                rs in eachindex(Residuals),
                t in 1:T,
            ],
            MESS[:vBTravelFull][r, j, d, rs, t] >= sum(
                MESS[:vBArriveFull][r, j, d, rs, tt] for tt in (t + 1):(t + Travel_delay[j][r]) if
                t + Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t + Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cBTruckTravelDelayArriveEmpty[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vBTravelEmpty][r, j, d, t] >= sum(
                MESS[:vBArriveEmpty][r, j, d, tt] for tt in (t + Travel_delay[j][r] + 1):t if
                t + Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t + Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cBTruckTravelDelayDepartFull[
                r in 1:R,
                j in TRUCK_TYPES,
                d in [-1, 1],
                rs in eachindex(Residuals),
                t in 1:T,
            ],
            MESS[:vBTravelFull][r, j, d, rs, t] >= sum(
                MESS[:vBDepartFull][r, j, d, rs, tt] for tt in (t + 1):(t - Travel_delay[j][r]) if
                t - Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t - Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
            cBTruckTravelDelayDepartEmpty[r in 1:R, j in TRUCK_TYPES, d in [-1, 1], t in 1:T],
            MESS[:vBTravelEmpty][r, j, d, t] >= sum(
                MESS[:vBDepartEmpty][r, j, d, tt] for tt in (t - Travel_delay[j][r] + 1):t if
                t - Travel_delay[j][r] >= ((t - 1) ÷ Period) * Period + 1 &&
                    t - Travel_delay[j][r] <= ((t - 1) ÷ Period + 1) * Period
            )
        end
    )

    ## Residual truck flow balance
    @constraint(
        MESS,
        cBResidualTruckFlow[
            z in TRUCK_ZONES,
            j in TRUCK_TYPES,
            rs in eachindex(Residuals),
            t in 1:T,
        ],
        MESS[:vBTruckFlow][z, j, rs, t] ==
        MESS[:vBUnloadedOverCrops][z, j, rs, t] *
        dfTru[!, :Truck_Cap_tonne_per_unit][j] *
        (1 - dfTru[!, :Loss_Percentage_per_mile][j]) -
        MESS[:vBLoaded][z, j, rs, t] * dfTru[!, :Truck_Cap_tonne_per_unit][j]
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
