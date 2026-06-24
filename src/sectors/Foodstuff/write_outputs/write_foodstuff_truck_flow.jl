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
	write_foodstuff_truck_flow(settings::Dict, inputs::Dict, MESS::Model)

Fucntion for reporting foodstuff flow via trucsk.
"""
function write_foodstuff_truck_flow(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        foodstuff_settings = settings["FoodstuffSettings"]
        path = foodstuff_settings["SavePath"]

        Z = inputs["Z"]
        T = inputs["T"]

        foodstuff_inputs = inputs["FoodstuffInputs"]

        TRUCK_TYPES = foodstuff_inputs["TRUCK_TYPES"]
        TRUCK_ZONES = foodstuff_inputs["TRUCK_ZONES"]
        Foods = foodstuff_inputs["Foods"]

        R = foodstuff_inputs["R"]

        dfTru = foodstuff_inputs["dfTru"]
        dfRoute = foodstuff_inputs["dfRoute"]

        ## Foodstuff truck flow
        truck_flow_path = joinpath(path, "TruckFlow")
        if (isdir(truck_flow_path) == false)
            mkdir(truck_flow_path)
        end

        temp = value.(MESS[:vFTruckFlow])
        for j in TRUCK_TYPES
            dfTruckFlow = DataFrame(Time = 1:T)
            for z in TRUCK_ZONES
                for fs in eachindex(Foods)
                    dfTruckFlow[!, Symbol("$(z)_$(fs)")] = temp[z, j, fs, :]
                end
            end
            CSV.write(
                joinpath(truck_flow_path, string("TruckFlow_", dfTru[!, :Truck_Type][j], ".csv")),
                dfTruckFlow,
            )
        end

        ## Hydrogen truck Number
        truck_number_path = joinpath(path, "TruckNumber")
        if (isdir(truck_number_path) == false)
            mkdir(truck_number_path)
        end

        dfTruckNumberFull = DataFrame(Time = 1:T)
        dfTruckNumberEmpty = DataFrame(Time = 1:T)
        temp_full = round.(value.(MESS[:vFFull]); digits = 2)
        temp_empty = round.(value.(MESS[:vFEmpty]); digits = 2)
        for j in TRUCK_TYPES
            for fs in eachindex(Foods)
                dfTruckNumberFull[!, Symbol(string(dfTru[!, :Truck_Type][j]), Foods[fs])] =
                    temp_full[j, fs, :]
            end
            dfTruckNumberEmpty[!, Symbol(dfTru[!, :Truck_Type][j])] = temp_empty[j, :]
        end
        CSV.write(joinpath(truck_number_path, "Foodstuff_TruckNumberFull.csv"), dfTruckNumberFull)
        CSV.write(joinpath(truck_number_path, "Foodstuff_TruckNumberEmpty.csv"), dfTruckNumberEmpty)

        ## Hydrogen truck state
        truck_state_path = joinpath(path, "TruckState")
        if (isdir(truck_state_path) == false)
            mkdir(truck_state_path)
        end
        dfTruckAvailFull = DataFrame(Time = 1:T)
        dfTruckAvailEmpty = DataFrame(Time = 1:T)
        dfTruckCharged = DataFrame(Time = 1:T)
        dfTruckDischarged = DataFrame(Time = 1:T)
        temp_avail_full = round.(value.(MESS[:vFAvailFull]); digits = 2)
        temp_avail_empty = round.(value.(MESS[:vFAvailEmpty]); digits = 2)
        temp_charged = round.(value.(MESS[:vFLoaded]); digits = 2)
        temp_discharged = round.(value.(MESS[:vFUnloaded]); digits = 2)
        for j in TRUCK_TYPES
            for z in TRUCK_ZONES
                for fs in eachindex(Foods)
                    dfTruckAvailFull[
                        !,
                        Symbol(string("$(z)_", dfTru[!, :Truck_Type][j], Foods[fs])),
                    ] = temp_avail_full[z, j, fs, :]
                    dfTruckCharged[
                        !,
                        Symbol(string("$(z)_", dfTru[!, :Truck_Type][j], Foods[fs])),
                    ] = temp_charged[z, j, fs, :]
                end
                dfTruckAvailEmpty[!, Symbol(string("$(z)_", dfTru[!, :Truck_Type][j]))] =
                    temp_avail_empty[z, j, :]
                dfTruckDischarged[!, Symbol(string("$(z)_", dfTru[!, :Truck_Type][j]))] =
                    temp_discharged[z, j, :]
            end
        end
        CSV.write(
            joinpath(truck_state_path, string("Foodstuff_TruckAvailFull.csv")),
            dfTruckAvailFull,
        )
        CSV.write(
            joinpath(truck_state_path, string("Foodstuff_TruckAvailEmpty.csv")),
            dfTruckAvailEmpty,
        )
        CSV.write(joinpath(truck_state_path, string("Foodstuff_TruckCharged.csv")), dfTruckCharged)
        CSV.write(
            joinpath(truck_state_path, string("Foodstuff_TruckDischarged.csv")),
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
        temp_travel_full = round.(value.(MESS[:vFTravelFull]); digits = 2)
        temp_arrive_full = round.(value.(MESS[:vFArriveFull]); digits = 2)
        temp_depart_full = round.(value.(MESS[:vFDepartFull]); digits = 2)
        temp_travel_empty = round.(value.(MESS[:vFTravelEmpty]); digits = 2)
        temp_arrive_empty = round.(value.(MESS[:vFArriveEmpty]); digits = 2)
        temp_depart_empty = round.(value.(MESS[:vFDepartEmpty]); digits = 2)
        for r in 1:R
            for d in [-1, 1]
                for j in TRUCK_TYPES
                    name = dfRoute[!, Symbol(d)][r] * "_" * dfTru[!, :Truck_Type][j]
                    for fs in eachindex(Foods)
                        dfTruckTravelFull[!, Symbol(name, Foods[fs])] =
                            temp_travel_full[r, j, d, fs, :]
                        dfTruckArriveFull[!, Symbol(name, Foods[fs])] =
                            temp_arrive_full[r, j, d, fs, :]
                        dfTruckDepartFull[!, Symbol(name, Foods[fs])] =
                            temp_depart_full[r, j, d, fs, :]
                    end

                    dfTruckTravelEmpty[!, Symbol(name)] = temp_travel_empty[r, j, d, :]
                    dfTruckArriveEmpty[!, Symbol(name)] = temp_arrive_empty[r, j, d, :]
                    dfTruckDepartEmpty[!, Symbol(name)] = temp_depart_empty[r, j, d, :]
                end
            end
        end

        CSV.write(joinpath(truck_transit_path, "Foodstuff_TruckTravelFull.csv"), dfTruckTravelFull)
        CSV.write(joinpath(truck_transit_path, "Foodstuff_TruckArriveFull.csv"), dfTruckArriveFull)
        CSV.write(joinpath(truck_transit_path, "Foodstuff_TruckDepartFull.csv"), dfTruckDepartFull)

        CSV.write(
            joinpath(truck_transit_path, "Foodstuff_TruckTravelEmpty.csv"),
            dfTruckTravelEmpty,
        )
        CSV.write(
            joinpath(truck_transit_path, "Foodstuff_TruckArriveEmpty.csv"),
            dfTruckArriveEmpty,
        )
        CSV.write(
            joinpath(truck_transit_path, "Foodstuff_TruckDepartEmpty.csv"),
            dfTruckDepartEmpty,
        )
    end
end
