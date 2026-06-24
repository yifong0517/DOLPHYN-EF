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
function write_hydrogen_electricity_consumption(settings::Dict, inputs::Dict, MESS::Model)

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

        ## Electricity index
        Electricity_Index = inputs["Electricity_Index"]

        ## Initialize electricity consumption dataframe
        dfElectricitys = []

        ## Obtain electricity consumption type by type
        temp = round.(value.(MESS[:eHElectricityConsumption]); sigdigits = 4)
        for f in eachindex(Electricity_Index)
            dfElectricity = DataFrame(
                ElectricityZone = Zones,
                Electricity = Electricity_Index[f],
                Zone = Zones,
                Total = zeros(Z),
            )
            dfElectricity = hcat(dfElectricity, DataFrame(temp[f, :, :], :auto))
            names = [
                Symbol("ElectricityZone")
                Symbol("Electricity")
                Symbol("Zone")
                Symbol("Total")
                tsymbols
            ]
            rename!(dfElectricity, names)
            dfElectricity[!, :Total] =
                round.(
                    [sum(weights .* Vector(dfElectricity[z, tsymbols])) for z in 1:Z];
                    sigdigits = 4,
                )
            push!(dfElectricitys, dfElectricity)
        end

        ## Gather all electricity consumption dataframes into one
        dfElectricitys = reduce(vcat, dfElectricitys)

        ## Change electricity zones index with zone+electricity type
        dfElectricitys[!, :ElectricityZone] =
            ["$(f)_$(z)" for f in Electricity_Index for z in Zones]

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(
                stack(
                    dfElectricitys[!, [Symbol("Electricity"); Symbol("Zone"); tsymbols]],
                    tsymbols,
                    variable_name = :TimeStamp,
                    value_name = :Consumption,
                ),
                settings["DB"],
                "HElectricityConsumption",
            )
        end

        ## CSV writing
        CSV.write(
            joinpath(path, "hydrogen_electricity_consumption.csv"),
            permutedims(dfElectricitys, "ElectricityZone"),
        )
    end
end
