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
function write_ammonia_demand(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        ammonia_settings = settings["AmmoniaSettings"]
        path = ammonia_settings["SavePath"]

        ## Flags
        AllowNse = ammonia_settings["AllowNse"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        ammonia_inputs = inputs["AmmoniaInputs"]

        ## Demand in each zone in each time step
        dfDemand = DataFrame(Zone = Zones, Total = Array{Union{Missing, Float64}}(undef, Z))
        dfDemand = hcat(dfDemand, DataFrame(round.(value.(MESS[:eADemand]); sigdigits = 4), :auto))

        auxNew_Names = [
            Symbol("Zone")
            Symbol("Total")
            tsymbols
        ]
        rename!(dfDemand, auxNew_Names)

        dfDemandDB = stack(dfDemand, tsymbols, variable_name = :TimeIndex, value_name = :Demand)

        dfDemand[!, :Total] =
            round.([sum(weights .* Vector(dfDemand[z, tsymbols])) for z in 1:Z]; sigdigits = 4)

        ## Push total summation row for csv results
        push!(
            dfDemand,
            [
                "Sum"
                round(sum(dfDemand[!, :Total]))
                round.([sum(dfDemand[!, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
            ],
        )

        ## CSV writing
        CSV.write(joinpath(path, "demand_by_zone.csv"), permutedims(dfDemand, "Zone"))

        ## Additional demand in each zone in each time step
        dfAddDemand = DataFrame(Zone = Zones, Total = Array{Union{Missing, Float64}}(undef, Z))
        dfAddDemand = hcat(
            dfAddDemand,
            DataFrame(round.(value.(MESS[:eADemandAddition]); sigdigits = 4), :auto),
        )

        auxNew_Names = [
            Symbol("Zone")
            Symbol("Total")
            tsymbols
        ]
        rename!(dfAddDemand, auxNew_Names)

        dfDemandDB[!, :AddDemand] =
            stack(dfAddDemand, tsymbols, variable_name = :TimeIndex, value_name = :AddDemand)[
                !,
                :AddDemand,
            ]

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(dfDemandDB, settings["DB"], "ADemand")
        end

        dfAddDemand[!, :Total] =
            round.([sum(weights .* Vector(dfAddDemand[z, tsymbols])) for z in 1:Z]; sigdigits = 4)

        ## Push total summation row for csv results
        push!(
            dfAddDemand,
            [
                "Sum"
                round(sum(dfAddDemand[!, :Total]); sigdigits = 4)
                round.([sum(dfAddDemand[:, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
            ],
        )

        ## CSV writing
        CSV.write(joinpath(path, "demand_additional_by_zone.csv"), permutedims(dfAddDemand, "Zone"))

        if AllowNse == 1
            SEG = ammonia_inputs["SEG"]

            ## Non-served energy/demand curtailment by segment in each time step
            dfs = []
            temp = round.(value.(MESS[:vADNse]); sigdigits = 4)
            for s in 1:SEG
                dfTemp = DataFrame(
                    ZoneAegment = ["($z)_($s)" for z in Zones],
                    Zone = Zones,
                    Segment = string(s),
                    Total = Array{Union{Missing, Float64}}(undef, Z),
                )
                dfTemp = hcat(dfTemp, DataFrame(temp[s, :, :], :auto))
                auxNew_Names = [
                    Symbol("ZoneAegment")
                    Symbol("Zone")
                    Symbol("Segment")
                    Symbol("Total")
                    tsymbols
                ]
                rename!(dfTemp, auxNew_Names)

                dfDemandDB[!, Symbol("Nse_$s")] = stack(
                    dfTemp[!, [Symbol("Zone"); tsymbols]],
                    tsymbols,
                    variable_name = :TimeIndex,
                    value_name = Symbol("Nse_$s"),
                )[
                    !,
                    Symbol("Nse_$s"),
                ]

                push!(dfs, dfTemp)
            end

            dfNse = reduce(vcat, dfs)
            ## Push total summation row for csv results
            push!(
                dfNse,
                [
                    "Sum"
                    "Sum"
                    "Sum"
                    round(sum(dfNse[!, :Total]); sigdigits = 4)
                    round.([sum(dfNse[!, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
                ],
            )

            ## CSV writing
            CSV.write(joinpath(path, "non_served_demand.csv"), permutedims(dfNse, "ZoneAegment"))
        end
    end
end
