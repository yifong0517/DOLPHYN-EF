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
function write_foodstuff_crop_export(settings::Dict, inputs::Dict, MESS::Model)

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

        ## Foodstuff sector crop export
        dfCropExports = []
        temp = round.(value.(MESS[:vFCropExport]); sigdigits = 4)
        for cs in eachindex(Crops)
            dfCropExport = DataFrame(
                Zone = Zones .* "_" .* Crops[cs],
                Total = Array{Union{Missing, Float64}}(undef, Z),
            )
            dfCropExport = hcat(dfCropExport, DataFrame(temp[:, cs, :], :auto))

            auxNew_Names = [Symbol("Zone"); Symbol("Total"); [Symbol("$t") for t in 1:T]]
            rename!(dfCropExport, auxNew_Names)

            dfCropExport[!, :Total] =
                round.(
                    [sum(weights .* Vector(dfCropExport[z, tsymbols])) for z in 1:Z];
                    sigdigits = 4,
                )

            push!(
                dfCropExport,
                [
                    "Total_$(Crops[cs])"
                    round(sum(dfCropExport[!, :Total]); sigdigits = 4)
                    round.([sum(dfCropExport[:, Symbol("$t")]) for t in 1:T]; sigdigits = 4)
                ],
            )

            push!(dfCropExports, dfCropExport)
        end

        ## Gather all dataframes into one
        dfCropExports = reduce(vcat, dfCropExports)

        CSV.write(joinpath(path, "foodstuff_crop_export.csv"), permutedims(dfCropExports, "Zone"))
    end
end
