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
function write_carbon_storage_capacities(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        carbon_settings = settings["CarbonSettings"]
        path = carbon_settings["SavePath"]

        ## Flags
        AllowDis = carbon_settings["AllowDis"]

        carbon_inputs = inputs["CarbonInputs"]

        dfSto = carbon_inputs["dfSto"]

        NEW_STO_CAP = carbon_inputs["NEW_STO_CAP"]
        RET_STO_CAP = carbon_inputs["RET_STO_CAP"]

        S = carbon_inputs["S"]

        RESOURCES = carbon_inputs["StoResources"]

        ## New storage discharging/charging and energy capacities
        newcapdischarge = zeros(size(RESOURCES))
        newcapcharge = zeros(size(RESOURCES))
        newcapenergy = zeros(size(RESOURCES))
        if AllowDis == 1
            temp_dis = value.(MESS[:vCNewStoDisCap])
        end
        temp_ene = value.(MESS[:vCNewStoEneCap])
        temp_cha = value.(MESS[:vCNewStoChaCap])
        for i in NEW_STO_CAP
            if AllowDis == 1
                newcapdischarge[i] = temp_dis[i]
            else
                newcapdischarge[i] = 0.0
            end
            newcapenergy[i] = temp_ene[i]
            newcapcharge[i] = temp_cha[i]
        end

        ## Retired storage discharging/charging and energy capacities
        retcapdischarge = zeros(size(RESOURCES))
        retcapcharge = zeros(size(RESOURCES))
        retcapenergy = zeros(size(RESOURCES))
        if AllowDis == 1
            temp_dis = value.(MESS[:vCRetStoDisCap])
        end
        temp_ene = value.(MESS[:vCRetStoEneCap])
        temp_cha = value.(MESS[:vCRetStoChaCap])
        for i in RET_STO_CAP
            if AllowDis == 1
                retcapdischarge[i] = temp_dis[i]
            else
                retcapdischarge[i] = 0.0
            end
            retcapenergy[i] = temp_ene[i]
            retcapcharge[i] = temp_cha[i]
        end

        ## Storage capacities dataframe
        dfCap = DataFrame(
            Resource = string.(RESOURCES),
            ResourceType = string.(dfSto[!, :Resource_Type]),
            Zone = string.(dfSto[!, :Zone]),
            StartStoDisCap = round.(dfSto[!, :Existing_Dis_Cap_tonne_per_hr]; digits = 2),
            StartStoChaCap = round.(dfSto[!, :Existing_Cha_Cap_tonne_per_hr]; digits = 2),
            StartStoEneCap = round.(dfSto[!, :Existing_Ene_Cap_tonne]; digits = 2),
            RetStoDisCap = round.(retcapdischarge[:]; digits = 2),
            RetStoChaCap = round.(retcapcharge[:]; digits = 2),
            RetStoEneCap = round.(retcapenergy[:]; digits = 2),
            NewStoDisCap = round.(newcapdischarge[:]; digits = 2),
            NewStoChaCap = round.(newcapcharge[:]; digits = 2),
            NewStoEneCap = round.(newcapenergy[:]; digits = 2),
            EndStoDisCap = (AllowDis == 1) ? round.(value.(MESS[:eCStoDisCap]); digits = 2) : 0.0,
            EndStoChaCap = round.(value.(MESS[:eCStoChaCap]); digits = 2),
            EndStoEneCap = round.(value.(MESS[:eCStoEneCap]); digits = 2),
        )

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(dfCap, settings["DB"], "CStorage")
        end

        ## Total storage capacities
        total = DataFrame(
            Resource = "Sum",
            ResourceType = "Sum",
            Zone = "Sum",
            StartStoDisCap = round(sum(dfCap[!, :StartStoDisCap]); digits = 2),
            StartStoChaCap = round(sum(dfCap[!, :StartStoChaCap]); digits = 2),
            StartStoEneCap = round(sum(dfCap[!, :StartStoEneCap]); digits = 2),
            RetStoDisCap = round(sum(dfCap[!, :RetStoDisCap]); digits = 2),
            RetStoChaCap = round(sum(dfCap[!, :RetStoChaCap]); digits = 2),
            RetStoEneCap = round(sum(dfCap[!, :RetStoEneCap]); digits = 2),
            NewStoDisCap = round(sum(dfCap[!, :NewStoDisCap]); digits = 2),
            NewStoChaCap = round(sum(dfCap[!, :NewStoChaCap]); digits = 2),
            NewStoEneCap = round(sum(dfCap[!, :NewStoEneCap]); digits = 2),
            EndStoDisCap = round(sum(dfCap[!, :EndStoDisCap]); digits = 2),
            EndStoChaCap = round(sum(dfCap[!, :EndStoChaCap]); digits = 2),
            EndStoEneCap = round(sum(dfCap[!, :EndStoEneCap]); digits = 2),
        )

        ## Merge total dataframe for csv results
        dfCap = vcat(dfCap, total)

        ## CSV writing
        CSV.write(joinpath(path, "capacities_storage.csv"), dfCap)
    end
end
