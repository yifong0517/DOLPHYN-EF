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
function write_ammonia_storage_lcos(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 1
        ammonia_settings = settings["AmmoniaSettings"]
        path = ammonia_settings["SavePath"]
        IncludeExistingSto = ammonia_settings["IncludeExistingSto"]

        ammonia_inputs = inputs["AmmoniaInputs"]
        dfSto = ammonia_inputs["dfSto"]
        RESOURCES = ammonia_inputs["StoResources"]

        NEW_STO_CAP = ammonia_inputs["NEW_STO_CAP"]

        ## Storage dataframe
        dfLCOS = DataFrame(
            Resource = RESOURCES,
            ResourceType = string.(dfSto[!, :Resource_Type]),
            Zone = string.(dfSto[!, :Zone]),
        )
        dfTotal = DataFrame(Resource = "Sum", ResourceType = "Sum", Zone = "Sum")

        ## Fix costs - energy investment costs
        FixInvEneCosts = zeros(size(RESOURCES))
        temp = value.(MESS[:eAObjFixInvStoEneOS])
        for i in NEW_STO_CAP
            FixInvEneCosts[i] = temp[i]
        end
        dfLCOS[!, :FixInvEneCosts] = round.(FixInvEneCosts; digits = 2)
        dfTotal[!, :FixInvEneCosts] = [round(sum(FixInvEneCosts); digits = 2)]

        ## Fix costs - energy operation & maintenance costs
        FixFomEneCosts = value.(MESS[:eAObjFixFomStoEneOS])
        dfLCOS[!, :FixFomEneCosts] = round.(FixFomEneCosts; digits = 2)
        dfTotal[!, :FixFomEneCosts] = [round(sum(FixFomEneCosts); digits = 2)]

        ## Fix costs - energy sunk investment costs
        if IncludeExistingSto == 1
            FixSunkInvEneCosts = value.(MESS[:eAObjFixSunkInvStoEneOS])
            dfLCOS[!, :FixSunkInvEneCosts] = round.(FixSunkInvEneCosts; digits = 2)
            dfTotal[!, :FixSunkInvEneCosts] = [round(sum(FixSunkInvEneCosts); digits = 2)]
        end

        ## Fix costs - discharge investment costs
        FixInvDisCosts = zeros(size(RESOURCES))
        temp = value.(MESS[:eAObjFixInvStoDisOS])
        for i in NEW_STO_CAP
            FixInvDisCosts[i] = temp[i]
        end
        dfLCOS[!, :FixInvDisCosts] = round.(FixInvDisCosts; digits = 2)
        dfTotal[!, :FixInvDisCosts] = [round(sum(FixInvDisCosts); digits = 2)]

        ## Fix costs - discharge operation & maintenance costs
        FixFomDisCosts = value.(MESS[:eAObjFixFomStoDisOS])
        dfLCOS[!, :FixFomDisCosts] = round.(FixFomDisCosts; digits = 2)
        dfTotal[!, :FixFomDisCosts] = [round(sum(FixFomDisCosts); digits = 2)]

        ## Fix costs - discharge sunk investment costs
        if IncludeExistingSto == 1
            FixSunkInvDisCosts = value.(MESS[:eAObjFixSunkInvStoDisOS])
            dfLCOS[!, :FixSunkInvDisCosts] = round.(FixSunkInvDisCosts; digits = 2)
            dfTotal[!, :FixSunkInvDisCosts] = [round(sum(FixSunkInvDisCosts); digits = 2)]
        end

        ## Fix costs - charge investment costs
        FixInvChaCosts = zeros(size(RESOURCES))
        temp = value.(MESS[:eAObjFixInvStoChaOS])
        for i in NEW_STO_CAP
            FixInvChaCosts[i] = temp[i]
        end
        dfLCOS[!, :FixInvChaCosts] = round.(FixInvChaCosts; digits = 2)
        dfTotal[!, :FixInvChaCosts] = [round(sum(FixInvChaCosts); digits = 2)]

        ## Fix costs - charge operation & maintenance costs
        FixFomChaCosts = value.(MESS[:eAObjFixFomStoChaOS])
        dfLCOS[!, :FixFomChaCosts] = round.(FixFomChaCosts; digits = 2)
        dfTotal[!, :FixFomChaCosts] = [round(sum(FixFomChaCosts); digits = 2)]

        ## Fix costs - charge sunk investment costs
        if IncludeExistingSto == 1
            FixSunkInvChaCosts = value.(MESS[:eAObjFixSunkInvStoChaOS])
            dfLCOS[!, :FixSunkInvChaCosts] = round.(FixSunkInvChaCosts; digits = 2)
            dfTotal[!, :FixSunkInvChaCosts] = [round(sum(FixSunkInvChaCosts); digits = 2)]
        end

        ## Variable costs - discharge operation costs
        VarStoDisCosts = value.(MESS[:eAObjVarStoDisOS])
        dfLCOS[!, :VarStoDisCosts] = round.(VarStoDisCosts; digits = 2)
        dfTotal[!, :VarStoDisCosts] = [round(sum(VarStoDisCosts); digits = 2)]

        ## Variable costs - charge operation costs
        VarStoChaCosts = value.(MESS[:eAObjVarStoChaOS])
        dfLCOS[!, :VarStoChaCosts] = round.(VarStoChaCosts; digits = 2)
        dfTotal[!, :VarStoChaCosts] = [round(sum(VarStoChaCosts); digits = 2)]

        ## Total costs of each storage = FixInvEneCosts + FixFomEneCosts + FixSunkInvEneCosts (if) +
        ## FixInvDisCosts + FixFomDisCosts + FixSunkInvDisCosts (if) +
        ## FixInvChaCosts + FixFomChaCosts + FixSunkInvChaCosts (if) +
        ## VarStoDisCosts + VarStoChaCosts
        dfLCOS = transform(dfLCOS, Cols(x -> contains(x, "Costs")) => (+) => :Costs)
        dfTotal[!, :Costs] = [round(sum(dfLCOS[!, :Costs]); digits = 2)]

        ## Total discharge
        dfLCOS[!, :Discharge] = round.(vec(sum(value.(MESS[:vAStoDis]); dims = 2)); digits = 2)
        dfTotal[!, :Discharge] = [round(sum(dfLCOS[!, :Discharge]); digits = 2)]

        ## Total charge
        dfLCOS[!, :Charge] = round.(vec(sum(value.(MESS[:vAStoCha]); dims = 2)); digits = 2)
        dfTotal[!, :Charge] = [round(sum(dfLCOS[!, :Charge]); digits = 2)]

        ## Capacity
        dfLCOS[!, :Capacity] = round.(value.(MESS[:eAStoEneCap]); digits = 2)
        dfTotal[!, :Capacity] = [round(sum(dfLCOS[!, :Capacity]); digits = 2)]

        ## LCOS calulation
        dfLCOS = transform(
            dfLCOS,
            [:Costs, :Discharge] =>
                ByRow((C, D) -> D > 0 ? round(C / D; digits = 2) : 0.0) =>
                    Symbol("LCOS (\$/t)"),
        )
        dfTotal[!, Symbol("LCOS (\$/t)")] = [
            round(
                mean(
                    dfLCOS[dfLCOS[!, Symbol("LCOS (\$/t)")] .> 0, Symbol("LCOS (\$/t)")],
                    Weights(dfLCOS[dfLCOS[!, Symbol("LCOS (\$/t)")] .> 0, :Discharge]),
                );
                digits = 2,
            ),
        ]

        ## Database writing
        if haskey(settings, "DB")
            dfStorage = DataFrame(DBInterface.execute(settings["DB"], "SELECT * FROM AStorage"))
            dfStorage = innerjoin(dfStorage, dfLCOS, on = [:Resource, :ResourceType, :Zone])
            SQLite.drop!(settings["DB"], "AStorage")
            SQLite.load!(dfStorage, settings["DB"], "AStorage")
        end

        ## Merge total dataframe for csv results
        dfLCOS = vcat(dfLCOS, dfTotal)

        ## CSV writing
        CSV.write(joinpath(path, "LCOS_storage.csv"), dfLCOS)
    end
end
