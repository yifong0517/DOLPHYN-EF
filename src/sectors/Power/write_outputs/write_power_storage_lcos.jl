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
function write_power_storage_lcos(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 1
        power_settings = settings["PowerSettings"]
        path = power_settings["SavePath"]
        IncludeExistingSto = power_settings["IncludeExistingSto"]
        PReserve = power_settings["PReserve"]

        power_inputs = inputs["PowerInputs"]
        dfSto = power_inputs["dfSto"]
        RESOURCES = power_inputs["StoResources"]

        NEW_STO_CAP = power_inputs["NEW_STO_CAP"]
        STO_ASYMMETRIC = power_inputs["STO_ASYMMETRIC"]
        if PReserve == 1
            STO_PRSV = power_inputs["STO_PRSV"]
        end

        ## Storage dataframe
        dfLCOS = DataFrame(
            Resource = RESOURCES,
            ResourceType = string.(dfSto[!, :Resource_Type]),
            Zone = string.(dfSto[!, :Zone]),
        )
        dfTotal = DataFrame(Resource = "Sum", ResourceType = "Sum", Zone = "Sum")

        ## Fix costs - energy investment costs
        FixInvEneCosts = zeros(size(RESOURCES))
        temp = value.(MESS[:ePObjFixInvStoEneOS])
        for i in NEW_STO_CAP
            FixInvEneCosts[i] = temp[i]
        end
        dfLCOS[!, :FixInvEneCosts] = round.(FixInvEneCosts; digits = 2)
        dfTotal[!, :FixInvEneCosts] = [round(sum(FixInvEneCosts); digits = 2)]

        ## Fix costs - energy operation & maintenance costs
        FixFomEneCosts = value.(MESS[:ePObjFixFomStoEneOS])
        dfLCOS[!, :FixFomEneCosts] = round.(FixFomEneCosts; digits = 2)
        dfTotal[!, :FixFomEneCosts] = [round(sum(FixFomEneCosts); digits = 2)]

        ## Fix costs - energy sunk investment costs
        if IncludeExistingSto > 0
            FixSunkInvEneCosts = value.(MESS[:ePObjFixSunkInvStoEneOS])
            dfLCOS[!, :FixSunkInvEneCosts] = round.(FixSunkInvEneCosts; digits = 2)
            dfTotal[!, :FixSunkInvEneCosts] = [round(sum(FixSunkInvEneCosts); digits = 2)]
        end

        ## Fix costs - discharge investment costs
        FixInvDisCosts = zeros(size(RESOURCES))
        temp = value.(MESS[:ePObjFixInvStoDisOS])
        for i in NEW_STO_CAP
            FixInvDisCosts[i] = temp[i]
        end
        dfLCOS[!, :FixInvDisCosts] = round.(FixInvDisCosts; digits = 2)
        dfTotal[!, :FixInvDisCosts] = [round(sum(FixInvDisCosts); digits = 2)]

        ## Fix costs - discharge operation & maintenance costs
        FixFomDisCosts = value.(MESS[:ePObjFixFomStoDisOS])
        dfLCOS[!, :FixFomDisCosts] = round.(FixFomDisCosts; digits = 2)
        dfTotal[!, :FixFomDisCosts] = [round(sum(FixFomDisCosts); digits = 2)]

        ## Fix costs - discharge sunk investment costs
        if IncludeExistingSto > 0
            FixSunkInvDisCosts = value.(MESS[:ePObjFixSunkInvStoDisOS])
            dfLCOS[!, :FixSunkInvDisCosts] = round.(FixSunkInvDisCosts; digits = 2)
            dfTotal[!, :FixSunkInvDisCosts] = [round(sum(FixSunkInvDisCosts); digits = 2)]
        end

        if !isempty(STO_ASYMMETRIC)
            ## Fix costs - charge investment costs
            FixInvChaCosts = zeros(size(RESOURCES))
            temp = value.(MESS[:ePObjFixInvStoChaOS])
            for i in intersect(NEW_STO_CAP, STO_ASYMMETRIC)
                FixInvChaCosts[i] = temp[i]
            end
            dfLCOS[!, :FixInvChaCosts] = round.(FixInvChaCosts; digits = 2)
            dfTotal[!, :FixInvChaCosts] = [round(sum(FixInvChaCosts); digits = 2)]

            ## Fix costs - charge operation & maintenance costs
            FixFomChaCosts = zeros(size(RESOURCES))
            temp = value.(MESS[:ePObjFixFomStoChaOS])
            for i in STO_ASYMMETRIC
                FixFomChaCosts[i] = temp[i]
            end
            dfLCOS[!, :FixFomChaCosts] = round.(FixFomChaCosts; digits = 2)
            dfTotal[!, :FixFomChaCosts] = [round(sum(FixFomChaCosts); digits = 2)]

            ## Fix costs - charge sunk investment costs
            if IncludeExistingSto > 0
                FixSunkInvChaCosts = zeros(size(RESOURCES))
                temp = value.(MESS[:ePObjFixSunkInvStoChaOS])
                for i in STO_ASYMMETRIC
                    FixSunkInvChaCosts[i] = temp[i]
                end
                dfLCOS[!, :FixSunkInvChaCosts] = round.(FixSunkInvChaCosts; digits = 2)
                dfTotal[!, :FixSunkInvChaCosts] = [round(sum(FixSunkInvChaCosts); digits = 2)]
            end
        end

        ## Variable costs - discharge operation costs
        VarStoDisCosts = value.(MESS[:ePObjVarStoDisOS])
        dfLCOS[!, :VarStoDisCosts] = round.(VarStoDisCosts; digits = 2)
        dfTotal[!, :VarStoDisCosts] = [round(sum(VarStoDisCosts); digits = 2)]

        ## Variable costs - discharge primary reserve costs
        if PReserve == 1
            VarStoDisPRSVCosts = zeros(size(RESOURCES))
            temp = value.(MESS[:ePObjReserveStoDisOS])
            for i in STO_PRSV
                VarStoDisPRSVCosts[i] = temp[i]
            end
            dfLCOS[!, :VarStoDisPRSVCosts] = round.(VarStoDisPRSVCosts; digits = 2)
            dfTotal[!, :VarStoDisPRSVCosts] = [round(sum(VarStoDisPRSVCosts); digits = 2)]
        end

        ## Variable costs - charge operation costs
        VarStoChaCosts = value.(MESS[:ePObjVarStoChaOS])
        dfLCOS[!, :VarStoChaCosts] = round.(VarStoChaCosts; digits = 2)
        dfTotal[!, :VarStoChaCosts] = [round(sum(VarStoChaCosts); digits = 2)]

        ## Variable costs - charge primary reserve costs
        if PReserve == 1
            VarStoChaPRSVCosts = zeros(size(RESOURCES))
            temp = value.(MESS[:ePObjReserveStoChaOS])
            for i in STO_PRSV
                VarStoChaPRSVCosts[i] = temp[i]
            end
            dfLCOS[!, :VarStoChaPRSVCosts] = round.(VarStoChaPRSVCosts; digits = 2)
            dfTotal[!, :VarStoChaPRSVCosts] = [round(sum(VarStoChaPRSVCosts); digits = 2)]
        end

        ## Total costs of each storage = FixInvEneCosts + FixFomEneCosts + FixSunkInvEneCosts (if) +
        ## FixInvDisCosts + FixFomDisCosts + FixSunkInvDisCosts (if) +
        ## FixInvChaCosts + FixFomChaCosts + FixSunkInvChaCosts (if) +
        ## VarStoDisCosts + VarStoDisPRSVCosts (if) + VarStoChaCosts + VarStoChaPRSVCosts
        dfLCOS = transform(dfLCOS, Cols(x -> contains(x, "Costs")) => (+) => :Costs)
        dfTotal[!, "Costs"] = [round(sum(dfLCOS[!, :Costs]); digits = 2)]

        ## Capacity
        dfLCOS[!, :Capacity] = round.(value.(MESS[:ePStoEneCap]); digits = 2)
        dfTotal[!, :Capacity] = [round(sum(dfLCOS[!, :Capacity]); digits = 2)]

        ## Total discharge
        dfLCOS[!, :Discharge] = round.(vec(sum(value.(MESS[:vPStoDis]); dims = 2)); digits = 2)
        dfTotal[!, :Discharge] = [round(sum(dfLCOS[!, :Discharge]); digits = 2)]

        ## Total charge
        dfLCOS[!, :Charge] = round.(vec(sum(value.(MESS[:vPStoCha]); dims = 2)); digits = 2)
        dfTotal[!, :Charge] = [round(sum(dfLCOS[!, :Charge]); digits = 2)]

        ## LCOS calulation
        dfLCOS = transform(
            dfLCOS,
            [:Costs, :Discharge] =>
                ByRow((C, D) -> D > 0 ? round(C / D; digits = 2) : 0.0) =>
                    Symbol("LCOS (\$/MWh)"),
        )
        dfTotal[!, Symbol("LCOS (\$/MWh)")] = [
            round(
                mean(
                    dfLCOS[dfLCOS[!, Symbol("LCOS (\$/MWh)")] .> 0, Symbol("LCOS (\$/MWh)")],
                    Weights(dfLCOS[dfLCOS[!, Symbol("LCOS (\$/MWh)")] .> 0, :Discharge]),
                );
                digits = 2,
            ),
        ]

        ## Database writing
        if haskey(settings, "DB")
            dfStorage = DataFrame(DBInterface.execute(settings["DB"], "SELECT * FROM PStorage"))
            dfStorage = innerjoin(dfStorage, dfLCOS, on = [:Resource, :ResourceType, :Zone])
            SQLite.drop!(settings["DB"], "PStorage")
            SQLite.load!(dfStorage, settings["DB"], "PStorage")
        end

        ## Merge total dataframe for csv results
        dfLCOS = vcat(dfLCOS, dfTotal)

        ## CSV writing
        CSV.write(joinpath(path, "LCOS_storage.csv"), dfLCOS)
    end
end
