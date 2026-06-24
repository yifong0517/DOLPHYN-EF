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
function write_bioenergy_storage_capacities(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        bioenergy_settings = settings["BioenergySettings"]
        path = bioenergy_settings["SavePath"]

        bioenergy_inputs = inputs["BioenergyInputs"]

        dfSto = bioenergy_inputs["dfSto"]

        NEW_STO_CAP = bioenergy_inputs["NEW_STO_CAP"]
        RET_STO_CAP = bioenergy_inputs["RET_STO_CAP"]

        S = bioenergy_inputs["S"]

        RESOURCES = dfSto[!, :Resource]

        ## New storage volume capacities
        newcapvolume = zeros(size(RESOURCES))
        temp_volume = round.(value.(MESS[:vBNewStoVolumeCap]); digits = 2)
        for i in NEW_STO_CAP
            newcapvolume[i] = temp_volume[i]
        end

        ## Retired storage volume capacities
        retcapvolume = zeros(size(RESOURCES))
        temp_volume = round.(value.(MESS[:vBRetStoVolumeCap]); digits = 2)
        for i in RET_STO_CAP
            retcapvolume[i] = temp_volume[i]
        end

        ## Storage capacities dataframe
        dfCap = DataFrame(
            Resource = string.(RESOURCES),
            Zone = string.(dfSto[!, :Zone]),
            StartStoVolumeCap = dfSto[!, :Existing_Volume_Cap_tonne],
            RetStoVolumeCap = retcapvolume,
            NewStoVolumeCap = newcapvolume,
            EndStoVolumeCap = round.(value.(MESS[:eBStoVolumeCap]); digits = 2),
        )

        total = DataFrame(
            Resource = "Sum",
            Zone = "Sum",
            StartStoVolumeCap = round(sum(dfCap[!, :StartStoVolumeCap]); digits = 2),
            RetStoVolumeCap = round(sum(dfCap[!, :RetStoVolumeCap]); digits = 2),
            NewStoVolumeCap = round(sum(dfCap[!, :NewStoVolumeCap]); digits = 2),
            EndStoVolumeCap = round(sum(dfCap[!, :EndStoVolumeCap]); digits = 2),
        )

        ## Merge total dataframe for csv results
        dfCap = vcat(dfCap, total)

        ## CSV writing
        CSV.write(joinpath(path, "storage_capacities.csv"), dfCap)
    end
end
