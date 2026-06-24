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
    write_foodstuff_truck_capacity(settings::Dict, inputs::Dict, MESS::Model)

Functions for reporting capacities of foodstuff trucks (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_foodstuff_truck_capacity(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        foodstuff_settings = settings["FoodstuffSettings"]
        path = foodstuff_settings["SavePath"]

        ## Flags
        TruckExpansion = foodstuff_settings["TruckExpansion"]
        foodstuff_inputs = inputs["FoodstuffInputs"]

        TRUCK_TYPES = foodstuff_inputs["TRUCK_TYPES"]
        TRUCK_ZONES = foodstuff_inputs["TRUCK_ZONES"]

        dfTru = foodstuff_inputs["dfTru"]

        ## Foodstuff truck capacity
        capNumber = zeros(size(TRUCK_TYPES))
        endNumber = zeros(size(TRUCK_TYPES))

        for j in TRUCK_TYPES
            capNumber[j] =
                (TruckExpansion == 1) ? round(value(MESS[:vFNewTruNumber][j]); digits = 2) : 0
            endNumber[j] = round(value(MESS[:eFTruNumber][j]); digits = 2)
        end

        dfTruckCap = DataFrame(
            TruckType = string.(dfTru[!, :Truck_Type][TRUCK_TYPES]),
            StartTruck = dfTru[!, :Existing_Number],
            NewTruck = capNumber,
            EndTruck = endNumber,
        )

        dfTruckTotal = DataFrame(
            TruckType = "Sum",
            StartTruck = round(sum(dfTruckCap[!, :StartTruck]); digits = 2),
            NewTruck = round(sum(dfTruckCap[!, :NewTruck]); digits = 2),
            EndTruck = round(sum(dfTruckCap[!, :EndTruck]); digits = 2),
        )

        dfTruckCap = vcat(dfTruckCap, dfTruckTotal)
        CSV.write(joinpath(path, "foodstuff_capacities_truck.csv"), dfTruckCap)
    end
end
