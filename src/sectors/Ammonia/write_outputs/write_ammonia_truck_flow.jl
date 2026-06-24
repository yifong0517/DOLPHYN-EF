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
	write_ammonia_truck_flow(settings::Dict, inputs::Dict, MESS::Model)

Fucntion for reporting ammonia flow via trucsk.
"""
function write_ammonia_truck_flow(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        ammonia_settings = settings["AmmoniaSettings"]
        path = ammonia_settings["SavePath"]

        Z = inputs["Z"]
        T = inputs["T"]

        ammonia_inputs = inputs["AmmoniaInputs"]

        TRUCK_TYPES = ammonia_inputs["TRUCK_TYPES"]
        TRANSPORT_ZONES = ammonia_inputs["TRANSPORT_ZONES"]

        R = ammonia_inputs["R"]

        dfTru = ammonia_inputs["dfTru"]
        dfRoute = ammonia_inputs["dfRoute"]

        ## Ammonia truck flow
        truck_flow_path = joinpath(path, "TruckFlow")
        if (isdir(truck_flow_path) == false)
            mkdir(truck_flow_path)
        end

        temp = round.(value.(MESS[:vATruckFlow]); digits = 2)
        for j in TRUCK_TYPES
            dfTruckFlow = DataFrame(Time = 1:T)
            for z in TRANSPORT_ZONES
                dfTruckFlow[!, Symbol("$z")] = temp[z, j, :]
            end
            ## CSV writing
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

        dfTruckNumber = DataFrame(Time = 1:T)
        temp_full = round.(value.(MESS[:vAFull]); digits = 2)
        temp_empty = round.(value.(MESS[:vAEmpty]); digits = 2)
        for j in TRUCK_TYPES
            dfTruckNumber[!, Symbol("Full_", dfTru[!, :Truck_Type][j])] = temp_full[j, :]
            dfTruckNumber[!, Symbol("Empty_", dfTru[!, :Truck_Type][j])] = temp_empty[j, :]
        end
        ## CSV writing
        CSV.write(joinpath(truck_number_path, "TruckNumber.csv"), dfTruckNumber)

        ## Hydrogen truck state
        truck_state_path = joinpath(path, "TruckState")
        if (isdir(truck_state_path) == false)
            mkdir(truck_state_path)
        end
        dfTruckAvailFull = DataFrame(Time = 1:T)
        dfTruckAvailEmpty = DataFrame(Time = 1:T)
        dfTruckCharged = DataFrame(Time = 1:T)
        dfTruckDischarged = DataFrame(Time = 1:T)
        temp_avail_full = round.(value.(MESS[:vAAvailFull]); digits = 2)
        temp_avail_empty = round.(value.(MESS[:vAAvailEmpty]); digits = 2)
        temp_charged = round.(value.(MESS[:vALoaded]); digits = 2)
        temp_discharged = round.(value.(MESS[:vAUnloaded]); digits = 2)
        for j in TRUCK_TYPES
            for z in TRANSPORT_ZONES
                dfTruckAvailFull[!, Symbol(string("$(z)_", dfTru[!, :Truck_Type][j]))] =
                    temp_avail_full[z, j, :]
                dfTruckAvailEmpty[!, Symbol(string("$(z)_", dfTru[!, :Truck_Type][j]))] =
                    temp_avail_empty[z, j, :]
                dfTruckCharged[!, Symbol(string("$(z)_", dfTru[!, :Truck_Type][j]))] =
                    temp_charged[z, j, :]
                dfTruckDischarged[!, Symbol(string("$(z)_", dfTru[!, :Truck_Type][j]))] =
                    temp_discharged[z, j, :]
            end
        end
        ## CSV writing
        CSV.write(joinpath(truck_state_path, string("TruckAvailFull.csv")), dfTruckAvailFull)
        CSV.write(joinpath(truck_state_path, string("TruckAvailEmpty.csv")), dfTruckAvailEmpty)
        CSV.write(joinpath(truck_state_path, string("TruckCharged.csv")), dfTruckCharged)
        CSV.write(joinpath(truck_state_path, string("TruckDischarged.csv")), dfTruckDischarged)

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
        temp_travel_full = round.(value.(MESS[:vATravelFull]); digits = 2)
        temp_arrive_full = round.(value.(MESS[:vAArriveFull]); digits = 2)
        temp_depart_full = round.(value.(MESS[:vADepartFull]); digits = 2)
        temp_travel_empty = round.(value.(MESS[:vATravelEmpty]); digits = 2)
        temp_arrive_empty = round.(value.(MESS[:vAArriveEmpty]); digits = 2)
        temp_depart_empty = round.(value.(MESS[:vADepartEmpty]); digits = 2)
        for r in 1:R
            for d in [-1, 1]
                for j in TRUCK_TYPES
                    name = dfRoute[!, Symbol(d)][r] * "_" * dfTru[!, :Truck_Type][j]
                    dfTruckTravelFull[!, Symbol(name)] = temp_travel_full[r, j, d, :]
                    dfTruckArriveFull[!, Symbol(name)] = temp_arrive_full[r, j, d, :]
                    dfTruckDepartFull[!, Symbol(name)] = temp_depart_full[r, j, d, :]

                    dfTruckTravelEmpty[!, Symbol(name)] = temp_travel_empty[r, j, d, :]
                    dfTruckArriveEmpty[!, Symbol(name)] = temp_arrive_empty[r, j, d, :]
                    dfTruckDepartEmpty[!, Symbol(name)] = temp_depart_empty[r, j, d, :]
                end
            end
        end

        ## CSV writing
        CSV.write(joinpath(truck_transit_path, "TruckTravelFull.csv"), dfTruckTravelFull)
        CSV.write(joinpath(truck_transit_path, "TruckArriveFull.csv"), dfTruckArriveFull)
        CSV.write(joinpath(truck_transit_path, "TruckDepartFull.csv"), dfTruckDepartFull)

        CSV.write(joinpath(truck_transit_path, "TruckTravelEmpty.csv"), dfTruckTravelEmpty)
        CSV.write(joinpath(truck_transit_path, "TruckArriveEmpty.csv"), dfTruckArriveEmpty)
        CSV.write(joinpath(truck_transit_path, "TruckDepartEmpty.csv"), dfTruckDepartEmpty)
    end
end
