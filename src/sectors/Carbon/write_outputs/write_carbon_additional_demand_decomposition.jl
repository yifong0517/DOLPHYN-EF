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
function write_carbon_additional_demand_decomposition(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 4
        carbon_settings = settings["CarbonSettings"]
        path = carbon_settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        carbon_inputs = inputs["CarbonInputs"]

        dfs = []

        ## Additional demand
        df = DataFrame(
            Term = ["Additional Carbon Demand By $(Zones[z])" for z in 1:Z],
            Zone = Zones,
            Sector = "Total",
            Total = 0,
        )

        df = hcat(df, DataFrame(round.(value.(MESS[:eCDemandAddition]); sigdigits = 4), :auto))

        push!(dfs, df)

        if settings["ModelSynfuels"] == 1
            ## Additional demand from synfuels generation
            df = DataFrame(
                Term = [
                    "Additional Carbon Demand From Synfuels Generation By $(Zones[z])" for z in 1:Z
                ],
                Zone = Zones,
                Sector = "Synfuels Generation",
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eCBalanceSGen]); sigdigits = 4), :auto))

            push!(dfs, df)
        end

        if settings["ModelFoodstuff"] == 1
            ## Additional demand from foodstuff urea usage
            df = DataFrame(
                Term = [
                    "Additional Carbon Demand From Foodstuff Fertizer By $(Zones[z])" for z in 1:Z
                ],
                Zone = Zones,
                Sector = "Foodstuff Fertizer",
                Total = 0,
            )

            df = hcat(
                df,
                DataFrame(round.(value.(MESS[:eCBalanceCropGrowing]); sigdigits = 4), :auto),
            )

            push!(dfs, df)
        end

        ## Gather all balance dataframes into one
        df = reduce(vcat, dfs)

        auxNew_Names = [
            Symbol("Term")
            Symbol("Zones")
            Symbol("Sector")
            Symbol("Total")
            tsymbols
        ]
        rename!(df, auxNew_Names)

        df[!, :Total] = round.(sum(df[!, c] for c in tsymbols); sigdigits = 4)

        ## CSV writing
        CSV.write(joinpath(path, "additional_demand_decomposition.csv"), permutedims(df, "Term"))
    end
end
