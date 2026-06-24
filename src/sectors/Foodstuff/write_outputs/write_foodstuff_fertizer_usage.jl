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
function write_foodstuff_fertizer_usage(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        foodstuff_settings = settings["FoodstuffSettings"]
        path = foodstuff_settings["SavePath"]

        Zones = inputs["Zones"]
        foodstuff_inputs = inputs["FoodstuffInputs"]

        Crops = foodstuff_inputs["Crops"]

        ## Urea, ammonia, hydrogen and nitrogen usage for each zone and crop type
        dfZonalFertizer = DataFrame(Zone = Zones)

        ## Urea usage
        dfZonalFertizer = hcat(
            dfZonalFertizer,
            DataFrame(
                Dict(
                    Symbol("$(Crops[cs])UreaUsage") =>
                        round.(value.(MESS[:eFCropZonalUreaUsage][:, cs]); sigdigits = 6) for
                    cs in eachindex(Crops)
                ),
            ),
        )

        ## Ammonia usage
        dfZonalFertizer = hcat(
            dfZonalFertizer,
            DataFrame(
                Dict(
                    Symbol("$(Crops[cs])AmmoniaUsage") =>
                        round.(value.(MESS[:eFCropZonalAmmoniaUsage][:, cs]); sigdigits = 6) for
                    cs in eachindex(Crops)
                ),
            ),
        )

        ## Hydrogen usage
        if !(settings["ModelAmmonia"] == 1)
            dfZonalFertizer = hcat(
                dfZonalFertizer,
                DataFrame(
                    Dict(
                        Symbol("$(Crops[cs])HydrogenUsage") =>
                            round.(value.(MESS[:eFCropZonalHydrogenUsage][:, cs]); sigdigits = 6) for cs in eachindex(Crops)
                    ),
                ),
            )
        end

        ## Nitrogen usage
        if !(settings["ModelAmmonia"] == 1)
            dfZonalFertizer = hcat(
                dfZonalFertizer,
                DataFrame(
                    Dict(
                        Symbol("$(Crops[cs])NitrogenUsage") =>
                            round.(value.(MESS[:eFCropZonalNitrogenUsage][:, cs]); sigdigits = 6) for cs in eachindex(Crops)
                    ),
                ),
            )
        end

        CSV.write(joinpath(path, "foodstuff_zonal_fertizer_usage.csv"), dfZonalFertizer)
    end
end
