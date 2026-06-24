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
function write_carbon_net_emissions(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        carbon_settings = settings["CarbonSettings"]
        path = carbon_settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        weights = inputs["weights"]
        Time_Index = inputs["Time_Index"]
        tsymbols = [Symbol("$t") for t in 1:T]

        carbon_inputs = inputs["CarbonInputs"]

        ## Emission in each zone in each time step
        dfnetEmission = DataFrame(Zone = Zones, Total = Array{Union{Missing, Float64}}(undef, Z))
        dfnetEmission = hcat(
            dfnetEmission,
            DataFrame(
                round.(value.(MESS[:eCEmissions]) .- value.(MESS[:eCCapture]); sigdigits = 4),
                :auto,
            ),
        )

        auxNew_Names = [
            Symbol("Zone")
            Symbol("Total")
            tsymbols
        ]
        rename!(dfnetEmission, auxNew_Names)
        dfnetEmission[!, :Total] =
            round.([sum(weights .* Vector(dfnetEmission[z, tsymbols])) for z in 1:Z]; sigdigits = 4)

        total = DataFrame(["Sum" sum(dfnetEmission[!, :Total]) fill(0.0, (1, T))], :auto)
        for t in 1:T
            total[:, t + 2] .= round(sum(dfnetEmission[:, Symbol("$t")]); sigdigits = 4)
        end

        rename!(total, auxNew_Names)
        dfnetEmission = vcat(dfnetEmission, total)

        ## CSV writing
        CSV.write(joinpath(path, "net_emission_by_zone.csv"), permutedims(dfnetEmission, "Zone"))
    end
end
