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
function write_power_expansion(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        power_settings = settings["PowerSettings"]
        path = power_settings["SavePath"]

        power_inputs = inputs["PowerInputs"]

        L = power_inputs["L"] # Number of transmission lines
        dfLine = power_inputs["dfLine"]

        ## Transmission network reinforcements
        if L > 0
            transcap = zeros(L)
            temp = round.(value.(MESS[:vPNewLineCap]); sigdigits = 2)
            for l in 1:L
                if l in power_inputs["NEW_LINES"]
                    transcap[l] = temp[l]
                end
            end

            dfTransCap = DataFrame(
                Line = string.(1:L),
                LineName = string.(dfLine[!, :Path_Name]),
                StartZone = string.(dfLine[!, :Start_Zone]),
                EndZone = string.(dfLine[!, :End_Zone]),
                Start_Trans_Capacity = dfLine[!, :Existing_Line_Cap_MW],
                New_Trans_Capacity = transcap,
                End_Trans_Capacity = round.(value.(MESS[:ePLineCap]); sigdigits = 2),
                Cost_Trans_Capacity = transcap .* dfLine[!, :Line_Inv_Cost_per_MW],
            )

            ## Database writing
            if haskey(settings, "DB")
                SQLite.load!(dfTransCap, settings["DB"], "PLines")
            end

            ## CSV writing
            CSV.write(joinpath(path, "network_expansion.csv"), dfTransCap)
        end
    end
end
