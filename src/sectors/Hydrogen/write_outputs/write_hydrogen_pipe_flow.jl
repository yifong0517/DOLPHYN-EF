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
	write_hydrogen_pipeline_flow(settings::Dict, inputs::Dict, MESS::Model)

Function for reporting the hydrogen flow via pipeliens and trucks.
"""
function write_hydrogen_pipe_flow(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        hydrogen_settings = settings["HydrogenSettings"]
        path = hydrogen_settings["SavePath"]

        Z = inputs["Z"]
        T = inputs["T"]

        hydrogen_inputs = inputs["HydrogenInputs"]
        P = hydrogen_inputs["P"]

        if P > 0
            Pipe_map = hydrogen_inputs["Pipe_map"]

            ## Hydrogen balance for each zone
            dfPipeFlow = Array{Any}
            rowoffset = 3
            for p in 1:P
                dfTemp1 = Array{Any}(nothing, T + rowoffset, 3)
                dfTemp1[1, 1:size(dfTemp1, 2)] =
                    ["Source_Zone_H2_Net", "Sink_Zone_H2_Net", "Pipe_Level"]

                dfTemp1[2, 1:size(dfTemp1, 2)] = repeat([p], size(dfTemp1, 2))

                dfTemp1[3, 1:size(dfTemp1, 2)] = [
                    [
                        Pipe_map[(Pipe_map[!, :d] .== 1) .& (Pipe_map[!, :pipe_no] .== p), :][
                            !,
                            :Zone,
                        ][1],
                    ],
                    [
                        Pipe_map[(Pipe_map[!, :d] .== -1) .& (Pipe_map[!, :pipe_no] .== p), :][
                            !,
                            :Zone,
                        ][1],
                    ],
                    "NA",
                ]

                tempflow = -round.(value.(MESS[:eHPipeFlow]); sigdigits = 4)
                templevel = round.(value.(MESS[:vHPipeLevel]); sigdigits = 4)
                for t in 1:T
                    dfTemp1[t + rowoffset, 1] = tempflow[p, t, 1]
                    dfTemp1[t + rowoffset, 2] = tempflow[p, t, -1]
                    dfTemp1[t + rowoffset, 3] = templevel[p, t]
                end
                if p == 1
                    dfPipeFlow = hcat(vcat(["", "Pipe", "Zone"], ["t$t" for t in 1:T]), dfTemp1)
                else
                    dfPipeFlow = hcat(dfPipeFlow, dfTemp1)
                end
            end

            dfPipeFlow = DataFrame(dfPipeFlow, :auto)

            ## CSV writing
            CSV.write(joinpath(path, "pipeline_flow.csv"), dfPipeFlow)
        end
    end
end
