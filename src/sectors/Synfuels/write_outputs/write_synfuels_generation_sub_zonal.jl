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
function write_synfuels_generation_sub_zonal(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 4
        synfuels_settings = settings["SynfuelsSettings"]
        path = synfuels_settings["SavePath"]

        Z = inputs["Z"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        synfuels_inputs = inputs["SynfuelsInputs"]
        SubZones = synfuels_inputs["SubZones"]

        dfSynfuels = DataFrame(
            SubZone = SubZones,
            Total = Array{Union{Missing, Float64}}(undef, length(SubZones)),
        )
        dfSynfuels = hcat(
            dfSynfuels,
            DataFrame(round.(value.(MESS[:eSGenerationSubZonal]).data; sigdigits = 4), :auto),
        )
        auxNew_Names = [
            Symbol("SubZone")
            Symbol("Total")
            tsymbols
        ]
        rename!(dfSynfuels, auxNew_Names)

        dfSynfuels[!, :Total] =
            round.(
                [sum(weights .* Vector(dfSynfuels[z, tsymbols])) for z in eachindex(SubZones)];
                sigdigits = 4,
            )

        ## Push total summation row for csv results
        push!(
            dfSynfuels,
            [
                "Sum"
                sum(dfSynfuels[!, :Total])
                [sum(dfSynfuels[:, Symbol("$t")]) for t in 1:T]
            ],
        )

        ## CSV writing
        CSV.write(joinpath(path, "generation_by_sub_zone.csv"), permutedims(dfSynfuels, "SubZone"))
    end
end
