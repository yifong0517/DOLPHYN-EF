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
function write_foodstuff_crop_warehouse(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        foodstuff_settings = settings["FoodstuffSettings"]
        path = foodstuff_settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        tsymbols = [Symbol("$t") for t in 1:T]

        foodstuff_inputs = inputs["FoodstuffInputs"]
        Crops = foodstuff_inputs["Crops"]

        ## Foodstuff sector crop warehouse volume
        dfVolumes = []
        for cs in eachindex(Crops)
            dfVolume = DataFrame(CropZone = Zones)
            dfVolume = hcat(
                dfVolume,
                DataFrame(round.(value.(MESS[:vFCropStoVolume][:, cs, :]); sigdigits = 4), :auto),
            )
            auxNew_Names = [Symbol("Zone"); tsymbols]
            rename!(dfVolume, auxNew_Names)
            push!(dfVolumes, dfVolume)
        end

        ## Gather all dataframes into one
        dfVolumes = reduce(vcat, dfVolumes)

        ## Change zones index with zone+crop type
        dfVolumes[!, :CropZone] = ["$(cs)_$(z)" for cs in Crops for z in Zones]

        CSV.write(
            joinpath(path, "foodstuff_crop_warehouse_volume.csv"),
            permutedims(dfVolumes, "CropZone"),
        )

        ## Foodstuff sector crop warehouse discharge
        dfDischarges = []
        for cs in eachindex(Crops)
            dfDischarge = DataFrame(CropZone = Zones)
            dfDischarge = hcat(
                dfDischarge,
                DataFrame(round.(value.(MESS[:vFCropStoDis][:, cs, :]); sigdigits = 4), :auto),
            )
            auxNew_Names = [Symbol("Zone"); tsymbols]
            rename!(dfDischarge, auxNew_Names)
            push!(dfDischarges, dfDischarge)
        end

        ## Gather all dataframes into one
        dfDischarges = reduce(vcat, dfDischarges)

        ## Change zones index with zone+crop type
        dfDischarges[!, :CropZone] = ["$(cs)_$(z)" for cs in Crops for z in Zones]

        CSV.write(
            joinpath(path, "foodstuff_crop_warehouse_discharge.csv"),
            permutedims(dfDischarges, "CropZone"),
        )

        ## Foodstuff sector crop warehouse charge
        dfCharges = []
        for cs in eachindex(Crops)
            dfCharge = DataFrame(CropZone = Zones)
            dfCharge = hcat(
                dfCharge,
                DataFrame(round.(value.(MESS[:eFCropStoCha][:, cs, :]); sigdigits = 4), :auto),
            )
            auxNew_Names = [Symbol("Zone"); tsymbols]
            rename!(dfCharge, auxNew_Names)
            push!(dfCharges, dfCharge)
        end

        ## Gather all dataframes into one
        dfCharges = reduce(vcat, dfCharges)

        ## Change zones index with zone+crop type
        dfCharges[!, :CropZone] = ["$(cs)_$(z)" for cs in Crops for z in Zones]

        CSV.write(
            joinpath(path, "foodstuff_crop_warehouse_charge.csv"),
            permutedims(dfCharges, "CropZone"),
        )

        if foodstuff_settings["CropRotation"] == 1
            ## Foodstuff sector crop warehouse volume
            dfRotations = []
            for cs in eachindex(Crops)
                dfRotation = DataFrame(CropZone = Zones)
                dfRotation = hcat(
                    dfRotation,
                    DataFrame(
                        round.(value.(MESS[:eFCropRotation][:, cs, :]); sigdigits = 4),
                        :auto,
                    ),
                )
                auxNew_Names = [Symbol("Zone"); tsymbols]
                rename!(dfRotation, auxNew_Names)
                push!(dfRotations, dfRotation)
            end

            ## Gather all dataframes into one
            dfRotations = reduce(vcat, dfRotations)

            ## Change zones index with zone+crop type
            dfRotations[!, :CropZone] = ["$(cs)_$(z)" for cs in Crops for z in Zones]

            CSV.write(
                joinpath(path, "foodstuff_crop_warehouse_rotation.csv"),
                permutedims(dfRotations, "CropZone"),
            )
        end
    end
end
