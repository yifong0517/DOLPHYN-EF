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
function write_ammonia_generation_capacity_factor(settings::Dict, inputs::Dict, MESS::Model)

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

        ## Find generator which is in operation
        INOPERATION = findall(x -> x > 0, round.(value.(MESS[:eAGenCap]); digits = 4))
        IG = length(INOPERATION)

        ## Capacity factor of each generator for each time step
        if !isempty(INOPERATION)
            dfCapacityFactor = DataFrame(
                Resource = string.(RESOURCES[INOPERATION]),
                ResourceType = string.(dfGen[!, :Resource_Type][INOPERATION]),
                Zone = string.(dfGen[!, :Zone][INOPERATION]),
                Total = Array{Union{Missing, Float64}}(undef, length(INOPERATION)),
            )
            dfCapacityFactor = hcat(
                dfCapacityFactor,
                DataFrame(
                    round.(
                        value.(MESS[:vAGen][INOPERATION, :]) ./
                        value.(MESS[:eAGenCap][INOPERATION]);
                        digits = 4,
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
            rename!(dfCapacityFactor, auxNew_Names)

            dfCapacityFactor[!, :Total] =
                round.(
                    [sum(weights .* Vector(dfCapacityFactor[g, tsymbols])) / T for g in 1:IG];
                    digits = 4,
                )

            ## Database writing
            if haskey(settings, "DB")
                CF = [
                    g in INOPERATION ?
                    dfCapacityFactor[dfCapacityFactor.Resource .== RESOURCES[g], :Total] : 0 for
                    g in 1:G
                ]
                dfGenerator =
                    DataFrame(DBInterface.execute(settings["DB"], "SELECT * FROM AGenerator"))
                dfGenerator[!, :CapacityFactor] = CF
                SQLite.drop!(settings["DB"], "AGenerator")
                SQLite.load!(dfGenerator, settings["DB"], "AGenerator")
            end

            ## Push total summation row for csv results
            push!(
                dfCapacityFactor,
                [
                    "Sum"
                    "Sum"
                    "Sum"
                    round(sum(dfCapacityFactor[!, :Total]) / IG; digits = 4)
                    round.([sum(dfCapacityFactor[!, Symbol("$t")]) / IG for t in 1:T]; digits = 4)
                ],
            )

            ## CSV writing
            CSV.write(
                joinpath(path, "capacity_factor.csv"),
                permutedims(dfCapacityFactor, "Resource", makeunique = true),
            )
        end
    end
end
