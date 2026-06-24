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
function write_bioenergy_demand(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        bioenergy_settings = settings["BioenergySettings"]
        path = bioenergy_settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        bioenergy_inputs = inputs["BioenergyInputs"]
        Residuals = bioenergy_inputs["Residuals"]

        dfs = []
        temp = round.(value.(MESS[:eBDemand]); sigdigits = 4)
        for rs in eachindex(Residuals)
            ## Demand in each zone in each time step
            dfDemand = DataFrame(
                Zone = Zones .* "_" .* Residuals[rs],
                Total = Array{Union{Missing, Float64}}(undef, Z),
            )
            dfDemand = hcat(dfDemand, DataFrame(temp[:, rs, :], :auto))

            auxNew_Names = [
                Symbol("Zone")
                Symbol("Total")
                tsymbols
            ]
            rename!(dfDemand, auxNew_Names)

            dfDemand[!, :Total] =
                round.([sum(weights .* Vector(dfDemand[z, tsymbols])) for z in 1:Z]; sigdigits = 4)

            push!(
                dfDemand,
                [
                    "Total_$(Residuals[rs])"
                    round(sum(dfDemand[!, :Total]); sigdigits = 4)
                    round.([sum(dfDemand[:, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
                ],
            )

            push!(dfs, dfDemand)
        end

        df = reduce(vcat, dfs)

        CSV.write(joinpath(path, "demand_by_zone.csv"), permutedims(df, "Zone"))

        dfs = []
        temp = round.(value.(MESS[:eBDemandAddition]); sigdigits = 4)
        for rs in eachindex(Residuals)
            ## Additional demand in each zone in each time step
            dfAddDemand = DataFrame(
                Zone = Zones .* "_" .* Residuals[rs],
                Total = Array{Union{Missing, Float64}}(undef, Z),
            )
            dfAddDemand = hcat(dfAddDemand, DataFrame(temp[:, rs, :], :auto))

            auxNew_Names = [
                Symbol("Zone")
                Symbol("Total")
                tsymbols
            ]
            rename!(dfAddDemand, auxNew_Names)

            dfAddDemand[!, :Total] =
                round.(
                    [sum(weights .* Vector(dfAddDemand[z, tsymbols])) for z in 1:Z];
                    sigdigits = 4,
                )

            push!(
                dfAddDemand,
                [
                    "Total_$(Residuals[rs])"
                    round(sum(dfAddDemand[!, :Total]); sigdigits = 4)
                    round.([sum(dfAddDemand[:, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
                ],
            )
            push!(dfs, dfAddDemand)
        end

        df = reduce(vcat, dfs)

        CSV.write(joinpath(path, "demand_additional_by_zone.csv"), permutedims(df, "Zone"))
    end
end
