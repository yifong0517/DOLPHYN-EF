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
    write_bioenergy_truck_capacity(settings::Dict, inputs::Dict, MESS::Model)

Functions for reporting capacities of bioenergy trucks (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_bioenergy_truck_capacity(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        bioenergy_settings = settings["BioenergySettings"]
        path = bioenergy_settings["SavePath"]

        ## Flags
        NetworkExpansion = bioenergy_settings["NetworkExpansion"]

        bioenergy_inputs = inputs["BioenergyInputs"]

        TRUCK_TYPES = bioenergy_inputs["TRUCK_TYPES"]
        TRUCK_ZONES = bioenergy_inputs["TRUCK_ZONES"]

        dfTru = bioenergy_inputs["dfTru"]

        ## Bioenergy truck capacity
        capNumber = zeros(size(TRUCK_TYPES))
        endNumber = zeros(size(TRUCK_TYPES))

        for j in TRUCK_TYPES
            capNumber[j] =
                (NetworkExpansion == 1) ? round(value(MESS[:vBNewTruNumber][j]); digits = 2) : 0
            endNumber[j] = round(value(MESS[:eBTruNumber][j]); digits = 2)
        end

        dfTruckCap = DataFrame(
            TruckType = string.(dfTru[!, :Truck_Type][TRUCK_TYPES]),
            StartTruck = dfTru[!, :Existing_Number],
            NewTruck = capNumber,
            EndTruck = endNumber,
        )

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(dfTruckCap, settings["DB"], "BTrucks")
        end

        dfTruckTotal = DataFrame(
            TruckType = "Sum",
            StartTruck = round(sum(dfTruckCap[!, :StartTruck]); digits = 2),
            NewTruck = round(sum(dfTruckCap[!, :NewTruck]); digits = 2),
            EndTruck = round(sum(dfTruckCap[!, :EndTruck]); digits = 2),
        )

        ## Merge total dataframe for csv results
        dfTruckCap = vcat(dfTruckCap, dfTruckTotal)

        ## CSV writing
        CSV.write(joinpath(path, "capacities_truck.csv"), dfTruckCap)
    end
end
