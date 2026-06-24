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
function write_carbon_pipe_lcoc(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 1
        T = inputs["T"]
        weights = inputs["weights"]

        if !(settings["ModelPower"] == 1)
            Electricity_Index = inputs["Electricity_Index"]
            electricity_costs = inputs["electricity_costs"]
        end

        carbon_settings = settings["CarbonSettings"]
        path = carbon_settings["SavePath"]
        IncludeExistingNetwork = carbon_settings["IncludeExistingNetwork"]

        carbon_inputs = inputs["CarbonInputs"]
        NEW_PIPES = carbon_inputs["NEW_PIPES"]
        dfPipe = carbon_inputs["dfPipe"]
        P = carbon_inputs["P"]

        if P > 0
            ## Pipeline dataframe
            dfLCOC = DataFrame(
                Pipe = string.(1:P),
                StartZone = string.(dfPipe[!, :Start_Zone]),
                EndZone = string.(dfPipe[!, :End_Zone]),
                Distance = dfPipe[!, :Pipe_Length_miles],
            )
            dfTotal = DataFrame(
                Pipe = "Sum",
                StartZone = "Sum",
                EndZone = "Sum",
                Distance = mean(dfPipe[!, :Pipe_Length_miles]),
            )

            ## Fix costs - investment costs
            FixInvCosts = zeros(P)
            temp = value.(MESS[:eCObjNetworkExpansionOP])
            for p in NEW_PIPES
                FixInvCosts[p] = temp[p]
            end
            dfLCOC[!, :FixInvCosts] = round.(FixInvCosts; digits = 2)
            dfTotal[!, :FixInvCosts] = [round(sum(FixInvCosts); digits = 2)]

            ## Fix costs - sunk investment costs
            if IncludeExistingNetwork == 1
                FixSunkInvCosts = value.(MESS[:eCObjNetworkExistingOP])
                dfLCOC[!, :FixSunkInvCosts] = round.(FixSunkInvCosts; digits = 2)
                dfTotal[!, :FixSunkInvCosts] = [round(sum(FixSunkInvCosts); digits = 2)]
            end

            ## Var costs - compression power costs
            if !(settings["ModelPower"] == 1)
                temp = value.(MESS[:vCPipeFlow_pos])
                VarComCosts = [
                    if dfPipe[!, :Electricity][p] in Electricity_Index
                        sum(
                            weights[t] *
                            temp[p, t, d] *
                            electricity_costs[dfPipe[!, :Electricity][p]][t] for t in 1:T for
                            d in [-1, 1]
                        ) * (
                            dfPipe[!, :Pipe_Comp_Energy][p] +
                            dfPipe[!, :Booster_Stations_Number][p] *
                            dfPipe[!, :Booster_Comp_Energy_MWh_per_tonne][p]
                        )
                    else
                        0
                    end for p in 1:P
                ]
                dfLCOC[!, :VarComCosts] = round.(VarComCosts; digits = 2)
                dfTotal[!, :VarComCosts] = [round(sum(VarComCosts); digits = 2)]
            end

            ## Total costs of each pipeline = FixInvCosts + FixSunkInvCosts (if) + VarComCosts (if)
            dfLCOC = transform(dfLCOC, Cols(x -> contains(x, "Costs")) => (+) => :Costs)
            dfTotal[!, :Costs] = [round(sum(dfLCOC[!, :Costs]); digits = 2)]

            ## Total flow
            flow = Array(value.(MESS[:eCPipeFlow]))
            dfLCOC[!, :Flow] = round.(vec(sum(flow; dims = [2, 3])); digits = 2)
            dfTotal[!, :Flow] = [round(sum(dfLCOC[!, :Flow]); digits = 2)]

            ## Capacity
            dfLCOC[!, :Capacity] = round.(value.(MESS[:eCPipeCap]); digits = 2)
            dfTotal[!, :Capacity] = [round(sum(dfLCOC[!, :Capacity]); digits = 2)]

            ## LCOH calulation
            dfLCOC = transform(
                dfLCOC,
                [:Distance, :Costs, :Flow] =>
                    ByRow((D, C, F) -> F > 0 ? round(C / F / D; digits = 2) : 0.0) =>
                        Symbol("LCOH (\$/tonne/mile)"),
            )
            dfTotal[!, Symbol("LCOH (\$/tonne/mile)")] = [
                round(
                    mean(
                        dfLCOC[
                            dfLCOC[!, Symbol("LCOH (\$/tonne/mile)")] .> 0,
                            Symbol("LCOH (\$/tonne/mile)"),
                        ],
                        Weights(
                            dfLCOC[dfLCOC[!, Symbol("LCOH (\$/tonne/mile)")] .> 0, :Distance] .*
                            dfLCOC[dfLCOC[!, Symbol("LCOH (\$/tonne/mile)")] .> 0, :Flow],
                        ),
                    );
                    digits = 2,
                ),
            ]

            ## Database writing
            if haskey(settings, "DB")
                if carbon_settings["NetworkExpansion"] != -1
                    CPipes = DataFrame(DBInterface.execute(settings["DB"], "SELECT * FROM CPipes"))
                    CPipes = innerjoin(CPipes, dfLCOC, on = [:Pipe, :StartZone, :EndZone])
                    SQLite.drop!(settings["DB"], "CPipes")
                    SQLite.load!(CPipes, settings["DB"], "CPipes")
                else
                    SQLite.load!(dfLCOC, settings["DB"], "CPipes")
                end
            end

            ## Merge total dataframe for csv results
            dfLCOC = vcat(dfLCOC, dfTotal)

            ## CSV writing
            CSV.write(joinpath(path, "LCOC_pipeline.csv"), dfLCOC)
        end
    end
end
