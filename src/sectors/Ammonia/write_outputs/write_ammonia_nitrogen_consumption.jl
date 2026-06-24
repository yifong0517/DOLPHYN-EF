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
function write_ammonia_nitrogen_consumption(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        ammonia_settings = settings["AmmoniaSettings"]
        path = ammonia_settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        weights = inputs["weights"]
        Time_Index = inputs["Time_Index"]
        tsymbols = [Symbol("$t") for t in 1:T]

        ammonia_inputs = inputs["AmmoniaInputs"]

        ## Initialize nitrogen dataframe
        dfNitrogen = DataFrame(Zone = Zones, Total = zeros(Z))

        ## Merge Nitrogen into Nitrogen dataframe
        dfNitrogen =
            hcat(dfNitrogen, DataFrame(round.(value.(MESS[:eEmissions]); sigdigits = 6), :auto))

        ## Rename Nitrogen dataframe
        names = [Symbol("Zone"); Symbol("Total"); tsymbols]
        rename!(dfNitrogen, names)

        ## Get total sum value via summation over all time indexes
        dfNitrogen[!, :Total] =
            round.([sum(weights .* Vector(dfNitrogen[z, tsymbols])) for z in 1:Z]; sigdigits = 6)

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(
                stack(
                    dfNitrogen[!, [Symbol("Zone"); tsymbols]],
                    tsymbols,
                    variable_name = :TimeStamp,
                    value_name = :Emission,
                ),
                settings["DB"],
                "Nitrogen",
            )
        end

        ## CSV writing
        CSV.write(joinpath(path, "nitrogen_consumption.csv"), permutedims(dfNitrogen, "Zone"))
    end
end
