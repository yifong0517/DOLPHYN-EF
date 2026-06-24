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
function write_ammonia_generation_lcoa(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 1
        ammonia_settings = settings["AmmoniaSettings"]
        path = ammonia_settings["SavePath"]
        IncludeExistingGen = ammonia_settings["IncludeExistingGen"]

        weights = inputs["weights"]
        ammonia_inputs = inputs["AmmoniaInputs"]
        RESOURCES = ammonia_inputs["GenResources"]
        dfGen = ammonia_inputs["dfGen"]

        ## Generator dataframe
        dfLCOA = DataFrame(
            Resource = RESOURCES,
            ResourceType = string.(dfGen[!, :Resource_Type]),
            Zone = string.(dfGen[!, :Zone]),
        )
        dfTotal = DataFrame(Resource = "Sum", ResourceType = "Sum", Zone = "Sum")

        NEW_GEN_CAP = ammonia_inputs["NEW_GEN_CAP"]
        RESOURCES = ammonia_inputs["GenResources"]

        ## Fix costs - investment costs
        FixInvCosts = zeros(size(RESOURCES))
        temp = value.(MESS[:eAObjFixInvGenOG])
        for i in NEW_GEN_CAP
            FixInvCosts[i] = temp[i]
        end
        dfLCOA[!, :FixInvCosts] = round.(FixInvCosts; digits = 2)
        dfTotal[!, :FixInvCosts] = [round(sum(FixInvCosts); digits = 2)]

        ## Fix costs - operation & maintenance costs
        FixFomCosts = value.(MESS[:eAObjFixFomGenOG])
        dfLCOA[!, :FixFomCosts] = round.(FixFomCosts; digits = 2)
        dfTotal[!, :FixFomCosts] = [round(sum(FixFomCosts); digits = 2)]

        ## Fix costs - sunk investment costs
        if IncludeExistingGen > 0
            FixSunkInvCosts = value.(MESS[:eAObjFixSunkInvGenOG])
            dfLCOA[!, :FixSunkInvCosts] = round.(FixSunkInvCosts; digits = 2)
            dfTotal[!, :FixSunkInvCosts] = [round(sum(FixSunkInvCosts); digits = 2)]
        end

        ## Variable costs - operation costs
        VarGenCosts = value.(MESS[:eAObjVarGenOG])
        dfLCOA[!, :VarGenCosts] = round.(VarGenCosts; digits = 2)
        dfTotal[!, :VarGenCosts] = [round(sum(VarGenCosts); digits = 2)]

        ## Variable costs - fuel costs
        if settings["ModelFuels"] == 1
            VarFuelCosts = value.(MESS[:eAObjVarFuelOG])
            dfLCOA[!, :VarFuelCosts] = round.(VarFuelCosts; digits = 2)
            dfTotal[!, :VarFuelCosts] = [round(sum(VarFuelCosts); digits = 2)]
        end

        ## Variable costs - electricity purchasing costs
        if !(settings["ModelPower"] == 1)
            VarElectricityCosts = value.(MESS[:eAObjVarElectricityOG])
        else
            VarElectricityCosts = vec(
                sum(
                    value.(MESS[:vAGen]) .*
                    (dual.(MESS[:cPBalance]) ./ transpose(weights))[dfGen[!, :ZoneIndex], :];
                    dims = 2,
                ) .* dfGen[!, :Electricity_Rate_MWh_per_tonne],
            )
        end
        dfLCOA[!, :VarElectricityCosts] = round.(VarElectricityCosts; digits = 2)
        dfTotal[!, :VarElectricityCosts] = [round(sum(VarElectricityCosts); digits = 2)]

        ## Variable costs - hydrogen purchasing costs
        if !(settings["ModelHydrogen"] == 1)
            VarHydrogenCosts = value.(MESS[:eAObjVarHydrogenOG])
        else
            VarHydrogenCosts = vec(
                sum(
                    value.(MESS[:vAGen]) .*
                    (dual.(MESS[:cHBalance]) ./ transpose(weights))[dfGen[!, :ZoneIndex], :];
                    dims = 2,
                ) .* dfGen[!, :Hydrogen_Rate_tonne_per_tonne],
            )
        end
        dfLCOA[!, :VarHydrogenCosts] = round.(VarHydrogenCosts; digits = 2)
        dfTotal[!, :VarHydrogenCosts] = [round(sum(VarHydrogenCosts); digits = 2)]

        ## Variable costs - bioenergy purchasing costs
        if !(settings["ModelBioenergy"] == 1)
            VarBioenergyCosts = value.(MESS[:eAObjVarBioenergyOG])
            dfLCOA[!, :VarBioenergyCosts] = round.(VarBioenergyCosts; digits = 2)
            dfTotal[!, :VarBioenergyCosts] = [round(sum(VarBioenergyCosts); digits = 2)]
        end

        ## Total costs of each generator = FixInvCosts + FixFomCosts + FixSunkInvCosts (if) + VarGenCosts
        ## + VarFuelCosts (if) + VarElectricityCosts + VarHydrogenCosts + VarBioenergyCosts (if)
        dfLCOA = transform(dfLCOA, Cols(x -> contains(x, "Costs")) => (+) => :Costs)
        dfTotal[!, :Costs] = [round(sum(dfLCOA[!, :Costs]); digits = 2)]

        ## Total generation
        dfLCOA[!, :Generation] = round.(vec(sum(value.(MESS[:vAGen]); dims = 2)); digits = 2)
        dfTotal[!, :Generation] = [round(sum(dfLCOA[!, :Generation]); digits = 2)]

        ## Capacity
        dfLCOA[!, :Capacity] = round.(value.(MESS[:eAGenCap]); digits = 2)
        dfTotal[!, :Capacity] = [round(sum(dfLCOA[!, :Capacity]); digits = 2)]

        ## LCOA calulation
        dfLCOA = transform(
            dfLCOA,
            [:Costs, :Generation] =>
                ByRow((C, G) -> G > 0 ? round(C / G; digits = 2) : 0.0) =>
                    Symbol("LCOA (\$/t)"),
        )
        dfTotal[!, Symbol("LCOA (\$/t)")] = [
            round(
                mean(
                    dfLCOA[dfLCOA[!, Symbol("LCOA (\$/t)")] .> 0, Symbol("LCOA (\$/t)")],
                    Weights(dfLCOA[dfLCOA[!, Symbol("LCOA (\$/t)")] .> 0, :Generation]),
                );
                digits = 2,
            ),
        ]

        ## Database writing
        if haskey(settings, "DB")
            dfGenerator = DataFrame(DBInterface.execute(settings["DB"], "SELECT * FROM AGenerator"))
            dfGenerator = innerjoin(dfGenerator, dfLCOA, on = [:Resource, :ResourceType, :Zone])
            SQLite.drop!(settings["DB"], "AGenerator")
            SQLite.load!(dfGenerator, settings["DB"], "AGenerator")
        end

        ## Merge total dataframe for csv results
        dfLCOA = vcat(dfLCOA, dfTotal)

        ## CSV writing
        CSV.write(joinpath(path, "LCOA_generation.csv"), dfLCOA)
    end
end
