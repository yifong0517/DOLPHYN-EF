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
function write_power_storage(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        power_settings = settings["PowerSettings"]
        path = power_settings["SavePath"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        tsymbols = [Symbol("$t") for t in 1:T]

        power_inputs = inputs["PowerInputs"]

        S = power_inputs["S"]
        dfSto = power_inputs["dfSto"]

        RESOURCES = power_inputs["StoResources"]

        ## Storage level (state of charge) of each resource in each time step
        dfStorage = DataFrame(
            Resource = string.(RESOURCES),
            ResourceType = string.(dfSto[!, :Resource_Type]),
            Zone = string.(dfSto[!, :Zone]),
        )
        dfStorage =
            hcat(dfStorage, DataFrame(round.(value.(MESS[:vPStoEneLevel]); sigdigits = 4), :auto))
        auxNew_Names = [Symbol("Resource"); Symbol("ResourceType"); Symbol("Zone"); tsymbols]
        rename!(dfStorage, auxNew_Names)

        dfStorageDB = stack(dfStorage, tsymbols, variable_name = :TimeIndex, value_name = :SOC)

        ## CSV writing
        CSV.write(joinpath(path, "storage_energy.csv"), permutedims(dfStorage, "Resource"))

        ## Storage discharge of each resource in each time step
        dfStorage = DataFrame(
            Resource = string.(RESOURCES),
            ResourceType = string.(dfSto[!, :Resource_Type]),
            Zone = string.(dfSto[!, :Zone]),
        )
        dfStorage =
            hcat(dfStorage, DataFrame(round.(value.(MESS[:vPStoDis]); sigdigits = 4), :auto))
        auxNew_Names = [Symbol("Resource"); Symbol("ResourceType"); Symbol("Zone"); tsymbols]
        rename!(dfStorage, auxNew_Names)

        dfStorageDB[!, :Discharge] =
            stack(dfStorage, tsymbols, variable_name = :TimeIndex, value_name = :Discharge)[
                !,
                :Discharge,
            ]

        ## CSV writing
        CSV.write(joinpath(path, "storage_discharge.csv"), permutedims(dfStorage, "Resource"))

        ## Storage discharge of each resource in each time step
        dfStorage = DataFrame(
            Resource = string.(RESOURCES),
            ResourceType = string.(dfSto[!, :Resource_Type]),
            Zone = string.(dfSto[!, :Zone]),
        )
        dfStorage =
            hcat(dfStorage, DataFrame(round.(value.(MESS[:vPStoCha]); sigdigits = 4), :auto))
        auxNew_Names = [Symbol("Resource"); Symbol("ResourceType"); Symbol("Zone"); tsymbols]
        rename!(dfStorage, auxNew_Names)

        dfStorageDB[!, :Charge] =
            stack(dfStorage, tsymbols, variable_name = :TimeIndex, value_name = :Charge)[!, :Charge]

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(dfStorageDB, settings["DB"], "PStorageDispatch")
        end

        ## CSV writing
        CSV.write(joinpath(path, "storage_charge.csv"), permutedims(dfStorage, "Resource"))
    end
end
