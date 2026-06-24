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
function write_power_transmission_lcoe(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 1
        power_settings = settings["PowerSettings"]
        path = power_settings["SavePath"]
        IncludeExistingNetwork = power_settings["IncludeExistingNetwork"]

        power_inputs = inputs["PowerInputs"]
        dfLine = power_inputs["dfLine"]
        NEW_LINES = power_inputs["NEW_LINES"]
        L = power_inputs["L"]

        if L > 0
            ## Transmission line dataframe
            dfLCOE = DataFrame(
                Line = string.(1:L),
                LineName = string.(dfLine[!, :Path_Name]),
                StartZone = string.(dfLine[!, :Start_Zone]),
                EndZone = string.(dfLine[!, :End_Zone]),
            )
            dfTotal = DataFrame(Line = "Sum", LineName = "Sum", StartZone = "Sum", EndZone = "Sum")

            ## Fix costs - investment costs
            Exp = zeros(L)
            temp = value.(MESS[:ePObjNetworkExpOL])
            for l in NEW_LINES
                Exp[l] = temp[l]
            end
            dfLCOE[!, :ExpCosts] = round.(Exp; digits = 2)
            dfTotal[!, :ExpCosts] = [round(sum(Exp); digits = 2)]

            ## Fix costs - sunk investment costs
            if IncludeExistingNetwork > 0
                Exi = value.(MESS[:ePObjNetworkExistingOL])
                dfLCOE[!, :ExiCosts] = round.(Exi; digits = 2)
                dfTotal[!, :ExiCosts] = [round(sum(Exi); digits = 2)]
            end

            ## Total costs = investment costs + sunk investment costs (if any)
            dfLCOE = transform(dfLCOE, Cols(x -> contains(x, "Costs")) => (+) => :Costs)
            dfTotal[!, "Costs"] = [round(sum(dfLCOE[!, :Costs]); digits = 2)]

            ## Capacity
            dfLCOE[!, :Capacity] = round.(value.(MESS[:ePLineCap]); digits = 2)
            dfTotal[!, :Capacity] = [round(sum(dfLCOE[!, :Capacity]); digits = 2)]

            ## Total transmission
            dfLCOE[!, :Transmission] =
                round.(vec(sum(abs.(value.(MESS[:vPLineFlow])); dims = 2)); digits = 2)
            dfTotal[!, :Transmission] = [round(sum(dfLCOE[!, :Transmission]); digits = 2)]

            ## LCOE calculation
            dfLCOE = transform(
                dfLCOE,
                [:Costs, :Transmission] =>
                    ByRow((C, T) -> T > 0 ? round(C / T; digits = 2) : 0.0) =>
                        Symbol("LCOE (\$/MWh)"),
            )
            dfTotal[!, Symbol("LCOE (\$/MWh)")] = [
                round(
                    mean(
                        dfLCOE[dfLCOE[!, Symbol("LCOE (\$/MWh)")] .> 0, Symbol("LCOE (\$/MWh)")],
                        Weights(dfLCOE[dfLCOE[!, Symbol("LCOE (\$/MWh)")] .> 0, :Transmission]),
                    );
                    digits = 2,
                ),
            ]

            ## Database writing
            if haskey(settings, "DB")
                if power_settings["NetworkExpansion"] != -1
                    PLines = DataFrame(DBInterface.execute(settings["DB"], "SELECT * FROM PLines"))
                    PLines =
                        innerjoin(PLines, dfLCOE, on = [:Line, :LineName, :StartZone, :EndZone])
                    SQLite.drop!(settings["DB"], "PLines")
                    SQLite.load!(PLines, settings["DB"], "PLines")
                else
                    SQLite.load!(dfLCOE, settings["DB"], "PLines")
                end
            end

            ## Merge total dataframe for csv results
            dfLCOE = vcat(dfLCOE, dfTotal)

            ## CSV writing
            CSV.write(joinpath(path, "LCOE_transmission.csv"), dfLCOE)
        end
    end
end
