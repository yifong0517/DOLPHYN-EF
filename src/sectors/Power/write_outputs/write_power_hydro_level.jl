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
function write_power_hydro_level(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        power_settings = settings["PowerSettings"]
        path = power_settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        power_inputs = inputs["PowerInputs"]

        RESOURCES = power_inputs["GenResources"]

        dfGen = power_inputs["dfGen"]
        HYDRO = power_inputs["HYDRO"]

        ## Hydropower injected by each hydro resource in each time step
        dfHydro = DataFrame(
            Resource = string.(RESOURCES[HYDRO]),
            Zone = string.(dfGen[!, :Zone][HYDRO]),
            Total = Array{Union{Missing, Float64}}(undef, length(HYDRO)),
        )
        dfHydro =
            hcat(dfHydro, DataFrame(round.(value.(MESS[:vPHydroLevel]).data; sigdigits = 4), :auto))

        auxNew_Names = [
            Symbol("Resource")
            Symbol("Zone")
            Symbol("Total")
            tsymbols
        ]
        rename!(dfHydro, auxNew_Names)

        dfHydro[!, :Total] =
            round.(
                [sum(weights .* Vector(dfHydro[g, tsymbols])) for g in eachindex(HYDRO)];
                sigdigits = 4,
            )

        ## Push total summation row for csv results
        push!(
            dfHydro,
            [
                "Sum"
                "Sum"
                round(sum(dfHydro[!, :Total]); sigdigits = 4)
                round.([sum(dfHydro[!, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
            ],
        )

        ## CSV writing
        CSV.write(
            joinpath(path, "hydro_storage_level.csv"),
            permutedims(dfHydro, "Resource", makeunique = true),
        )

        ## Water spill of each hydro resource in each time step
        dfSpill = DataFrame(
            Resource = string.(RESOURCES[HYDRO]),
            Zone = string.(dfGen[!, :Zone][HYDRO]),
            Total = Array{Union{Missing, Float64}}(undef, length(HYDRO)),
        )
        dfSpill =
            hcat(dfSpill, DataFrame(round.(value.(MESS[:vPSpill]).data; sigdigits = 4), :auto))

        auxNew_Names = [
            Symbol("Resource")
            Symbol("Zone")
            Symbol("Total")
            tsymbols
        ]
        rename!(dfSpill, auxNew_Names)

        dfSpill[!, :Total] =
            round.(
                [sum(weights .* Vector(dfSpill[g, tsymbols])) for g in eachindex(HYDRO)];
                sigdigits = 4,
            )

        ## Push total summation row for csv results
        push!(
            dfSpill,
            [
                "Sum"
                "Sum"
                round(sum(dfSpill[!, :Total]); sigdigits = 4)
                round.([sum(dfSpill[!, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
            ],
        )

        ## CSV writing
        CSV.write(
            joinpath(path, "hydro_water_spill.csv"),
            permutedims(dfSpill, "Resource", makeunique = true),
        )
    end
end
