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
function write_foodstuff_emissions(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        foodstuff_settings = settings["FoodstuffSettings"]
        path = foodstuff_settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        foodstuff_inputs = inputs["FoodstuffInputs"]
        Foods = foodstuff_inputs["Foods"]

        dfs = []
        ## Emission in each zone in each time step
        df = DataFrame(Term = ["Emission By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(round.(value.(MESS[:eFEmissions]); sigdigits = 6), :auto))

        push!(dfs, df)

        if foodstuff_settings["ModelFuels"] == 1 && foodstuff_settings["ModelTrucks"] == 1
            ## Emission from truck travel in each zone in each time step
            df = DataFrame(
                Term = ["Emission From Truck By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(
                df,
                DataFrame(round.(value.(MESS[:eFEmissionsFoodTruckTravel]); sigdigits = 6), :auto),
            )

            push!(dfs, df)
        end

        ## Emission CO2-eq from methane and NOx in each zone
        df = DataFrame(
            Term = ["Emission CO2-eq By $(Zones[z])" for z in 1:Z],
            Zone = Zones,
            Total = 0,
        )

        df = hcat(df, DataFrame(round.(value.(MESS[:eFEmissionsCO2eq]); sigdigits = 6), :auto))

        push!(dfs, df)

        ## Emission from methane in each zone in each time step
        df = DataFrame(
            Term = ["Emission CO2-eq From Methane By $(Zones[z])" for z in 1:Z],
            Zone = Zones,
            Total = 0,
        )

        df = hcat(
            df,
            DataFrame(round.(value.(MESS[:eFCropEmissionsCO2eqMethane]); sigdigits = 6), :auto),
        )

        push!(dfs, df)

        ## Emission from N2O in each zone in each time step
        df = DataFrame(
            Term = ["Emission CO2-eq From N2O By $(Zones[z])" for z in 1:Z],
            Zone = Zones,
            Total = 0,
        )

        df = hcat(
            df,
            DataFrame(round.(value.(MESS[:eFCropEmissionsCO2eqN2O]); sigdigits = 6), :auto),
        )

        push!(dfs, df)

        ## Gather all emission dataframes into one
        df = reduce(vcat, dfs)

        auxNew_Names = [
            Symbol("Term")
            Symbol("Zone")
            Symbol("Total")
            tsymbols
        ]
        rename!(df, auxNew_Names)

        df[!, :Total] = round.(sum(df[!, c] for c in tsymbols); sigdigits = 6)

        CSV.write(joinpath(path, "emission_by_zone.csv"), permutedims(df, "Term"))
    end
end
