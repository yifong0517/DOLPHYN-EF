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
function write_hydrogen_carbon_consumption(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        hydrogen_settings = settings["HydrogenSettings"]
        path = hydrogen_settings["SavePath"]

        ## Basic model spatial and temporal information
        ### Spatial information
        Z = inputs["Z"]
        Zones = inputs["Zones"]

        ### Temporal information
        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        ## Carbon index
        Carbon_Index = inputs["Carbon_Index"]

        ## Initialize carbon consumption dataframe
        dfCarbons = []

        ## Obtain carbon consumption type by type
        temp = round.(value.(MESS[:eHCarbonConsumption]); sigdigits = 4)
        for f in eachindex(Carbon_Index)
            dfCarbon = DataFrame(
                CarbonZone = Zones,
                Carbon = Carbon_Index[f],
                Zone = Zones,
                Total = zeros(Z),
            )
            dfCarbon = hcat(dfCarbon, DataFrame(temp[f, :, :], :auto))
            names =
                [Symbol("CarbonZone"); Symbol("Carbon"); Symbol("Zone"); Symbol("Total"); tsymbols]
            rename!(dfCarbon, names)
            dfCarbon[!, :Total] =
                round.([sum(weights .* Vector(dfCarbon[z, tsymbols])) for z in 1:Z]; sigdigits = 4)
            push!(dfCarbons, dfCarbon)
        end

        ## Gather all carbon consumption dataframes into one
        dfCarbons = reduce(vcat, dfCarbons)

        ## Change carbon zones index with zone+carbon type
        dfCarbons[!, :CarbonZone] = ["$(f)_$(z)" for f in Carbon_Index for z in Zones]

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(
                stack(
                    dfCarbons[!, [Symbol("Carbon"); Symbol("Zone"); tsymbols]],
                    tsymbols,
                    variable_name = :TimeStamp,
                    value_name = :Consumption,
                ),
                settings["DB"],
                "HCarbonConsumption",
            )
        end

        ## CSV writing
        CSV.write(
            joinpath(path, "hydrogen_carbon_consumption.csv"),
            permutedims(dfCarbons, "CarbonZone"),
        )
    end
end
