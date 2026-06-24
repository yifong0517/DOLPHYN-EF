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
	write_bioenergy_truck_flow(settings::Dict, inputs::Dict, MESS::Model)

Fucntion for reporting bioenergy flow via trucsk.
"""
function write_bioenergy_truck_flow(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        bioenergy_settings = settings["BioenergySettings"]
        path = bioenergy_settings["SavePath"]

        Z = inputs["Z"]
        T = inputs["T"]

        bioenergy_inputs = inputs["BioenergyInputs"]

        TRUCK_TYPES = bioenergy_inputs["TRUCK_TYPES"]
        TRUCK_ZONES = bioenergy_inputs["TRUCK_ZONES"]
        Residuals = bioenergy_inputs["Residuals"]

        R = bioenergy_inputs["R"]

        dfTru = bioenergy_inputs["dfTru"]
        dfRoute = bioenergy_inputs["dfRoute"]

        ## Bioenergy truck flow
        truck_flow_path = joinpath(path, "TruckFlow")
        if (isdir(truck_flow_path) == false)
            mkdir(truck_flow_path)
        end

        temp = value.(MESS[:vBTruckFlow])
        for j in TRUCK_TYPES
            dfTruckFlow = DataFrame(Time = 1:T)
            for z in TRUCK_ZONES
                for f in eachindex(Residuals)
                    dfTruckFlow[!, Symbol("$(z)_$(f)")] = temp[z, j, f, :]
                end
            end
            CSV.write(
                joinpath(truck_flow_path, string("TruckFlow_", dfTru[!, :Truck_Type][j], ".csv")),
                dfTruckFlow,
            )
        end

        ## Residual truck Number
        truck_number_path = joinpath(path, "TruckNumber")
        if (isdir(truck_number_path) == false)
            mkdir(truck_number_path)
        end

        dfTruckNumberFull = DataFrame(Time = 1:T)
        dfTruckNumberEmpty = DataFrame(Time = 1:T)
        temp_full = round.(value.(MESS[:vBFull]); digits = 2)
        temp_empty = round.(value.(MESS[:vBEmpty]); digits = 2)
        for j in TRUCK_TYPES
            for f in eachindex(Residuals)
                dfTruckNumberFull[!, Symbol(string(dfTru[!, :Truck_Type][j]), Residuals[f])] =
                    temp_full[j, f, :]
            end
            dfTruckNumberEmpty[!, Symbol(dfTru[!, :Truck_Type][j])] = temp_empty[j, :]
        end
        CSV.write(joinpath(truck_number_path, "Bioenergy_TruckNumberFull.csv"), dfTruckNumberFull)
        CSV.write(joinpath(truck_number_path, "Bioenergy_TruckNumberEmpty.csv"), dfTruckNumberEmpty)

        ## Hydrogen truck state
        truck_state_path = joinpath(path, "TruckState")
        if (isdir(truck_state_path) == false)
            mkdir(truck_state_path)
        end
        dfTruckAvailFull = DataFrame(Time = 1:T)
        dfTruckAvailEmpty = DataFrame(Time = 1:T)
        dfTruckCharged = DataFrame(Time = 1:T)
        dfTruckDischarged = DataFrame(Time = 1:T)
        temp_avail_full = round.(value.(MESS[:vBAvailFull]); digits = 2)
        temp_avail_empty = round.(value.(MESS[:vBAvailEmpty]); digits = 2)
        temp_charged = round.(value.(MESS[:vBLoaded]); digits = 2)
        temp_discharged = round.(value.(MESS[:vBUnloaded]); digits = 2)
        for j in TRUCK_TYPES
            for z in TRUCK_ZONES
                for f in eachindex(Residuals)
                    dfTruckAvailFull[
                        !,
                        Symbol(string("$(z)_", dfTru[!, :Truck_Type][j], Residuals[f])),
                    ] = temp_avail_full[z, j, f, :]
                    dfTruckCharged[
                        !,
                        Symbol(string("$(z)_", dfTru[!, :Truck_Type][j], Residuals[f])),
                    ] = temp_charged[z, j, f, :]
                end
                dfTruckAvailEmpty[!, Symbol(string("$(z)_", dfTru[!, :Truck_Type][j]))] =
                    temp_avail_empty[z, j, :]
                dfTruckDischarged[!, Symbol(string("$(z)_", dfTru[!, :Truck_Type][j]))] =
                    temp_discharged[z, j, :]
            end
        end
        CSV.write(
            joinpath(truck_state_path, string("Bioenergy_TruckAvailFull.csv")),
            dfTruckAvailFull,
        )
        CSV.write(
            joinpath(truck_state_path, string("Bioenergy_TruckAvailEmpty.csv")),
            dfTruckAvailEmpty,
        )
        CSV.write(joinpath(truck_state_path, string("Bioenergy_TruckCharged.csv")), dfTruckCharged)
        CSV.write(
            joinpath(truck_state_path, string("Bioenergy_TruckDischarged.csv")),
            dfTruckDischarged,
        )

        ## Hydrogen truck transit
        truck_transit_path = joinpath(path, "Transit")
        if (isdir(truck_transit_path) == false)
            mkdir(truck_transit_path)
        end

        dfTruckTravelFull = DataFrame(Time = 1:T)
        dfTruckArriveFull = DataFrame(Time = 1:T)
        dfTruckDepartFull = DataFrame(Time = 1:T)
        dfTruckTravelEmpty = DataFrame(Time = 1:T)
        dfTruckArriveEmpty = DataFrame(Time = 1:T)
        dfTruckDepartEmpty = DataFrame(Time = 1:T)
        temp_travel_full = round.(value.(MESS[:vBTravelFull]); digits = 2)
        temp_arrive_full = round.(value.(MESS[:vBArriveFull]); digits = 2)
        temp_depart_full = round.(value.(MESS[:vBDepartFull]); digits = 2)
        temp_travel_empty = round.(value.(MESS[:vBTravelEmpty]); digits = 2)
        temp_arrive_empty = round.(value.(MESS[:vBArriveEmpty]); digits = 2)
        temp_depart_empty = round.(value.(MESS[:vBDepartEmpty]); digits = 2)
        for r in 1:R
            for d in [-1, 1]
                for j in TRUCK_TYPES
                    name = dfRoute[!, Symbol(d)][r] * "_" * dfTru[!, :Truck_Type][j]
                    for f in eachindex(Residuals)
                        dfTruckTravelFull[!, Symbol(name, Residuals[f])] =
                            temp_travel_full[r, j, d, f, :]
                        dfTruckArriveFull[!, Symbol(name, Residuals[f])] =
                            temp_arrive_full[r, j, d, f, :]
                        dfTruckDepartFull[!, Symbol(name, Residuals[f])] =
                            temp_depart_full[r, j, d, f, :]
                    end

                    dfTruckTravelEmpty[!, Symbol(name)] = temp_travel_empty[r, j, d, :]
                    dfTruckArriveEmpty[!, Symbol(name)] = temp_arrive_empty[r, j, d, :]
                    dfTruckDepartEmpty[!, Symbol(name)] = temp_depart_empty[r, j, d, :]
                end
            end
        end

        CSV.write(joinpath(truck_transit_path, "Bioenergy_TruckTravelFull.csv"), dfTruckTravelFull)
        CSV.write(joinpath(truck_transit_path, "Bioenergy_TruckArriveFull.csv"), dfTruckArriveFull)
        CSV.write(joinpath(truck_transit_path, "Bioenergy_TruckDepartFull.csv"), dfTruckDepartFull)

        CSV.write(
            joinpath(truck_transit_path, "Bioenergy_TruckTravelEmpty.csv"),
            dfTruckTravelEmpty,
        )
        CSV.write(
            joinpath(truck_transit_path, "Bioenergy_TruckArriveEmpty.csv"),
            dfTruckArriveEmpty,
        )
        CSV.write(
            joinpath(truck_transit_path, "Bioenergy_TruckDepartEmpty.csv"),
            dfTruckDepartEmpty,
        )
    end
end
