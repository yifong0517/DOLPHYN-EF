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
    write_hydrogen_truck_capacity(settings::Dict, inputs::Dict, MESS::Model)

Functions for reporting capacities of hydrogen trucks (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_hydrogen_truck_capacity(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        hydrogen_settings = settings["HydrogenSettings"]
        path = hydrogen_settings["SavePath"]

        ## Flags
        NetworkExpansion = hydrogen_settings["NetworkExpansion"]

        hydrogen_inputs = inputs["HydrogenInputs"]

        TRUCK_TYPES = hydrogen_inputs["TRUCK_TYPES"]
        TRANSPORT_ZONES = hydrogen_inputs["TRANSPORT_ZONES"]

        dfTru = hydrogen_inputs["dfTru"]

        ## Hydrogen truck capacity
        capNumber = zeros(size(TRUCK_TYPES))
        endNumber = zeros(size(TRUCK_TYPES))

        for j in TRUCK_TYPES
            capNumber[j] =
                !(NetworkExpansion == 1) ? round(value(MESS[:vHNewTruNumber][j]); sigdigits = 4) :
                0.0
            endNumber[j] = round(value(MESS[:eHTruNumber][j]); sigdigits = 4)
        end

        dfTruckCap = DataFrame(
            TruckType = string.(dfTru[!, :Truck_Type]),
            StartTruck = dfTru[!, :Existing_Number],
            NewTruck = capNumber,
            EndTruck = endNumber,
        )

        for z in TRANSPORT_ZONES
            dfTruckCap[!, Symbol("StartTruckCompCapZone$z")] =
                dfTru[!, Symbol("Existing_Comp_Cap_tonne_$z")]
            tempComp = zeros(size(TRUCK_TYPES))
            for j in TRUCK_TYPES
                tempComp[j] =
                    !(NetworkExpansion == 1) ?
                    round(value(MESS[:vHNewTruComp][z, j]); sigdigits = 4) : 0.0
            end
            dfTruckCap[!, Symbol("NewTruckCompCapZone$z")] = tempComp

            tempComp = zeros(size(TRUCK_TYPES))
            for j in TRUCK_TYPES
                tempComp[j] = round(value(MESS[:eHTruComp][z, j]); sigdigits = 4)
            end
            dfTruckCap[!, Symbol("EndTruckCompCapZone$z")] = tempComp
        end

        dfTruckCap[!, :StartTruckCompCap] =
            sum(dfTruckCap[!, Symbol("StartTruckCompCapZone$z")] for z in TRANSPORT_ZONES)
        dfTruckCap[!, :NewTruckCompCap] =
            sum(dfTruckCap[!, Symbol("NewTruckCompCapZone$z")] for z in TRANSPORT_ZONES)
        dfTruckCap[!, :EndTruckCompCap] =
            sum(dfTruckCap[!, Symbol("EndTruckCompCapZone$z")] for z in TRANSPORT_ZONES)

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(dfTruckCap, settings["DB"], "HTrucks")
        end

        dfTruckTotal = DataFrame(
            TruckType = "Sum",
            StartTruck = round(sum(dfTruckCap[!, :StartTruck]); sigdigits = 4),
            NewTruck = round(sum(dfTruckCap[!, :NewTruck]); sigdigits = 4),
            EndTruck = round(sum(dfTruckCap[!, :EndTruck]); sigdigits = 4),
            StartTruckCompCap = round(sum(dfTruckCap[!, :StartTruckCompCap]); sigdigits = 4),
            NewTruckCompCap = round(sum(dfTruckCap[!, :NewTruckCompCap]); sigdigits = 4),
            EndTruckCompCap = round(sum(dfTruckCap[!, :EndTruckCompCap]); sigdigits = 4),
        )

        for z in TRANSPORT_ZONES
            dfTruckTotal[!, Symbol("StartTruckCompCapZone$z")] =
                round.([sum(dfTruckCap[!, Symbol("StartTruckCompCapZone$z")])]; sigdigits = 4)
            dfTruckTotal[!, Symbol("NewTruckCompCapZone$z")] =
                round.([sum(dfTruckCap[!, Symbol("NewTruckCompCapZone$z")])]; sigdigits = 4)
            dfTruckTotal[!, Symbol("EndTruckCompCapZone$z")] =
                round.([sum(dfTruckCap[!, Symbol("EndTruckCompCapZone$z")])]; sigdigits = 4)
        end

        ## Merge total dataframe for csv results
        dfTruckCap = vcat(dfTruckCap, dfTruckTotal)

        ## CSV writing
        CSV.write(joinpath(path, "capacities_truck.csv"), dfTruckCap)
    end
end
