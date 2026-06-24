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
	pipeline_all(settings::Dict, inputs::Dict, MESS::Model)

"""
function pipeline_all(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Hydrogen Transmission Pipeline Core Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]
    T = inputs["T"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
    end

    hydrogen_settings = settings["HydrogenSettings"]
    hydrogen_inputs = inputs["HydrogenInputs"]

    dfPipe = hydrogen_inputs["dfPipe"]

    ## Number of transmission lines
    P = hydrogen_inputs["P"]
    Pipe_map = hydrogen_inputs["Pipe_map"]

    @variable(MESS, vHPipeLevel[p = 1:P, t = 1:T] >= 0) ## Storage in the pipe
    @variable(MESS, vHPipeFlow_pos[p = 1:P, t = 1:T, d = [-1, 1]] >= 0) ## positive pipeflow
    @variable(MESS, vHPipeFlow_neg[p = 1:P, t = 1:T, d = [-1, 1]] >= 0) ## negative pipeflow

    ### Expressions ###
    ## Calculate net flow at each pipe-zone interfrace
    @expression(
        MESS,
        eHPipeFlow[p = 1:P, t = 1:T, d = [-1, 1]],
        MESS[:vHPipeFlow_pos][p, t, d] - MESS[:vHPipeFlow_neg][p, t, d]
    )

    ## Hydrogen Power Consumption balance
    ## H2 balance - net flows of H2 from between z and zz via pipeline p over time period t
    @expression(
        MESS,
        eHBalancePipeFlow[z = 1:Z, t = 1:T],
        -sum(
            MESS[:eHPipeFlow][
                p,
                t,
                Pipe_map[(Pipe_map.Zone .== Zones[z]) .& (Pipe_map.pipe_no .== p), :d][1],
            ] for p in Pipe_map[Pipe_map.Zone .== Zones[z], :pipe_no];
            init = 0.0,
        )
    )
    add_to_expression!.(MESS[:eHBalance], MESS[:eHBalancePipeFlow])
    add_to_expression!.(MESS[:eHTransmission], MESS[:eHBalancePipeFlow])

    ## Compression power consumption
    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceHPipeComp[z = 1:Z, t = 1:T],
            sum(
                MESS[:vHPipeFlow_pos][
                    p,
                    t,
                    Pipe_map[(Pipe_map.Zone .== Zones[z]) .& (Pipe_map.pipe_no .== p), :d][1],
                ] * (
                    dfPipe[!, :Pipe_Comp_Energy][p] +
                    dfPipe[!, :Booster_Stations_Number][p] *
                    dfPipe[!, :Booster_Comp_Energy_MWh_per_tonne][p]
                ) for p in Pipe_map[Pipe_map.Zone .== Zones[z], :pipe_no];
                init = 0.0,
            )
        )

        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceHPipeComp])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceHPipeComp])
    else
        @expression(
            MESS,
            eHElectricityConsumptionPipeComp[f in eachindex(Electricity_Index), z in 1:Z, t in 1:T],
            begin
                if Electricity_Index[f] in dfPipe[!, :Electricity]
                    sum(
                        MESS[:vHPipeFlow_pos][
                            p,
                            t,
                            Pipe_map[(Pipe_map.Zone .== Zones[z]) .& (Pipe_map.pipe_no .== p), :d][1],
                        ] * (
                            dfPipe[!, :Pipe_Comp_Energy][p] +
                            dfPipe[!, :Booster_Stations_Number][p] *
                            dfPipe[!, :Booster_Comp_Energy_MWh_per_tonne][p]
                        ) for p in Pipe_map[Pipe_map.Zone .== Zones[z], :pipe_no];
                        init = 0.0,
                    )
                else
                    0
                end
            end
        )
        add_to_expression!.(
            MESS[:eHElectricityConsumption],
            MESS[:eHElectricityConsumptionPipeComp],
        )
    end
    ### End Expressions ###

    ### Constraints ###
    ## Constraint maximum pipe flow
    @constraints(
        MESS,
        begin
            cHPipeMaxFlow[p in 1:P, t = 1:T, d in [-1, 1]],
            MESS[:eHPipeFlow][p, t, d] <=
            MESS[:eHPipeCap][p] * dfPipe[!, :Max_Flow_tonne_per_hr][p]
            cHPipeMinFlow[p in 1:P, t = 1:T, d in [-1, 1]],
            -MESS[:eHPipeFlow][p, t, d] <=
            MESS[:eHPipeCap][p] * dfPipe[!, :Max_Flow_tonne_per_hr][p]
        end
    )

    ## Constrain positive and negative pipe flows
    @constraints(
        MESS,
        begin
            cHPipeMaxPositiveFlow[p in 1:P, t = 1:T, d in [-1, 1]],
            MESS[:eHPipeCap][p] * dfPipe[!, :Max_Flow_tonne_per_hr][p] >= vHPipeFlow_pos[p, t, d]
            cHPipeMaxNegtiveFlow[p in 1:P, t = 1:T, d in [-1, 1]],
            MESS[:eHPipeCap][p] * dfPipe[!, :Max_Flow_tonne_per_hr][p] >= vHPipeFlow_neg[p, t, d]
        end
    )

    ## Minimum and maximum pipe level constraint
    @constraints(
        MESS,
        begin
            cHPipeStoMinCap[p in 1:P, t = 1:T],
            MESS[:vHPipeLevel][p, t] >= dfPipe[!, :Min_Storage_Cap][p] * MESS[:eHPipeCap][p]
            cHPipeStoMaxCap[p in 1:P, t = 1:T],
            dfPipe[!, :Max_Storage_Cap][p] * MESS[:eHPipeCap][p] >= MESS[:vHPipeLevel][p, t]
        end
    )

    ## Pipeline storage level change
    @constraint(
        MESS,
        cHPipeStoLevel[p in 1:P, t in 1:T],
        MESS[:vHPipeLevel][p, t] ==
        MESS[:vHPipeLevel][p, BS1T[t]] - MESS[:eHPipeFlow][p, t, -1] - MESS[:eHPipeFlow][p, t, 1]
    )
    ### End Constraints ###

    return MESS
end
