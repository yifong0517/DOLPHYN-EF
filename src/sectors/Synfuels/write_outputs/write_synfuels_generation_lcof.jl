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
function write_synfuels_generation_lcof(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 1
        synfuels_settings = settings["SynfuelsSettings"]
        path = synfuels_settings["SavePath"]
        IncludeExistingGen = synfuels_settings["IncludeExistingGen"]

        weights = inputs["weights"]
        synfuels_inputs = inputs["SynfuelsInputs"]
        RESOURCES = synfuels_inputs["GenResources"]
        dfGen = synfuels_inputs["dfGen"]

        ## Generator dataframe
        dfLCOF = DataFrame(
            Resource = RESOURCES,
            ResourceType = string.(dfGen[!, :Resource_Type]),
            Zone = string.(dfGen[!, :Zone]),
        )
        dfTotal = DataFrame(Resource = "Sum", ResourceType = "Sum", Zone = "Sum")

        NEW_GEN_CAP = synfuels_inputs["NEW_GEN_CAP"]
        RESOURCES = synfuels_inputs["GenResources"]

        ## Fix costs - investment costs
        FixInvCosts = zeros(size(RESOURCES))
        temp = value.(MESS[:eSObjFixInvGenOG])
        for i in NEW_GEN_CAP
            FixInvCosts[i] = temp[i]
        end
        dfLCOF[!, :FixInvCosts] = round.(FixInvCosts; digits = 2)
        dfTotal[!, :FixInvCosts] = [round(sum(FixInvCosts); digits = 2)]

        ## Fix costs - operation & maintenance costs
        FixFomCosts = value.(MESS[:eSObjFixFomGenOG])
        dfLCOF[!, :FixFomCosts] = round.(FixFomCosts; digits = 2)
        dfTotal[!, :FixFomCosts] = [round(sum(FixFomCosts); digits = 2)]

        ## Fix costs - sunk investment costs
        if IncludeExistingGen > 0
            FixSunkInvCosts = value.(MESS[:eSObjFixSunkInvGenOG])
            dfLCOF[!, :FixSunkInvCosts] = round.(FixSunkInvCosts; digits = 2)
            dfTotal[!, :FixSunkInvCosts] = [round(sum(FixSunkInvCosts); digits = 2)]
        end

        ## Variable costs - operation costs
        VarGenCosts = value.(MESS[:eSObjVarGenOG])
        dfLCOF[!, :VarGenCosts] = round.(VarGenCosts; digits = 2)
        dfTotal[!, :VarGenCosts] = [round(sum(VarGenCosts); digits = 2)]

        ## Variable costs - fuel costs
        if settings["ModelFuels"] == 1
            VarFuelCosts = value.(MESS[:eSObjVarFuelOG])
            dfLCOF[!, :VarFuelCosts] = round.(VarFuelCosts; digits = 2)
            dfTotal[!, :VarFuelCosts] = [round(sum(VarFuelCosts); digits = 2)]
        end

        ## Variable costs - electricity purchasing costs
        if !(settings["ModelPower"] == 1)
            VarElectricityCosts = value.(MESS[:eSObjVarElectricityOG])
        else
            VarElectricityCosts = vec(
                sum(
                    value.(MESS[:vSGen]) .*
                    (dual.(MESS[:cPBalance]) ./ transpose(weights))[dfGen[!, :ZoneIndex], :];
                    dims = 2,
                ) .* dfGen[!, :Electricity_Rate_MWh_per_tonne],
            )
        end
        dfLCOF[!, :VarElectricityCosts] = round.(VarElectricityCosts; digits = 2)
        dfTotal[!, :VarElectricityCosts] = [round(sum(VarElectricityCosts); digits = 2)]

        ## Variable costs - hydrogen purchasing costs
        if !(settings["ModelHydrogen"] == 1)
            VarHydrogenCosts = value.(MESS[:eSObjVarHydrogenOG])
        else
            VarHydrogenCosts = vec(
                sum(
                    value.(MESS[:vSGen]) .*
                    (dual.(MESS[:cHBalance]) ./ transpose(weights))[dfGen[!, :ZoneIndex], :];
                    dims = 2,
                ) .* dfGen[!, :Hydrogen_Rate_tonne_per_tonne],
            )
        end
        dfLCOF[!, :VarHydrogenCosts] = round.(VarHydrogenCosts; digits = 2)
        dfTotal[!, :VarHydrogenCosts] = [round(sum(VarHydrogenCosts); digits = 2)]

        ## Variable costs - carbon purchasing costs
        if !(settings["ModelCarbon"] == 1)
            VarCarbonCosts = value.(MESS[:eSObjVarCarbonOG])
        else
            VarCarbonCosts = vec(
                sum(
                    value.(MESS[:vSGen]) .*
                    (dual.(MESS[:cCBalance]) ./ transpose(weights))[dfGen[!, :ZoneIndex], :];
                    dims = 2,
                ) .* dfGen[!, :Carbon_Rate_tonne_per_tonne],
            )
        end
        dfLCOF[!, :VarCarbonCosts] = round.(VarCarbonCosts; digits = 2)
        dfTotal[!, :VarCarbonCosts] = [round(sum(VarCarbonCosts); digits = 2)]

        ## Variable costs - bioenergy purchasing costs
        if !(settings["ModelBioenergy"] == 1)
            VarBioenergyCosts = value.(MESS[:eSObjVarBioenergyOG])
            dfLCOF[!, :VarBioenergyCosts] = round.(VarBioenergyCosts; digits = 2)
            dfTotal[!, :VarBioenergyCosts] = [round(sum(VarBioenergyCosts); digits = 2)]
        end

        ## Total costs of each generator = FixInvCosts + FixFomCosts + FixSunkInvCosts (if) + VarGenCosts
        ## + VarFuelCosts (if) + VarElectricityCosts + VarHydrogenCosts + VarCarbonCosts + VarBioenergyCosts (if)
        dfLCOF = transform(dfLCOF, Cols(x -> contains(x, "Costs")) => (+) => :Costs)
        dfTotal[!, :Costs] = [round(sum(dfLCOF[!, :Costs]); digits = 2)]

        ## Total generation
        dfLCOF[!, :Generation] = round.(vec(sum(value.(MESS[:vSGen]); dims = 2)); digits = 2)
        dfTotal[!, :Generation] = [round(sum(dfLCOF[!, :Generation]); digits = 2)]

        ## Capacity
        dfLCOF[!, :Capacity] = round.(value.(MESS[:eSGenCap]); digits = 2)
        dfTotal[!, :Capacity] = [round(sum(dfLCOF[!, :Capacity]); digits = 2)]

        ## LCOF calulation
        dfLCOF = transform(
            dfLCOF,
            [:Costs, :Generation] =>
                ByRow((C, G) -> G > 0 ? round(C / G; digits = 2) : 0.0) =>
                    Symbol("LCOF (\$/t)"),
        )
        dfTotal[!, Symbol("LCOF (\$/t)")] = [
            round(
                mean(
                    dfLCOF[dfLCOF[!, Symbol("LCOF (\$/t)")] .> 0, Symbol("LCOF (\$/t)")],
                    Weights(dfLCOF[dfLCOF[!, Symbol("LCOF (\$/t)")] .> 0, :Generation]),
                );
                digits = 2,
            ),
        ]

        ## Database writing
        if haskey(settings, "DB")
            dfGenerator = DataFrame(DBInterface.execute(settings["DB"], "SELECT * FROM SGenerator"))
            dfGenerator = innerjoin(dfGenerator, dfLCOF, on = [:Resource, :ResourceType, :Zone])
            SQLite.drop!(settings["DB"], "SGenerator")
            SQLite.load!(dfGenerator, settings["DB"], "SGenerator")
        end

        ## Merge total dataframe for csv results
        dfLCOF = vcat(dfLCOF, dfTotal)

        ## CSV writing
        CSV.write(joinpath(path, "LCOF_generation.csv"), dfLCOF)
    end
end
