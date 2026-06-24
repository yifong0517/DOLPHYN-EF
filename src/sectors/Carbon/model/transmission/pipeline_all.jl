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

    print_and_log(settings, "i", "Carbon Transmission Pipeline Core Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]
    T = inputs["T"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
    end

    carbon_settings = settings["CarbonSettings"]
    carbon_inputs = inputs["CarbonInputs"]

    dfPipe = carbon_inputs["dfPipe"]

    ## Number of transmission lines
    L = carbon_inputs["L"]
    Pipe_map = carbon_inputs["Pipe_map"]

    ### Variables ###
    @variable(MESS, vCPipeLevel[p = 1:L, t = 1:T] >= 0) ## Storage in the pipe
    @variable(MESS, vCPipeFlow_pos[p = 1:L, t = 1:T, d = [-1, 1]] >= 0) ## positive pipeflow
    @variable(MESS, vCPipeFlow_neg[p = 1:L, t = 1:T, d = [-1, 1]] >= 0) ## negative pipeflow

    ### Expressions ###
    ## Calculate net flow at each pipe-zone interfrace
    @expression(
        MESS,
        eCPipeFlow[p = 1:L, t = 1:T, d = [-1, 1]],
        vCPipeFlow_pos[p, t, d] - vCPipeFlow_neg[p, t, d]
    )

    ## Balance Expressions ##
    ## Carbon Power Consumption balance
    ## Carbon balance - net flows of CO2 from between z and zz via pipeline p over time period t
    @expression(
        MESS,
        eCBalancePipeFlow[z = 1:Z, t = 1:T],
        -sum(
            eCPipeFlow[
                p,
                t,
                Pipe_map[(Pipe_map.Zone .== Zones[z]) .& (Pipe_map.pipe_no .== p), :d][1],
            ] for p in Pipe_map[Pipe_map.Zone .== Zones[z], :pipe_no];
            init = 0.0,
        )
    )
    add_to_expression!.(MESS[:eCBalance], MESS[:eCBalancePipeFlow])

    ## Compression power consumption
    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceCPipeComp[z = 1:Z, t = 1:T],
            sum(
                vCPipeFlow_pos[
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

        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceCPipeComp])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceCPipeComp])
    else
        @expression(
            MESS,
            eCElectricityConsumptionPipeComp[f in eachindex(Electricity_Index), z in 1:Z, t in 1:T],
            begin
                if Electricity_Index[f] in dfPipe[!, :Electricity]
                    sum(
                        vCPipeFlow_pos[
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
            MESS[:eCElectricityConsumption],
            MESS[:eCElectricityConsumptionPipeComp],
        )
    end
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Constraint maximum pipe flow
    @constraints(
        MESS,
        begin
            cCPipeMaxFlow[p in 1:L, t = 1:T, d in [-1, 1]],
            MESS[:eCPipeFlow][p, t, d] <=
            MESS[:eCPipeCap][p] * dfPipe[!, :Max_Flow_tonne_per_hr][p]
            cCPipeMinFlow[p in 1:L, t = 1:T, d in [-1, 1]],
            -MESS[:eCPipeFlow][p, t, d] <=
            MESS[:eCPipeCap][p] * dfPipe[!, :Max_Flow_tonne_per_hr][p]
        end
    )

    ## Constrain positive and negative pipe flows
    @constraints(
        MESS,
        begin
            cCPipeMaxPositiveFlow[p in 1:L, t = 1:T, d in [-1, 1]],
            MESS[:eCPipeCap][p] * dfPipe[!, :Max_Flow_tonne_per_hr][p] >= vCPipeFlow_pos[p, t, d]
            cCPipeMaxNegtiveFlow[p in 1:L, t = 1:T, d in [-1, 1]],
            MESS[:eCPipeCap][p] * dfPipe[!, :Max_Flow_tonne_per_hr][p] >= vCPipeFlow_neg[p, t, d]
        end
    )

    ## Minimum and maximum pipe level constraint
    @constraints(
        MESS,
        begin
            cCPipeStoMinCap[p in 1:L, t = 1:T],
            MESS[:vCPipeLevel][p, t] >= dfPipe[!, :Min_Storage_Cap][p] * MESS[:eCPipeCap][p]
            cCPipeStoMaxCap[p in 1:L, t = 1:T],
            dfPipe[!, :Max_Storage_Cap][p] * MESS[:eCPipeCap][p] >= MESS[:vCPipeLevel][p, t]
        end
    )

    ## Pipeline storage level change
    @constraint(
        MESS,
        cCPipeStoLevel[p in 1:L, t in 1:T],
        MESS[:vCPipeLevel][p, t] ==
        MESS[:vCPipeLevel][p, BS1T[t]] - MESS[:eCPipeFlow][p, t, -1] - MESS[:eCPipeFlow][p, t, 1]
    )
    ### End Constraints ###

    return MESS
end
