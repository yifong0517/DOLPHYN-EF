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
function write_power_transmission_angle(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        power_settings = settings["PowerSettings"]
        path = power_settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        ## Angle in each zone in each time step
        dfAngle = DataFrame(Zone = Zones, Total = Array{Union{Missing, Float64}}(undef, Z))
        dfAngle = hcat(dfAngle, DataFrame(round.(value.(MESS[:vPLineAngle]); sigdigits = 4), :auto))

        auxNew_Names = [
            Symbol("Zone")
            Symbol("Total")
            tsymbols
        ]
        rename!(dfAngle, auxNew_Names)

        dfAngleDB = stack(dfAngle, tsymbols, variable_name = :TimeIndex, value_name = :Angle)

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(dfAngleDB, settings["DB"], "PAngle")
        end

        dfAngle[!, :Average] =
            round.([mean(weights .* Vector(dfAngle[z, tsymbols])) for z in 1:Z]; sigdigits = 4)

        ## Push average row for csv results
        push!(
            dfAngle,
            [
                "Average"
                round(mean(dfAngle[!, :Average]))
                round.([mean(dfAngle[!, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
            ],
        )

        ## CSV writing
        CSV.write(joinpath(path, "angle_by_zone.csv"), permutedims(dfAngle, "Zone"))
    end
end
