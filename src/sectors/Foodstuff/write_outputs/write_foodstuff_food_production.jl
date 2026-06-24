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
    write_foodstuff_food_production(settings::Dict, inputs::Dict, MESS::Model)

"""
function write_foodstuff_food_production(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        foodstuff_settings = settings["FoodstuffSettings"]
        path = foodstuff_settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        foodstuff_inputs = inputs["FoodstuffInputs"]

        Foods = foodstuff_inputs["Foods"]

        ## Foodstuff sector food production
        dfProductions = []
        temp = round.(value.(MESS[:eFFoodProduction]); sigdigits = 4)
        for fs in eachindex(Foods)
            dfProduction = DataFrame(
                Zone = Zones .* "_" .* Foods[fs],
                Total = Array{Union{Missing, Float64}}(undef, Z),
            )
            dfProduction = hcat(dfProduction, DataFrame(temp[:, fs, :], :auto))

            auxNew_Names = [Symbol("Zone"); Symbol("Total"); [Symbol("$t") for t in 1:T]]
            rename!(dfProduction, auxNew_Names)

            dfProduction[!, :Total] =
                round.(
                    [sum(weights .* Vector(dfProduction[z, tsymbols])) for z in 1:Z];
                    sigdigits = 4,
                )

            push!(
                dfProduction,
                [
                    "Total_$(Foods[fs])"
                    round(sum(dfProduction[!, :Total]); sigdigits = 4)
                    round.([sum(dfProduction[:, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
                ],
            )

            push!(dfProductions, dfProduction)
        end

        ## Gather all dataframes into one
        dfProductions = reduce(vcat, dfProductions)

        CSV.write(
            joinpath(path, "foodstuff_food_production.csv"),
            permutedims(dfProductions, "Zone"),
        )
    end
end
