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
function write_synfuels_storage_revenues(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        synfuels_settings = settings["SynfuelsSettings"]
        path = synfuels_settings["SavePath"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        synfuels_inputs = inputs["SynfuelsInputs"]

        dfSto = synfuels_inputs["dfSto"]
        S = synfuels_inputs["S"]
        RESOURCES = synfuels_inputs["StoResources"]

        ## Revenue obtained by each resource in each time step
        dfRevenue = DataFrame(
            Resource = string.(RESOURCES),
            ResourceType = string.(dfSto[!, :Resource_Type]),
            Zone = string.(dfSto[!, :Zone]),
            Total = Array{Union{Missing, Float64}}(undef, S),
        )

        dfRevenue = hcat(
            dfRevenue,
            DataFrame(
                round.(
                    (value.(MESS[:vSStoDis]) - value.(MESS[:vSStoCha])) .*
                    (dual.(MESS[:cSBalance]) ./ transpose(weights))[dfSto[!, :ZoneIndex], :];
                    digits = 2,
                ),
                :auto,
            ),
        )

        auxNew_Names = [
            Symbol("Resource")
            Symbol("ResourceType")
            Symbol("Zone")
            Symbol("Total")
            tsymbols
        ]
        rename!(dfRevenue, auxNew_Names)

        dfRevenue[!, :Total] =
            round.([sum(weights .* Vector(dfRevenue[s, tsymbols])) for s in 1:S]; digits = 2)

        ## Push total summation row for csv results
        push!(
            dfRevenue,
            [
                "Sum"
                "Sum"
                "Sum"
                round(sum(dfRevenue[!, :Total]); digits = 2)
                round.([sum(dfRevenue[!, Symbol("$t")]) for t in 1:T]; digits = 2)
            ],
        )

        ## CSV writing
        CSV.write(joinpath(path, "revenue_storage.csv"), permutedims(dfRevenue, "Resource"))
    end
end
