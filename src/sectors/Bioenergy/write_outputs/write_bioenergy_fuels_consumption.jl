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
function write_bioenergy_fuels_consumption(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        bioenergy_settings = settings["BioenergySettings"]
        path = bioenergy_settings["SavePath"]

        ## Basic model spatial and temporal information
        ### Spatial information
        Z = inputs["Z"]
        Zones = inputs["Zones"]

        ### Temporal information
        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        ## Fuels index
        Fuels_Index = inputs["Fuels_Index"]

        ## Initialize fuels consumption dataframe
        dfFuels = []

        ## Obtain fuels consumption type by type
        temp = round.(value.(MESS[:eBFuelsConsumption]); sigdigits = 4)
        for f in eachindex(Fuels_Index)
            dfFuel =
                DataFrame(FuelZone = Zones, Fuel = Fuels_Index[f], Zone = Zones, Total = zeros(Z))
            dfFuel = hcat(dfFuel, DataFrame(temp[f, :, :], :auto))
            names = [Symbol("FuelZone"); Symbol("Fuel"); Symbol("Zone"); Symbol("Total"); tsymbols]
            rename!(dfFuel, names)
            dfFuel[!, :Total] =
                round.([sum(weights .* Vector(dfFuel[z, tsymbols])) for z in 1:Z]; sigdigits = 4)
            push!(dfFuels, dfFuel)
        end

        ## Gather all fuel consumption dataframes into one
        dfFuels = reduce(vcat, dfFuels)

        ## Change fuel zones index with zone+fuel type
        dfFuels[!, :FuelZone] = ["$(f)_$(z)" for f in Fuels_Index for z in Zones]

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(
                stack(
                    dfFuels[!, [Symbol("Fuel"); Symbol("Zone"); tsymbols]],
                    tsymbols,
                    variable_name = :TimeStamp,
                    value_name = :Consumption,
                ),
                settings["DB"],
                "BFuelsConsumption",
            )
        end

        ## CSV writing
        CSV.write(
            joinpath(path, "bioenergy_fuels_consumption.csv"),
            permutedims(dfFuels, "FuelZone"),
        )
    end
end
