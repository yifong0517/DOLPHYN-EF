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
function write_ammonia_generation(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        ammonia_settings = settings["AmmoniaSettings"]
        path = ammonia_settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        ammonia_inputs = inputs["AmmoniaInputs"]

        RESOURCES = ammonia_inputs["GenResources"]

        dfGen = ammonia_inputs["dfGen"]
        G = ammonia_inputs["G"]

        ## Ammonia injected by each resource in each time step
        dfAmmonia = DataFrame(
            Resource = string.(RESOURCES),
            ResourceType = string.(dfGen[!, :Resource_Type]),
            Zone = string.(dfGen[!, :Zone]),
            Total = Array{Union{Missing, Float64}}(undef, G),
        )
        dfAmmonia = hcat(dfAmmonia, DataFrame(round.(value.(MESS[:vAGen]); sigdigits = 4), :auto))

        auxNew_Names = [
            Symbol("Resource")
            Symbol("ResourceType")
            Symbol("Zone")
            Symbol("Total")
            tsymbols
        ]
        rename!(dfAmmonia, auxNew_Names)

        dfAmmonia[!, :Total] =
            round.([sum(weights .* Vector(dfAmmonia[g, tsymbols])) for g in 1:G]; sigdigits = 4)

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(
                stack(
                    dfAmmonia[
                        !,
                        [Symbol("Resource"); Symbol("ResourceType"); Symbol("Zone"); tsymbols],
                    ],
                    tsymbols,
                    variable_name = :TimeAtamp,
                    value_name = :Generation,
                ),
                settings["DB"],
                "AGeneration",
            )
        end

        ## Push total summation row for csv results
        push!(
            dfAmmonia,
            [
                "Sum"
                "Sum"
                "Sum"
                round(sum(dfAmmonia[!, :Total]); sigdigits = 4)
                round.([sum(dfAmmonia[:, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
            ],
        )

        ## CSV writing
        CSV.write(
            joinpath(path, "generaton_by_plant.csv"),
            permutedims(dfAmmonia, "Resource", makeunique = true),
        )

        ## Power injected in each zone in each time step
        dfAmmonia = DataFrame(Zone = Zones, Total = Array{Union{Missing, Float64}}(undef, Z))
        dfAmmonia =
            hcat(dfAmmonia, DataFrame(round.(value.(MESS[:eAGeneration]); sigdigits = 4), :auto))

        auxNew_Names = [
            Symbol("Zone")
            Symbol("Total")
            tsymbols
        ]
        rename!(dfAmmonia, auxNew_Names)

        dfAmmonia[!, :Total] =
            round.([sum(weights .* Vector(dfAmmonia[z, tsymbols])) for z in 1:Z]; sigdigits = 4)

        ## Push total summation row for csv results
        push!(
            dfAmmonia,
            [
                "Sum"
                round(sum(dfAmmonia[!, :Total]); sigdigits = 4)
                round.([sum(dfAmmonia[:, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
            ],
        )

        ## CSV writing
        CSV.write(joinpath(path, "generation_by_zone.csv"), permutedims(dfAmmonia, "Zone"))
    end
end
