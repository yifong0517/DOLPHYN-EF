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
    write_ammonia_truck_capacity(settings::Dict, inputs::Dict, MESS::Model)

Functions for reporting capacities of ammonia trucks (starting capacities or, existing capacities, retired capacities, and new-built capacities).
"""
function write_ammonia_truck_capacity(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        ammonia_settings = settings["AmmoniaSettings"]
        path = ammonia_settings["SavePath"]

        ## Flags
        NetworkExpansion = ammonia_settings["NetworkExpansion"]

        ammonia_inputs = inputs["AmmoniaInputs"]

        TRUCK_TYPES = ammonia_inputs["TRUCK_TYPES"]
        TRANSPORT_ZONES = ammonia_inputs["TRANSPORT_ZONES"]

        dfTru = ammonia_inputs["dfTru"]

        ## Ammonia truck capacity
        capNumber = zeros(size(TRUCK_TYPES))
        endNumber = zeros(size(TRUCK_TYPES))

        for j in TRUCK_TYPES
            capNumber[j] =
                (NetworkExpansion == 1) ? round(value(MESS[:vANewTruNumber][j]); digits = 2) : 0
            endNumber[j] = round(value(MESS[:eATruNumber][j]); digits = 2)
        end

        dfTruckCap = DataFrame(
            TruckType = string.(dfTru[!, :Truck_Type][TRUCK_TYPES]),
            StartTruck = dfTru[!, :Existing_Number],
            NewTruck = capNumber,
            EndTruck = endNumber,
        )

        for z in TRANSPORT_ZONES
            dfTruckCap[!, Symbol("StartTruckCompCapZone$z")] =
                dfTru[!, Symbol("Existing_Comp_Cap_tonne_$z")]
            tempComp = zeros(size(TRUCK_TYPES))
            for j in TRUCK_TYPES
                tempComp[j] = (NetworkExpansion == 1) ? value(MESS[:vANewTruComp][z, j]) : 0
            end
            dfTruckCap[!, Symbol("NewTruckCompCapZone$z")] = tempComp

            tempComp = zeros(size(TRUCK_TYPES))
            for j in TRUCK_TYPES
                tempComp[j] = value(MESS[:eATruComp][z, j])
            end
            dfTruckCap[!, Symbol("EndTruckCompCapZone$z")] = tempComp
        end

        dfTruckCap[!, :StartTruckCompCap] =
            round.(
                sum(dfTruckCap[!, Symbol("StartTruckCompCapZone$z")] for z in TRANSPORT_ZONES);
                digits = 2,
            )
        dfTruckCap[!, :NewTruckCompCap] =
            round.(
                sum(dfTruckCap[!, Symbol("NewTruckCompCapZone$z")] for z in TRANSPORT_ZONES);
                digits = 2,
            )
        dfTruckCap[!, :EndTruckCompCap] =
            round.(
                sum(dfTruckCap[!, Symbol("EndTruckCompCapZone$z")] for z in TRANSPORT_ZONES);
                digits = 2,
            )

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(dfTruckCap, settings["DB"], "ATrucks")
        end

        dfTruckTotal = DataFrame(
            TruckType = "Sum",
            StartTruck = round(sum(dfTruckCap[!, :StartTruck]); digits = 2),
            NewTruck = round(sum(dfTruckCap[!, :NewTruck]); digits = 2),
            EndTruck = round(sum(dfTruckCap[!, :EndTruck]); digits = 2),
            StartTruckCompCap = round(sum(dfTruckCap[!, :StartTruckCompCap]); digits = 2),
            NewTruckCompCap = round(sum(dfTruckCap[!, :NewTruckCompCap]); digits = 2),
            EndTruckCompCap = round(sum(dfTruckCap[!, :EndTruckCompCap]); digits = 2),
        )

        for z in TRANSPORT_ZONES
            dfTruckTotal[!, Symbol("StartTruckCompCapZone$z")] =
                round.([sum(dfTruckCap[!, Symbol("StartTruckCompCapZone$z")])]; digits = 2)
            dfTruckTotal[!, Symbol("NewTruckCompCapZone$z")] =
                round.([sum(dfTruckCap[!, Symbol("NewTruckCompCapZone$z")])]; digits = 2)
            dfTruckTotal[!, Symbol("EndTruckCompCapZone$z")] =
                round.([sum(dfTruckCap[!, Symbol("EndTruckCompCapZone$z")])]; digits = 2)
        end

        ## Merge total dataframe for csv results
        dfTruckCap = vcat(dfTruckCap, dfTruckTotal)

        ## CSV writing
        CSV.write(joinpath(path, "capacities_truck.csv"), dfTruckCap)
    end
end
