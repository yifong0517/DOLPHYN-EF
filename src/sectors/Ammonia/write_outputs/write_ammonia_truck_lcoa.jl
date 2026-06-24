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
function write_ammonia_truck_lcoa(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 1
        ammonia_settings = settings["AmmoniaSettings"]
        path = ammonia_settings["SavePath"]
        NetworkExpansion = ammonia_settings["NetworkExpansion"]

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

        ammonia_inputs = inputs["AmmoniaInputs"]
        TRANSPORT_ZONES = ammonia_inputs["TRANSPORT_ZONES"]
        TRUCK_TYPES = ammonia_inputs["TRUCK_TYPES"]
        dfRoute = ammonia_inputs["dfRoute"]
        dfTru = ammonia_inputs["dfTru"]
        R = ammonia_inputs["R"]

        ## Truck dataframe
        dfLCOA = DataFrame(TruckType = string.(dfTru[!, :Truck_Type]))
        dfTotal = DataFrame(TruckType = "Sum")

        if NetworkExpansion == 1
            ## Fix costs - investment costs
            FixInvCosts = value.(MESS[:eAObjFixInvTruOJ]).data
            dfLCOA[!, :FixInvCosts] = round.(FixInvCosts; digits = 2)
            dfTotal[!, :FixInvCosts] = [round(sum(FixInvCosts); digits = 2)]
            ## Fix costs - compression investment costs
            FixInvCompCosts = value.(MESS[:eAObjFixInvTruCompOJ]).data
            dfLCOA[!, :FixInvCompCosts] = round.(FixInvCompCosts; digits = 2)
            dfTotal[!, :FixInvCompCosts] = [round(sum(FixInvCompCosts); digits = 2)]
        end

        ## Fix costs - operation and maintenance costs
        FixFomCosts = value.(MESS[:eAObjFixFomTruOJ]).data
        dfLCOA[!, :FixFomCosts] = round.(FixFomCosts; digits = 2)
        dfTotal[!, :FixFomCosts] = [round(sum(FixFomCosts); digits = 2)]

        ## Fix costs - compression operation and maintainance costs
        FixFomCompCosts = value.(MESS[:eAObjFixFomTruCompOJ]).data
        dfLCOA[!, :FixFomCompCosts] = round.(FixFomCompCosts; digits = 2)
        dfTotal[!, :FixFomCompCosts] = [round(sum(FixFomCompCosts); digits = 2)]

        ## Var costs - truck costs
        VarTruCosts = value.(MESS[:eAObjVarTruOJ]).data
        dfLCOA[!, :VarTruCosts] = round.(VarTruCosts; digits = 2)
        dfTotal[!, :VarTruCosts] = [round(sum(VarTruCosts); digits = 2)]

        ## Var costs - compression costs
        VarTruCompCosts = value.(MESS[:eAObjVarTruCompOJ]).data
        dfLCOA[!, :VarTruCompCosts] = round.(VarTruCompCosts; digits = 2)
        dfTotal[!, :VarTruCompCosts] = [round(sum(VarTruCompCosts); digits = 2)]

        ## Var costs - fuel costs
        if settings["ModelFuels"] == 1
            temp = value.(MESS[:vAArriveFull]) .+ value.(MESS[:vAArriveEmpty])
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
            dfLCOA[!, :VarFuelCosts] = round.(VarFuelCosts; digits = 2)
            dfTotal[!, :VarFuelCosts] = [round(sum(VarFuelCosts); digits = 2)]
        end

        ## Var costs - power costs
        if !(settings["ModelPower"] == 1)
            temp = value.(MESS[:vAArriveFull]) .+ value.(MESS[:vAArriveEmpty])
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
            dfLCOA[!, :VarPowCosts] = round.(VarPowCosts; digits = 2)
            dfTotal[!, :VarPowCosts] = [round(sum(VarPowCosts); digits = 2)]
        end

        ## Var costs - compression power costs
        if !(settings["ModelPower"] == 1)
            temp = value.(MESS[:vALoaded])
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
            dfLCOA[!, :VarPowCompCosts] = round.(VarPowCompCosts; digits = 2)
            dfTotal[!, :VarPowCompCosts] = [round(sum(VarPowCompCosts); digits = 2)]
        end

        ## Var costs - hydrogen costs
        if !(settings["ModelHydrogen"] == 1)
            temp = value.(MESS[:vAArriveFull]) .+ value.(MESS[:vAArriveEmpty])
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
            dfLCOA[!, :VarHFCCosts] = round.(VarHFCCosts; digits = 2)
            dfTotal[!, :VarHFCCosts] = [round(sum(VarHFCCosts); digits = 2)]
        end

        ## Total costs of each truck type = FixInvCosts (if) + FixInvCompCosts (if) + FixFomCosts + FixFomCompCosts
        ## + VarTruCosts  + VarTruCompCosts + VarFuelCosts (if) + VarPowCosts (if) + VarPowCompCosts (if)
        dfLCOA = transform(dfLCOA, Cols(x -> contains(x, "Costs")) => (+) => :Costs)
        dfTotal[!, :Costs] = [round(sum(dfLCOA[!, :Costs]); digits = 2)]

        ## Truck route flow
        ArriveFull = Array(value.(MESS[:vAArriveFull]))
        for r in 1:R
            dfLCOA[!, Symbol("Flow_", r)] =
                round.(
                    vec(
                        dfTru[!, :Truck_Cap_tonne_per_unit] .*
                        (1 .- dfTru[!, :Loss_Percentage_per_mile]) .* dfRoute[!, :Distance][r] .*
                        sum(ArriveFull[r, :, :, :]; dims = [2, 3]),
                    );
                    digits = 2,
                )
            dfTotal[!, Symbol("Flow_", r)] = [round(sum(dfLCOA[!, Symbol("Flow_", r)]); digits = 2)]
        end

        ## Truck total flow mileage
        dfLCOA = transform(dfLCOA, Cols(x -> contains(x, "Flow")) => (+) => :Flow)
        dfTotal[!, :Flow] = [round(sum(dfLCOA[!, :Flow]); digits = 2)]

        ## LCOH calulation
        dfLCOA = transform(
            dfLCOA,
            [:Costs, :Flow] =>
                ByRow((C, F) -> F > 0 ? round(C / F; digits = 2) : 0.0) =>
                    Symbol("LCOH (\$/t)"),
        )

        dfTotal[!, Symbol("LCOH (\$/t)")] = [
            round(
                mean(
                    dfLCOA[dfLCOA[!, Symbol("LCOH (\$/t)")] .> 0, Symbol("LCOH (\$/t)")],
                    Weights(dfLCOA[dfLCOA[!, Symbol("LCOH (\$/t)")] .> 0, :Flow]),
                );
                digits = 2,
            ),
        ]

        ## Database writing
        if haskey(settings, "DB")
            dfTrucks = DataFrame(DBInterface.execute(settings["DB"], "SELECT * FROM ATrucks"))
            dfTrucks = innerjoin(dfTrucks, dfLCOA, on = :TruckType)
            SQLite.drop!(settings["DB"], "ATrucks")
            SQLite.load!(dfTrucks, settings["DB"], "ATrucks")
        end

        ## Merge total dataframe for csv results
        dfLCOA = vcat(dfLCOA, dfTotal)

        ## CSV writing
        CSV.write(joinpath(path, "LCOA_truck.csv"), dfLCOA)
    end
end
