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
function write_power_generation_lcoe(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 1
        power_settings = settings["PowerSettings"]
        path = power_settings["SavePath"]
        IncludeExistingGen = power_settings["IncludeExistingGen"]
        PReserve = power_settings["PReserve"]

        weights = inputs["weights"]
        power_inputs = inputs["PowerInputs"]
        RESOURCES = power_inputs["GenResources"]
        dfGen = power_inputs["dfGen"]

        NEW_GEN_CAP = power_inputs["NEW_GEN_CAP"]
        if PReserve == 1
            GEN_PRSV = power_inputs["GEN_PRSV"]
        end

        ## Generator dataframe
        dfLCOE = DataFrame(
            Resource = RESOURCES,
            ResourceType = string.(dfGen[!, :Resource_Type]),
            Zone = string.(dfGen[!, :Zone]),
        )
        dfTotal = DataFrame(Resource = "Sum", ResourceType = "Sum", Zone = "Sum")

        ## Fix costs - investment costs
        FixInvCosts = zeros(size(RESOURCES))
        temp = value.(MESS[:ePObjFixInvGenOG])
        for i in NEW_GEN_CAP
            FixInvCosts[i] = temp[i]
        end
        dfLCOE[!, :FixInvCosts] = round.(FixInvCosts; digits = 2)
        dfTotal[!, :FixInvCosts] = [round(sum(FixInvCosts); digits = 2)]

        ## Fix costs - operation & maintenance costs
        FixFomCosts = value.(MESS[:ePObjFixFomGenOG])
        dfLCOE[!, :FixFomCosts] = round.(FixFomCosts; digits = 2)
        dfTotal[!, :FixFomCosts] = [round(sum(FixFomCosts); digits = 2)]

        ## Fix costs - sunk investment costs
        if IncludeExistingGen > 0
            FixSunkInvCosts = value.(MESS[:ePObjFixSunkInvGenOG])
            dfLCOE[!, :FixSunkInvCosts] = round.(FixSunkInvCosts; digits = 2)
            dfTotal[!, :FixSunkInvCosts] = [round(sum(FixSunkInvCosts); digits = 2)]
        end

        ## Variable costs - operation costs
        VarGenCosts = value.(MESS[:ePObjVarGenOG])
        dfLCOE[!, :VarGenCosts] = round.(VarGenCosts; digits = 2)
        dfTotal[!, :VarGenCosts] = [round(sum(VarGenCosts); digits = 2)]

        ## Variable costs - fuel costs
        if settings["ModelFuels"] == 1
            VarFuelCosts = value.(MESS[:ePObjVarFuelOG])
            dfLCOE[!, :VarFuelCosts] = round.(VarFuelCosts; digits = 2)
            dfTotal[!, :VarFuelCosts] = [round(sum(VarFuelCosts); digits = 2)]
        end

        ## Variable costs - hydrogen purchasing costs
        if !(settings["ModelHydrogen"] == 1)
            VarHydrogenCosts = value.(MESS[:ePObjVarHydrogenOG])
        else
            VarHydrogenCosts = vec(
                sum(
                    value.(MESS[:vPGen]) .*
                    (dual.(MESS[:cHBalance]) ./ transpose(weights))[dfGen[!, :ZoneIndex], :];
                    dims = 2,
                ) .* dfGen[!, :Hydrogen_Rate_tonne_per_MWh],
            )
        end
        dfLCOE[!, :VarHydrogenCosts] = round.(VarHydrogenCosts; digits = 2)
        dfTotal[!, :VarHydrogenCosts] = [round(sum(VarHydrogenCosts); digits = 2)]

        ## Variable costs - bioenergy purchasing costs
        if !(settings["ModelBioenergy"] == 1)
            VarBioenergyCosts = value.(MESS[:ePObjVarBioenergyOG])
            dfLCOE[!, :VarBioenergyCosts] = round.(VarBioenergyCosts; digits = 2)
            dfTotal[!, :VarBioenergyCosts] = [round(sum(VarBioenergyCosts); digits = 2)]
        end

        ## Variable costs - primary reserve costs
        if PReserve == 1
            VarGenPRSVCosts = zeros(size(RESOURCES))
            temp = value.(MESS[:ePObjVarReserveGenOG])
            for i in GEN_PRSV
                VarGenPRSVCosts[i] = temp[i]
            end
            dfLCOE[!, :VarGenPRSVCosts] = round.(VarGenPRSVCosts; digits = 2)
            dfTotal[!, :VarGenPRSVCosts] = [round(sum(VarGenPRSVCosts); digits = 2)]
        end

        ## Total costs of each generator = FixInvCosts + FixFomCosts + FixSunkInvCosts (if) + VarGenCosts
        ## + VarFuelCosts (if) + VarHydrogenCosts (if) + VarBioenergyCosts (if) + VarPRSVCosts (if)
        dfLCOE = transform(dfLCOE, Cols(x -> contains(x, "Costs")) => (+) => :Costs)
        dfTotal[!, "Costs"] = [round(sum(dfLCOE[!, :Costs]); digits = 2)]

        ## Capacity
        dfLCOE[!, :Capacity] = round.(value.(MESS[:ePGenCap]); digits = 2)
        dfTotal[!, :Capacity] = [round(sum(dfLCOE[!, :Capacity]); digits = 2)]

        ## Total generation
        dfLCOE[!, :Generation] = round.(vec(sum(value.(MESS[:vPGen]); dims = 2)); digits = 2)
        dfTotal[!, :Generation] = [round(sum(dfLCOE[!, :Generation]); digits = 2)]

        ## LCOE calulation
        dfLCOE = transform(
            dfLCOE,
            [:Costs, :Generation] =>
                ByRow((C, G) -> G > 0 ? round(C / G; digits = 2) : 0.0) =>
                    Symbol("LCOE (\$/MWh)"),
        )
        dfTotal[!, Symbol("LCOE (\$/MWh)")] = [
            round(
                mean(
                    dfLCOE[dfLCOE[!, Symbol("LCOE (\$/MWh)")] .> 0, Symbol("LCOE (\$/MWh)")],
                    Weights(dfLCOE[dfLCOE[!, Symbol("LCOE (\$/MWh)")] .> 0, :Generation]),
                );
                digits = 2,
            ),
        ]

        ## Database writing
        if haskey(settings, "DB")
            dfGenerator = DataFrame(DBInterface.execute(settings["DB"], "SELECT * FROM PGenerator"))
            dfGenerator = innerjoin(dfGenerator, dfLCOE, on = [:Resource, :ResourceType, :Zone])
            SQLite.drop!(settings["DB"], "PGenerator")
            SQLite.load!(dfGenerator, settings["DB"], "PGenerator")
        end

        ## Merge total dataframe for csv results
        dfLCOE = vcat(dfLCOE, dfTotal)

        ## CSV writing
        CSV.write(joinpath(path, "LCOE_generation.csv"), dfLCOE)
    end
end
