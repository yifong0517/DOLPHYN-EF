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
function write_power_storage_reserve(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        power_settings = settings["PowerSettings"]
        path = power_settings["SavePath"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        tsymbols = [Symbol("$t") for t in 1:T]

        power_inputs = inputs["PowerInputs"]
        dfSto = power_inputs["dfSto"]
        STO_PRSV = power_inputs["STO_PRSV"]
        RESOURCES = power_inputs["StoResources"]

        ## Storage discharge reserve of each resource in each time step
        dfStorage = DataFrame(
            Resource = string.(RESOURCES[STO_PRSV]),
            Zone = string.(dfSto[!, :Zone][STO_PRSV]),
        )
        dfStorage = hcat(
            dfStorage,
            DataFrame(round.(value.(MESS[:vPStoDisPRSV]).data; sigdigits = 4), :auto),
        )
        auxNew_Names = [Symbol("Resource"); Symbol("Zone"); tsymbols]
        rename!(dfStorage, auxNew_Names)

        ## CSV writing
        CSV.write(
            joinpath(path, "reserve_storage_discharge.csv"),
            permutedims(dfStorage, "Resource"),
        )

        ## Storage charge reserve of each resource in each time step
        dfStorage = DataFrame(
            Resource = string.(RESOURCES[STO_PRSV]),
            Zone = string.(dfSto[!, :Zone][STO_PRSV]),
        )
        dfStorage = hcat(
            dfStorage,
            DataFrame(round.(value.(MESS[:vPStoChaPRSV]).data; sigdigits = 4), :auto),
        )
        auxNew_Names = [Symbol("Resource"); Symbol("Zone"); tsymbols]
        rename!(dfStorage, auxNew_Names)

        ## CSV writing
        CSV.write(joinpath(path, "reserve_storage_charge.csv"), permutedims(dfStorage, "Resource"))
    end
end
