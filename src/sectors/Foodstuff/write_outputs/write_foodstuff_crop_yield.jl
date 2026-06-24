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
function write_foodstuff_crop_yield(settings::Dict, inputs::Dict, MESS::Model)

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

        Crops = foodstuff_inputs["Crops"]

        ## Foodstuff sector crop production
        dfCropYields = []
        temp = round.(value.(MESS[:eFCropYield]); sigdigits = 4)
        for cs in eachindex(Crops)
            dfCropYield = DataFrame(
                Zone = Zones .* "_" .* Crops[cs],
                Total = Array{Union{Missing, Float64}}(undef, Z),
            )
            dfCropYield = hcat(dfCropYield, DataFrame(temp[:, cs, :], :auto))

            auxNew_Names = [Symbol("Zone"); Symbol("Total"); [Symbol("$t") for t in 1:T]]
            rename!(dfCropYield, auxNew_Names)

            dfCropYield[!, :Total] =
                round.(
                    [sum(weights .* Vector(dfCropYield[z, tsymbols])) for z in 1:Z];
                    sigdigits = 4,
                )

            push!(
                dfCropYield,
                [
                    "Total_$(Crops[cs])"
                    round(sum(dfCropYield[!, :Total]); sigdigits = 4)
                    round.([sum(dfCropYield[:, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
                ],
            )

            push!(dfCropYields, dfCropYield)
        end

        ## Gather all dataframes into one
        dfCropYields = reduce(vcat, dfCropYields)

        CSV.write(joinpath(path, "foodstuff_crop_yield.csv"), permutedims(dfCropYields, "Zone"))
    end
end
