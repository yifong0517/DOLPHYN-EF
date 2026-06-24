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
function write_foodstuff_crop_import(settings::Dict, inputs::Dict, MESS::Model)

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

        dfFood = foodstuff_inputs["dfFood"]
        Crops = foodstuff_inputs["Crops"]
        Foods = foodstuff_inputs["Foods"]

        FT = foodstuff_inputs["FT"]

        ## Foodstuff sector crop import
        dfCropImports = []
        temp = round.(value.(MESS[:eFCropImport]); sigdigits = 4)
        for cs in eachindex(Crops)
            dfCropImport = DataFrame(
                Zone = Zones .* "_" .* Crops[cs],
                Total = Array{Union{Missing, Float64}}(undef, Z),
            )
            dfCropImport = hcat(dfCropImport, DataFrame(temp[:, cs, :], :auto))

            auxNew_Names = [Symbol("Zone"); Symbol("Total"); [Symbol("$t") for t in 1:T]]
            rename!(dfCropImport, auxNew_Names)

            dfCropImport[!, :Total] =
                round.(
                    [sum(weights .* Vector(dfCropImport[z, tsymbols])) for z in 1:Z];
                    sigdigits = 4,
                )

            push!(
                dfCropImport,
                [
                    "Total_$(Crops[cs])"
                    round(sum(dfCropImport[!, :Total]); sigdigits = 4)
                    round.([sum(dfCropImport[:, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
                ],
            )

            push!(dfCropImports, dfCropImport)
        end

        ## Gather all dataframes into one
        dfCropImports = reduce(vcat, dfCropImports)

        CSV.write(joinpath(path, "foodstuff_crop_import.csv"), permutedims(dfCropImports, "Zone"))

        ## Foodstuff sector food import
        dfFoodImport = DataFrame(
            FT_ID = string.(dfFood[!, :FT_ID]),
            Zone = dfFood[!, :Zone],
            Crop = dfFood[!, :Crop],
            Total = Array{Union{Missing, Float64}}(undef, FT),
        )

        dfFoodImport =
            hcat(dfFoodImport, DataFrame(round.(value.(MESS[:eFFoodImport]); sigdigits = 4), :auto))

        auxNew_Names = [
            Symbol("FT_ID")
            Symbol("Zone")
            Symbol("Crop")
            Symbol("Total")
            tsymbols
        ]
        rename!(dfFoodImport, auxNew_Names)

        dfFoodImport[!, :Total] =
            round.(
                [sum(weights .* Vector(dfFoodImport[ft, tsymbols])) for ft in 1:FT];
                sigdigits = 4,
            )

        ## Push total summation row for csv results
        push!(
            dfFoodImport,
            [
                "Sum"
                "Sum"
                "Sum"
                sum(dfFoodImport[!, :Total])
                [sum(dfFoodImport[!, Symbol("$t")]) for t in 1:T]
            ],
        )

        CSV.write(joinpath(path, "foodstuff_food_import.csv"), permutedims(dfFoodImport, "FT_ID"))
    end
end
