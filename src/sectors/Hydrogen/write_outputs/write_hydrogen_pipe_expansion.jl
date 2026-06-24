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
function write_hydrogen_pipe_expansion(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        hydrogen_settings = settings["HydrogenSettings"]
        path = hydrogen_settings["SavePath"]

        hydrogen_inputs = inputs["HydrogenInputs"]

        P = hydrogen_inputs["P"]
        dfPipe = hydrogen_inputs["dfPipe"]

        if P > 0
            Existing_Trans_Cap = zeros(P)
            transcap = zeros(P)
            Pipes = zeros(P)
            Fixed_Cost = zeros(P)

            temp = round.(value.(MESS[:eHPipeCap]); digits = 2)
            for p in 1:P
                Existing_Trans_Cap =
                    dfPipe[!, :Max_Flow_tonne_per_hr][p] * dfPipe[!, :Existing_Pipe_Number][p]
                transcap[p] = temp[p] * dfPipe[!, :Max_Flow_tonne_per_hr][p]
                Pipes[p] = temp[p]
                Fixed_Cost[p] =
                    temp[p] *
                    dfPipe[!, :Pipe_Inv_Cost_per_mile][p] *
                    dfPipe[!, :Pipe_Length_miles][p]
            end

            dfTransCap = DataFrame(
                Pipe = string.(1:P),
                StartZone = string.(dfPipe[!, :Start_Zone]),
                EndZone = string.(dfPipe[!, :End_Zone]),
                Existing_Trans_Capacity = Existing_Trans_Cap,
                New_Trans_Capacity = transcap,
                Total_Trans_Capacity = Pipes,
                Fixed_Cost_Pipes = Fixed_Cost,
            )

            ## Database writing
            if haskey(settings, "DB")
                SQLite.load!(dfTransCap, settings["DB"], "HPipes")
            end

            ## CSV writing
            CSV.write(joinpath(path, "network_expansion.csv"), dfTransCap)
        end
    end
end
