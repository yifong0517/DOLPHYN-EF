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
function write_carbon_truck_lcoc(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 1
        carbon_settings = settings["CarbonSettings"]
        path = carbon_settings["SavePath"]
        NetworkExpansion = carbon_settings["NetworkExpansion"]

        T = inputs["T"]
        weights = inputs["weights"]

        if settings["ModelFuels"] == 1
            Fuels_Index = inputs["Fuels_Index"]
            fuels_costs = inputs["fuels_costs"]
        end
        if !(settings["ModelPower"] == 1)
            Electricity_Index = inputs["Electricity_Index"]
            electricity_costs = inputs["electricity_costs"]
        end
        if !(settings["ModelHydrogen"] == 1)
            Hydrogen_Index = inputs["Hydrogen_Index"]
            hydrogen_costs = inputs["hydrogen_costs"]
        end

        carbon_inputs = inputs["CarbonInputs"]
        TRANSPORT_ZONES = carbon_inputs["TRANSPORT_ZONES"]
        TRUCK_TYPES = carbon_inputs["TRUCK_TYPES"]
        dfRoute = carbon_inputs["dfRoute"]
        dfTru = carbon_inputs["dfTru"]
        R = carbon_inputs["R"]

        ## Truck dataframe
        dfLCOC = DataFrame(TruckType = string.(dfTru[!, :Truck_Type]))
        dfTotal = DataFrame(TruckType = "Sum")

        if NetworkExpansion == 1
            ## Fix costs - investment costs
            FixInvCosts = value.(MESS[:eCObjFixInvTruOJ]).data
            dfLCOC[!, :FixInvCosts] = round.(FixInvCosts; digits = 2)
            dfTotal[!, :FixInvCosts] = [round(sum(FixInvCosts); digits = 2)]
            ## Fix costs - compression investment costs
            FixInvCompCosts = value.(MESS[:eCObjFixInvTruCompOJ]).data
            dfLCOC[!, :FixInvCompCosts] = round.(FixInvCompCosts; digits = 2)
            dfTotal[!, :FixInvCompCosts] = [round(sum(FixInvCompCosts); digits = 2)]
        end

        ## Fix costs - operation and maintenance costs
        FixFomCosts = value.(MESS[:eCObjFixFomTruOJ]).data
        dfLCOC[!, :FixFomCosts] = round.(FixFomCosts; digits = 2)
        dfTotal[!, :FixFomCosts] = [round(sum(FixFomCosts); digits = 2)]

        ## Fix costs - compression operation and maintainance costs
        FixFomCompCosts = value.(MESS[:eCObjFixFomTruCompOJ]).data
        dfLCOC[!, :FixFomCompCosts] = round.(FixFomCompCosts; digits = 2)
        dfTotal[!, :FixFomCompCosts] = [round(sum(FixFomCompCosts); digits = 2)]

        ## Var costs - truck costs
        VarTruCosts = value.(MESS[:eCObjVarTruOJ]).data
        dfLCOC[!, :VarTruCosts] = round.(VarTruCosts; digits = 2)
        dfTotal[!, :VarTruCosts] = [round(sum(VarTruCosts); digits = 2)]

        ## Var costs - compression costs
        VarTruCompCosts = value.(MESS[:eCObjVarTruCompOJ]).data
        dfLCOC[!, :VarTruCompCosts] = round.(VarTruCompCosts; digits = 2)
        dfTotal[!, :VarTruCompCosts] = [round(sum(VarTruCompCosts); digits = 2)]

        ## Var costs - fuel costs
        if settings["ModelFuels"] == 1
            temp = value.(MESS[:vCArriveFull]) .+ value.(MESS[:vCArriveEmpty])
            VarFuelCosts = [
                if dfTru[!, :Fuel][j] in Fuels_Index
                    sum(
                        weights[t] *
                        dfRoute[!, :Distance][r] *
                        temp[r, j, d, t] *
                        fuels_costs[dfTru[!, :Fuel][j]][t] for r in 1:R for d in [-1, 1] for
                        t in 1:T
                    ) * dfTru[!, :Fuel_MMBTU_per_mile][j]
                else
                    0
                end for j in TRUCK_TYPES
            ]
            dfLCOC[!, :VarFuelCosts] = round.(VarFuelCosts; digits = 2)
            dfTotal[!, :VarFuelCosts] = [round(sum(VarFuelCosts); digits = 2)]
        end

        ## Var costs - power costs
        if !(settings["ModelPower"] == 1)
            temp = value.(MESS[:vCArriveFull]) .+ value.(MESS[:vCArriveEmpty])
            VarPowCosts = [
                if dfTru[!, :Electricity][j] in Electricity_Index
                    sum(
                        weights[t] *
                        dfRoute[!, :Distance][r] *
                        temp[r, j, d, t] *
                        electricity_costs[dfTru[!, :Electricity][j]][t] for r in 1:R for
                        d in [-1, 1] for t in 1:T
                    ) * dfTru[!, :Electricity_MWh_per_mile][j]
                else
                    0
                end for j in TRUCK_TYPES
            ]
            dfLCOC[!, :VarPowCosts] = round.(VarPowCosts; digits = 2)
            dfTotal[!, :VarPowCosts] = [round(sum(VarPowCosts); digits = 2)]
        end

        ## Var costs - compression power costs
        if !(settings["ModelPower"] == 1)
            temp = value.(MESS[:vCLoaded])
            VarPowCompCosts = [
                if dfTru[!, :Electricity][j] in Electricity_Index
                    sum(
                        weights[t] *
                        temp[z, j, t] *
                        electricity_costs[dfTru[!, :Electricity][j]][t] for z in TRANSPORT_ZONES
                        for t in 1:T
                    ) *
                    dfTru[!, :Truck_Cap_tonne_per_unit][j] *
                    dfTru[!, :Truck_Comp_Energy_MWh_per_tonne][j]
                else
                    0
                end for j in TRUCK_TYPES
            ]
            dfLCOC[!, :VarPowCompCosts] = round.(VarPowCompCosts; digits = 2)
            dfTotal[!, :VarPowCompCosts] = [round(sum(VarPowCompCosts); digits = 2)]
        end

        ## Var costs - hydrogen costs
        if !(settings["ModelHydrogen"] == 1)
            temp = value.(MESS[:vCArriveFull]) .+ value.(MESS[:vCArriveEmpty])
            VarHFCCosts = [
                if dfTru[!, :Hydrogen][j] in Hydrogen_Index
                    sum(
                        weights[t] *
                        dfRoute[!, :Distance][r] *
                        temp[r, j, d, t] *
                        hydrogen_costs[dfTru[!, :Hydrogen][j]][t] for r in 1:R for d in [-1, 1]
                        for t in 1:T
                    ) * dfTru[!, :H2_tonne_per_mile][j]
                else
                    0
                end for j in TRUCK_TYPES
            ]
            dfLCOC[!, :VarHFCCosts] = round.(VarHFCCosts; digits = 2)
            dfTotal[!, :VarHFCCosts] = [round(sum(VarHFCCosts); digits = 2)]
        end

        ## Total costs of each truck type = FixInvCosts (if) + FixInvCompCosts (if) + FixFomCosts + FixFomCompCosts
        ## + VarTruCosts  + VarTruCompCosts + VarFuelCosts (if) + VarPowCosts (if) + VarPowCompCosts (if)
        dfLCOC = transform(dfLCOC, Cols(x -> contains(x, "Costs")) => (+) => :Costs)
        dfTotal[!, :Costs] = [round(sum(dfLCOC[!, :Costs]); digits = 2)]

        ## Truck route flow
        ArriveFull = Array(value.(MESS[:vCArriveFull]))
        for r in 1:R
            dfLCOC[!, Symbol("Flow_", r)] =
                round.(
                    vec(
                        dfTru[!, :Truck_Cap_tonne_per_unit] .*
                        (1 .- dfTru[!, :Loss_Percentage_per_mile]) .* dfRoute[!, :Distance][r] .*
                        sum(ArriveFull[r, :, :, :]; dims = [2, 3]),
                    );
                    digits = 2,
                )
            dfTotal[!, Symbol("Flow_", r)] = [round(sum(dfLCOC[!, Symbol("Flow_", r)]); digits = 2)]
        end

        ## Truck total flow mileage
        dfLCOC = transform(dfLCOC, Cols(x -> contains(x, "Flow")) => (+) => :Flow)
        dfTotal[!, :Flow] = [round(sum(dfLCOC[!, :Flow]); digits = 2)]

        ## LCOC calulation
        dfLCOC = transform(
            dfLCOC,
            [:Costs, :Flow] =>
                ByRow((C, F) -> F > 0 ? round(C / F; digits = 2) : 0.0) =>
                    Symbol("LCOC (\$/tonne)"),
        )

        dfTotal[!, Symbol("LCOC (\$/tonne)")] = [
            round(
                mean(
                    dfLCOC[dfLCOC[!, Symbol("LCOC (\$/tonne)")] .> 0, Symbol("LCOC (\$/tonne)")],
                    Weights(dfLCOC[dfLCOC[!, Symbol("LCOC (\$/tonne)")] .> 0, :Flow]),
                );
                digits = 2,
            ),
        ]

        ## Database writing
        if haskey(settings, "DB")
            dfTrucks = DataFrame(DBInterface.execute(settings["DB"], "SELECT * FROM CTrucks"))
            dfTrucks = innerjoin(dfTrucks, dfLCOC, on = :TruckType)
            SQLite.drop!(settings["DB"], "CTrucks")
            SQLite.load!(dfTrucks, settings["DB"], "CTrucks")
        end

        ## Merge total dataframe for csv results
        dfLCOC = vcat(dfLCOC, dfTotal)

        ## CSV writing
        CSV.write(joinpath(path, "LCOC_truck.csv"), dfLCOC)
    end
end
