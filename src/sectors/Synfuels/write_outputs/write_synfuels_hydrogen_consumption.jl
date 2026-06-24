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
function write_synfuels_hydrogen_consumption(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        synfuels_settings = settings["SynfuelsSettings"]
        path = synfuels_settings["SavePath"]

        ## Basic model spatial and temporal information
        ### Spatial information
        Z = inputs["Z"]
        Zones = inputs["Zones"]

        ### Temporal information
        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        ## Hydrogen index
        Hydrogen_Index = inputs["Hydrogen_Index"]

        ## Initialize hydrogen consumption dataframe
        dfHydrogens = []

        ## Obtain hydrogen consumption type by type
        temp = round.(value.(MESS[:eSHydrogenConsumption]); sigdigits = 4)
        for f in eachindex(Hydrogen_Index)
            dfHydrogen = DataFrame(
                HydrogenZone = Zones,
                Hydrogen = Hydrogen_Index[f],
                Zone = Zones,
                Total = zeros(Z),
            )
            dfHydrogen = hcat(dfHydrogen, DataFrame(temp[f, :, :], :auto))
            names = [
                Symbol("HydrogenZone")
                Symbol("Hydrogen")
                Symbol("Zone")
                Symbol("Total")
                tsymbols
            ]
            rename!(dfHydrogen, names)
            dfHydrogen[!, :Total] =
                round.(
                    [sum(weights .* Vector(dfHydrogen[z, tsymbols])) for z in 1:Z];
                    sigdigits = 4,
                )
            push!(dfHydrogens, dfHydrogen)
        end

        ## Gather all hydrogen consumption dataframes into one
        dfHydrogens = reduce(vcat, dfHydrogens)

        ## Change hydrogen zones index with zone+hydrogen type
        dfHydrogens[!, :HydrogenZone] = ["$(f)_$(z)" for f in Hydrogen_Index for z in Zones]

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(
                stack(
                    dfHydrogens[!, [Symbol("Hydrogen"); Symbol("Zone"); tsymbols]],
                    tsymbols,
                    variable_name = :TimeStamp,
                    value_name = :Consumption,
                ),
                settings["DB"],
                "SHydrogenConsumption",
            )
        end

        ## CSV writing
        CSV.write(
            joinpath(path, "synfuels_hydrogen_consumption.csv"),
            permutedims(dfHydrogens, "HydrogenZone"),
        )
    end
end
