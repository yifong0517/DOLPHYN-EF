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
function write_hydrogen_generation_lcoh(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 1
        hydrogen_settings = settings["HydrogenSettings"]
        path = hydrogen_settings["SavePath"]
        IncludeExistingGen = hydrogen_settings["IncludeExistingGen"]

        weights = inputs["weights"]
        hydrogen_inputs = inputs["HydrogenInputs"]
        RESOURCES = hydrogen_inputs["GenResources"]
        NEW_GEN_CAP = hydrogen_inputs["NEW_GEN_CAP"]
        dfGen = hydrogen_inputs["dfGen"]

        ## Generator dataframe
        dfLCOH = DataFrame(
            Resource = string.(RESOURCES),
            ResourceType = string.(dfGen[!, :Resource_Type]),
            Zone = string.(dfGen[!, :Zone]),
        )
        dfTotal = DataFrame(Resource = "Sum", ResourceType = "Sum", Zone = "Sum")

        ## Fix costs - investment costs
        FixInvCosts = zeros(size(RESOURCES))
        temp = value.(MESS[:eHObjFixInvGenOG])
        for i in NEW_GEN_CAP
            FixInvCosts[i] = temp[i]
        end
        dfLCOH[!, :FixInvCosts] = round.(FixInvCosts; digits = 2)
        dfTotal[!, :FixInvCosts] = [round(sum(FixInvCosts); digits = 2)]

        ## Fix costs - operation & maintenance costs
        FixFomCosts = value.(MESS[:eHObjFixFomGenOG])
        dfLCOH[!, :FixFomCosts] = round.(FixFomCosts; digits = 2)
        dfTotal[!, :FixFomCosts] = [round(sum(FixFomCosts); digits = 2)]

        ## Fix costs - sunk investment costs
        if IncludeExistingGen > 0
            FixSunkInvCosts = value.(MESS[:eHObjFixSunkInvGenOG])
            dfLCOH[!, :FixSunkInvCosts] = round.(FixSunkInvCosts; digits = 2)
            dfTotal[!, :FixSunkInvCosts] = [round(sum(FixSunkInvCosts); digits = 2)]
        end

        ## Variable costs - operation costs
        VarGenCosts = value.(MESS[:eHObjVarGenOG])
        dfLCOH[!, :VarGenCosts] = round.(VarGenCosts; digits = 2)
        dfTotal[!, :VarGenCosts] = [round(sum(VarGenCosts); digits = 2)]

        ## Variable costs - fuel costs
        if settings["ModelFuels"] == 1
            VarFuelCosts = value.(MESS[:eHObjVarFuelOG])
            dfLCOH[!, :VarFuelCosts] = round.(VarFuelCosts; digits = 2)
            dfTotal[!, :VarFuelCosts] = [round(sum(VarFuelCosts); digits = 2)]
        end

        ## Variable costs - electricity purchasing costs
        if !(settings["ModelPower"] == 1)
            VarElectricityCosts = value.(MESS[:eHObjVarElectricityOG])
        else
            VarElectricityCosts = vec(
                sum(
                    value.(MESS[:vHGen]) .*
                    (dual.(MESS[:cPBalance]) ./ transpose(weights))[dfGen[!, :ZoneIndex], :];
                    dims = 2,
                ) .* dfGen[!, :Electricity_Rate_MWh_per_tonne],
            )
        end
        dfLCOH[!, :VarElectricityCosts] = round.(VarElectricityCosts; digits = 2)
        dfTotal[!, :VarElectricityCosts] = [round(sum(VarElectricityCosts); digits = 2)]

        ## Variable costs - bioenergy purchasing costs
        if !(settings["ModelBioenergy"] == 1)
            VarBioenergyCosts = value.(MESS[:eHObjVarBioenergyOG])
            dfLCOH[!, :VarBioenergyCosts] = round.(VarBioenergyCosts; digits = 2)
            dfTotal[!, :VarBioenergyCosts] = [round(sum(VarBioenergyCosts); digits = 2)]
        end

        ## Total costs of each generator = FixInvCosts + FixFomCosts + FixSunkInvCosts (if) + VarGenCosts
        ## + VarFuelCosts (if) + VarElectricityCosts + VarBioenergyCosts (if)
        dfLCOH = transform(dfLCOH, Cols(x -> contains(x, "Costs")) => (+) => :Costs)
        dfTotal[!, :Costs] = [round(sum(dfLCOH[!, :Costs]); digits = 2)]

        ## Total generation
        dfLCOH[!, :Generation] = round.(vec(sum(value.(MESS[:vHGen]); dims = 2)); digits = 2)
        dfTotal[!, :Generation] = [round(sum(dfLCOH[!, :Generation]); digits = 2)]

        ## Capacity
        dfLCOH[!, :Capacity] = round.(value.(MESS[:eHGenCap]); digits = 2)
        dfTotal[!, :Capacity] = [round(sum(dfLCOH[!, :Capacity]); digits = 2)]

        ## LCOH calulation
        dfLCOH = transform(
            dfLCOH,
            [:Costs, :Generation] =>
                ByRow((C, G) -> G > 0 ? round(C / G; digits = 2) : 0.0) =>
                    Symbol("LCOH (\$/t)"),
        )
        dfTotal[!, Symbol("LCOH (\$/t)")] = [
            round(
                mean(
                    dfLCOH[dfLCOH[!, Symbol("LCOH (\$/t)")] .> 0, Symbol("LCOH (\$/t)")],
                    Weights(dfLCOH[dfLCOH[!, Symbol("LCOH (\$/t)")] .> 0, :Generation]),
                );
                digits = 2,
            ),
        ]

        ## Database writing
        if haskey(settings, "DB")
            dfGenerator = DataFrame(DBInterface.execute(settings["DB"], "SELECT * FROM HGenerator"))
            dfGenerator = innerjoin(dfGenerator, dfLCOH, on = [:Resource, :ResourceType, :Zone])
            SQLite.drop!(settings["DB"], "HGenerator")
            SQLite.load!(dfGenerator, settings["DB"], "HGenerator")
        end

        ## Merge total dataframe for csv results
        dfLCOH = vcat(dfLCOH, dfTotal)

        ## CSV writing
        CSV.write(joinpath(path, "LCOH_generation.csv"), dfLCOH)
    end
end
