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
function write_hydrogen_additional_demand_decomposition(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 4
        hydrogen_settings = settings["HydrogenSettings"]
        path = hydrogen_settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        hydrogen_inputs = inputs["HydrogenInputs"]

        dfs = []

        ## Additional demand
        df = DataFrame(
            Term = ["Additional Hydrogen Demand By $(Zones[z])" for z in 1:Z],
            Zone = Zones,
            Sector = "Total",
            Total = 0,
        )

        df = hcat(df, DataFrame(round.(value.(MESS[:eHDemandAddition]); sigdigits = 4), :auto))

        push!(dfs, df)

        if settings["ModelPower"] == 1
            power_inputs = inputs["PowerInputs"]
            HFG = power_inputs["HFG"]
            if !isempty(HFG)
                ## Additional demand From Gas Turbines
                df = DataFrame(
                    Term = [
                        "Additional Hydrogen Demand From Gas Turbines By $(Zones[z])" for z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Power Gas Turbines",
                    Total = 0,
                )

                df = hcat(df, DataFrame(round.(value.(MESS[:eHBalanceHFG]); sigdigits = 4), :auto))

                push!(dfs, df)
            end
        end

        if settings["ModelCarbon"] == 1
            carbon_settings = settings["CarbonSettings"]
            if carbon_settings["ModelTrucks"] == 1
                ## Additional demand from carbon truck travel
                df = DataFrame(
                    Term = [
                        "Additional Hydrogen Demand From Carbon Truck Travel By $(Zones[z])" for
                        z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Carbon Truck Travel",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:eHBalanceCTruckTravel]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end
        end

        if settings["ModelSynfuels"] == 1
            synfuels_settings = settings["SynfuelsSettings"]
            ## Additional demand from synfuels generation
            df = DataFrame(
                Term = [
                    "Additional Hydrogen Demand From Synfuels Generation By $(Zones[z])" for
                    z in 1:Z
                ],
                Zone = Zones,
                Sector = "Synfuels Generation",
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eHBalanceSGen]); sigdigits = 4), :auto))

            push!(dfs, df)
            if synfuels_settings["ModelTrucks"] == 1
                ## Additional demand from carbon truck travel
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Synfuels Truck Travel By $(Zones[z])" for
                        z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Synfuels Truck Travel",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:eHBalanceSTruckTravel]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end
        end

        if settings["ModelAmmonia"] == 1
            ammonia_settings = settings["AmmoniaSettings"]
            ## Additional demand from ammonia generation
            df = DataFrame(
                Term = [
                    "Additional Hydrogen Demand From Ammonia Generation By $(Zones[z])" for z in 1:Z
                ],
                Zone = Zones,
                Sector = "Ammonia Generation",
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eHBalanceAGen]); sigdigits = 4), :auto))

            push!(dfs, df)
            if ammonia_settings["ModelTrucks"] == 1
                ## Additional demand from carbon truck travel
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Ammonia Truck Travel By $(Zones[z])" for
                        z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Ammonia Truck Travel",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:eHBalanceATruckTravel]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end
        end

        if settings["ModelFoodstuff"] == 1
            ## Additional demand from foodstuff ammonia generation when ammonia sector is not modeled
            if !(settings["ModelAmmonia"] == 1)
                df = DataFrame(
                    Term = [
                        "Additional Hydrogen Demand From Foodstuff Fertizer By $(Zones[z])" for
                        z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Foodstuff Fertizer",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:eHBalanceCropGrowing]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end
        end

        ## Gather all balance dataframes into one
        df = reduce(vcat, dfs)

        auxNew_Names = [
            Symbol("Term")
            Symbol("Zone")
            Symbol("Sector")
            Symbol("Total")
            tsymbols
        ]
        rename!(df, auxNew_Names)

        df[!, :Total] = round.((sum(df[!, c] for c in tsymbols)); sigdigits = 4)

        ## CSV writing
        CSV.write(joinpath(path, "additional_demand_decomposition.csv"), permutedims(df, "Term"))
    end
end
