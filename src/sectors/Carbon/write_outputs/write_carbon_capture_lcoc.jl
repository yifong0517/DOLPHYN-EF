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
function write_carbon_capture_lcoc(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 1
        carbon_settings = settings["CarbonSettings"]
        path = carbon_settings["SavePath"]
        IncludeExistingCap = carbon_settings["IncludeExistingCap"]

        weights = inputs["weights"]
        carbon_inputs = inputs["CarbonInputs"]
        RESOURCES = carbon_inputs["GenResources"]
        dfGen = carbon_inputs["dfGen"]

        ## Generator dataframe
        dfLCOC = DataFrame(
            Resource = RESOURCES,
            ResourceType = string.(dfGen[!, :Resource_Type]),
            Zone = string.(dfGen[!, :Zone]),
        )
        dfTotal = DataFrame(Resource = "Sum", ResourceType = "Sum", Zone = "Sum")

        NEW_CAPTURE_CAP = carbon_inputs["NEW_CAPTURE_CAP"]
        RESOURCES = carbon_inputs["GenResources"]

        ## Fix costs - investment costs
        FixInvCosts = zeros(size(RESOURCES))
        temp = value.(MESS[:eCObjFixInvCapOG])
        for i in NEW_CAPTURE_CAP
            FixInvCosts[i] = temp[i]
        end
        dfLCOC[!, :FixInvCosts] = round.(FixInvCosts; digits = 2)
        dfTotal[!, :FixInvCosts] = [round(sum(FixInvCosts); digits = 2)]

        ## Fix costs - operation & maintenance costs
        FixFomCosts = value.(MESS[:eCObjFixFomCapOG])
        dfLCOC[!, :FixFomCosts] = round.(FixFomCosts; digits = 2)
        dfTotal[!, :FixFomCosts] = [round(sum(FixFomCosts); digits = 2)]

        ## Fix costs - sunk investment costs
        if IncludeExistingCap > 0
            FixSunkInvCosts = value.(MESS[:eCObjFixSunkInvCap])
            dfLCOC[!, :FixSunkInvCosts] = round.(FixSunkInvCosts; digits = 2)
            dfTotal[!, :FixSunkInvCosts] = [round(sum(FixSunkInvCosts); digits = 2)]
        end

        ## Variable costs - operation costs
        VarGenCosts = value.(MESS[:eCObjVarCapOG])
        dfLCOC[!, :VarGenCosts] = round.(VarGenCosts; digits = 2)
        dfTotal[!, :VarGenCosts] = [round(sum(VarGenCosts); digits = 2)]

        ## Variable costs - fuel costs
        if settings["ModelFuels"] == 1
            VarFuelCosts = value.(MESS[:eCObjVarFuelOG])
            dfLCOC[!, :VarFuelCosts] = round.(VarFuelCosts; digits = 2)
            dfTotal[!, :VarFuelCosts] = [round(sum(VarFuelCosts); digits = 2)]
        end

        ## Variable costs - electricity purchasing costs
        if !(settings["ModelPower"] == 1)
            VarElectricityCosts = value.(MESS[:eCObjVarElectricityOG])
        else
            VarElectricityCosts = vec(
                sum(
                    value.(MESS[:vCCap]) .*
                    (dual.(MESS[:cPBalance]) ./ transpose(weights))[dfGen[!, :ZoneIndex], :];
                    dims = 2,
                ) .* dfGen[!, :Electricity_Rate_MWh_per_tonne],
            )
        end
        dfLCOC[!, :VarElectricityCosts] = round.(VarElectricityCosts; digits = 2)
        dfTotal[!, :VarElectricityCosts] = [round(sum(VarElectricityCosts); digits = 2)]

        ## Variable costs - hydrogen purchasing costs
        if !(settings["ModelHydrogen"] == 1)
            VarHydrogenCosts = value.(MESS[:eCObjVarHydrogenOG])
        else
            VarHydrogenCosts = vec(
                sum(
                    value.(MESS[:vCCap]) .*
                    (dual.(MESS[:cHBalance]) ./ transpose(weights))[dfGen[!, :ZoneIndex], :];
                    dims = 2,
                ) .* dfGen[!, :Hydrogen_Rate_tonne_per_tonne],
            )
        end
        dfLCOC[!, :VarHydrogenCosts] = round.(VarHydrogenCosts; digits = 2)
        dfTotal[!, :VarHydrogenCosts] = [round(sum(VarHydrogenCosts); digits = 2)]

        ## Variable costs - bioenergy purchasing costs
        if !(settings["ModelBioenergy"] == 1)
            VarBioenergyCosts = value.(MESS[:eCObjVarBioenergyOG])
            dfLCOC[!, :VarBioenergyCosts] = round.(VarBioenergyCosts; digits = 2)
            dfTotal[!, :VarBioenergyCosts] = [round(sum(VarBioenergyCosts); digits = 2)]
        end

        ## Total costs of each generator = FixInvCosts + FixFomCosts + FixSunkInvCosts (if) + VarGenCosts
        ## + VarFuelCosts (if) + VarElectricityCosts + VarHydrogenCosts + VarBioenergyCosts (if)
        dfLCOC = transform(dfLCOC, Cols(x -> contains(x, "Costs")) => (+) => :Costs)
        dfTotal[!, :Costs] = [round(sum(dfLCOC[!, :Costs]); digits = 2)]

        ## Total captured carbon dioxide
        dfLCOC[!, :Capture] = round.(vec(sum(value.(MESS[:vCCap]); dims = 2)); digits = 2)
        dfTotal[!, :Capture] = [round(sum(dfLCOC[!, :Capture]); digits = 2)]

        ## Capacity
        dfLCOC[!, :Capacity] = round.(value.(MESS[:eCCaptureCap]); digits = 2)
        dfTotal[!, :Capacity] = [round(sum(dfLCOC[!, :Capacity]); digits = 2)]

        ## LCOC calulation
        dfLCOC = transform(
            dfLCOC,
            [:Costs, :Capture] =>
                ByRow((C, Cap) -> Cap > 0 ? round(C / Cap; digits = 2) : 0.0) =>
                    Symbol("LCOC (\$/tonne)"),
        )
        dfTotal[!, Symbol("LCOC (\$/tonne)")] = [
            round(
                mean(
                    dfLCOC[dfLCOC[!, Symbol("LCOC (\$/tonne)")] .> 0, Symbol("LCOC (\$/tonne)")],
                    Weights(dfLCOC[dfLCOC[!, Symbol("LCOC (\$/tonne)")] .> 0, :Capture]),
                );
                digits = 2,
            ),
        ]

        ## Database writing
        if haskey(settings, "DB")
            dfGenerator = DataFrame(DBInterface.execute(settings["DB"], "SELECT * FROM CGenerator"))
            dfGenerator = innerjoin(dfGenerator, dfLCOC, on = [:Resource, :ResourceType, :Zone])
            SQLite.drop!(settings["DB"], "CGenerator")
            SQLite.load!(dfGenerator, settings["DB"], "CGenerator")
        end

        ## Merge total dataframe for csv results
        dfLCOC = vcat(dfLCOC, dfTotal)

        ## CSV writing
        CSV.write(joinpath(path, "LCOC_capture.csv"), dfLCOC)
    end
end
