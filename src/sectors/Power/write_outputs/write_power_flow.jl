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
function write_power_flow(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        power_settings = settings["PowerSettings"]
        path = power_settings["SavePath"]

        Z = inputs["Z"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        power_inputs = inputs["PowerInputs"]

        dfLine = power_inputs["dfLine"]
        ## Transmission related values
        L = power_inputs["L"]

        if L > 0
            ## Power flows on transmission lines at each time step
            dfFlow = DataFrame(
                Line = string.(1:L),
                LineName = string.(dfLine[!, :Path_Name]),
                Total = Array{Union{Missing, Float64}}(undef, L),
            )

            dfFlow = hcat(
                dfFlow,
                DataFrame(round.(value.(MESS[:vPLineFlow]); sigdigits = 4), :auto),
            )
            auxNew_Names = [Symbol("Line"); Symbol("LineName"); Symbol("Total"); tsymbols]
            rename!(dfFlow, auxNew_Names)

            dfFlow[!, :Total] =
                round.([sum(weights .* Vector(dfFlow[l, tsymbols])) for l in 1:L]; sigdigits = 4)

            ## Database writing
            if haskey(settings, "DB")
                SQLite.load!(
                    stack(
                        dfFlow[!, [Symbol("Line"); Symbol("LineName"); tsymbols]],
                        tsymbols,
                        variable_name = :TimeStamp,
                        value_name = :Flow,
                    ),
                    settings["DB"],
                    "PTransmission",
                )
            end

            ## Push total summation row for csv results
            push!(
                dfFlow,
                [
                    "Sum"
                    "Sum"
                    round(sum(dfFlow[!, :Total]); sigdigits = 4)
                    round.([sum(dfFlow[!, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
                ],
            )

            ## CSV writing
            CSV.write(joinpath(path, "flow_by_line.csv"), permutedims(dfFlow, "LineName"))

            ## Power losses for transmission between zones at each time step
            dfTLosses = DataFrame(
                Line = string.(1:L),
                LineName = string.(dfLine[!, :Path_Name]),
                Total = Array{Union{Missing, Float64}}(undef, L),
            )
            tlosses = zeros(L, T)
            temp = round.(value.(MESS[:vPLineFlowLoss]); sigdigits = 4)
            for l in 1:L
                if l in power_inputs["LOSS_LINES"]
                    tlosses[l, :] = temp[l, :]
                end
                dfTLosses[!, :Total][l] = round(sum(weights .* tlosses[l, :]); sigdigits = 4)
            end
            dfTLosses = hcat(dfTLosses, DataFrame(tlosses, :auto))

            auxNew_Names = [
                Symbol("Line")
                Symbol("LineName")
                Symbol("Total")
                tsymbols
            ]
            rename!(dfTLosses, auxNew_Names)

            dfTLosses[!, :Total] =
                round.([sum(weights .* Vector(dfTLosses[l, tsymbols])) for l in 1:L]; sigdigits = 4)

            ## Database writing
            if haskey(settings, "DB")
                dfTransmisson =
                    DataFrame(DBInterface.execute(settings["DB"], "SELECT * FROM PTransmission"))
                dfTransmisson = innerjoin(
                    dfTransmisson,
                    stack(
                        dfTLosses[!, [Symbol("Line"); Symbol("LineName"); tsymbols]],
                        tsymbols,
                        variable_name = :TimeStamp,
                        value_name = :Loss,
                    ),
                    on = [:Line, :LineName, :TimeStamp],
                )
                SQLite.drop!(settings["DB"], "PTransmission")
                SQLite.load!(dfTransmisson, settings["DB"], "PTransmission")
            end

            ## Push total summation row for csv results
            push!(
                dfTLosses,
                [
                    "Sum"
                    "Sum"
                    round(sum(dfTLosses[!, :Total]); sigdigits = 4)
                    round.([sum(dfTLosses[!, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
                ],
            )

            ## CSV writing
            CSV.write(joinpath(path, "flow_losses_by_line.csv"), permutedims(dfTLosses, "LineName"))
        end
    end
end
