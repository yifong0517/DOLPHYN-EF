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
function write_carbon_bioenergy_consumption(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        carbon_settings = settings["CarbonSettings"]
        path = carbon_settings["SavePath"]

        ## Basic model spatial and temporal information
        ### Spatial information
        Z = inputs["Z"]
        Zones = inputs["Zones"]

        ### Temporal information
        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        ## Bioenergy index
        Bioenergy_Index = inputs["Bioenergy_Index"]

        ## Initialize bioenergy consumption dataframe
        dfBioenergys = []

        ## Obtain bioenergy consumption type by type
        temp = round.(value.(MESS[:eCBioenergyConsumption]); sigdigits = 4)
        for f in eachindex(Bioenergy_Index)
            dfBioenergy = DataFrame(
                BioenergyZone = Zones,
                Bioenergy = Bioenergy_Index[f],
                Zone = Zones,
                Total = zeros(Z),
            )
            dfBioenergy = hcat(dfBioenergy, DataFrame(temp[f, :, :], :auto))
            names = [
                Symbol("BioenergyZone")
                Symbol("Bioenergy")
                Symbol("Zone")
                Symbol("Total")
                tsymbols
            ]
            rename!(dfBioenergy, names)
            dfBioenergy[!, :Total] =
                round.(
                    [sum(weights .* Vector(dfBioenergy[z, tsymbols])) for z in 1:Z];
                    sigdigits = 4,
                )
            push!(dfBioenergys, dfBioenergy)
        end

        ## Gather all bioenergy consumption dataframes into one
        dfBioenergys = reduce(vcat, dfBioenergys)

        ## Change bioenergy zones index with zone+bioenergy type
        dfBioenergys[!, :BioenergyZone] = ["$(f)_$(z)" for f in Bioenergy_Index for z in Zones]

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(
                stack(
                    dfBioenergys[!, [Symbol("Bioenergy"); Symbol("Zone"); tsymbols]],
                    tsymbols,
                    variable_name = :TimeStamp,
                    value_name = :Consumption,
                ),
                settings["DB"],
                "CBioenergyConsumption",
            )
        end

        ## CSV writing
        CSV.write(
            joinpath(path, "carbon_bioenergy_consumption.csv"),
            permutedims(dfBioenergys, "BioenergyZone"),
        )
    end
end
