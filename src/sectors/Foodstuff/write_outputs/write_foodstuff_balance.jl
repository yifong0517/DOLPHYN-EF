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
function write_foodstuff_balance(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        foodstuff_settings = settings["FoodstuffSettings"]
        path = foodstuff_settings["SavePath"]

        ## Flags
        FoodTransport = foodstuff_settings["FoodTransport"]
        ModelTrucks = foodstuff_settings["ModelTrucks"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        foodstuff_inputs = inputs["FoodstuffInputs"]
        Foods = foodstuff_inputs["Foods"]

        for fs in eachindex(Foods)
            dfs = []
            ## Food balance from generation
            df = DataFrame(
                Term = ["Generation By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(
                df,
                DataFrame(round.(value.(MESS[:eFFoodProduction][:, fs, :]); digits = 2), :auto),
            )

            push!(dfs, df)

            ## Food balance from storage
            df = DataFrame(Term = ["Storage By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

            df = hcat(
                df,
                DataFrame(round.(value.(MESS[:eFFoodBalanceSto][:, fs, :]); digits = 2), :auto),
            )

            push!(dfs, df)

            ## Food balance from transmission
            df = DataFrame(
                Term = ["Transmission By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(
                df,
                DataFrame(round.(value.(MESS[:eFTransmission][:, fs, :]); digits = 2), :auto),
            )

            push!(dfs, df)

            ## Food balance from demand
            df = DataFrame(Term = ["Demand By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

            df = hcat(df, DataFrame(-round.(value.(MESS[:eFDemand][:, fs, :]); digits = 2), :auto))

            push!(dfs, df)

            ## Transmission
            if FoodTransport == 1
                df = DataFrame(
                    Term = ["General Transmission By $(Zones[z])" for z in 1:Z],
                    Zone = Zones,
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(
                        round.(value.(MESS[:eFBalanceTransportFlow][:, fs, :]); digits = 2),
                        :auto,
                    ),
                )

                push!(dfs, df)
            end

            ## Transmission from truck
            if ModelTrucks == 1
                df = DataFrame(
                    Term = ["Truck Transmission By $(Zones[z])" for z in 1:Z],
                    Zone = Zones,
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(
                        round.(value.(MESS[:eFBalanceTruckZonalFlow][:, fs, :]); digits = 2),
                        :auto,
                    ),
                )

                push!(dfs, df)
            end

            ## Storage from discharge
            df = DataFrame(
                Term = ["Storage Discharge By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(
                df,
                DataFrame(round.(value.(MESS[:eFFoodBalanceStoDis][:, fs, :]); digits = 2), :auto),
            )

            push!(dfs, df)

            ## Storage from charge
            df = DataFrame(
                Term = ["Storage Charge By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(
                df,
                DataFrame(round.(value.(MESS[:eFFoodBalanceStoCha][:, fs, :]); digits = 2), :auto),
            )

            push!(dfs, df)

            ## Demand from inputs
            df = DataFrame(
                Term = ["Inputs Demand By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(-round.(foodstuff_inputs["D"][:, fs, :]; digits = 2), :auto))

            push!(dfs, df)

            ## Demand from additional demand
            df = DataFrame(
                Term = ["Additional Demand By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(
                df,
                DataFrame(-round.(value.(MESS[:eFDemandAddition][:, fs, :]); digits = 2), :auto),
            )

            push!(dfs, df)

            ## Gather all balance dataframes into one
            df = reduce(vcat, dfs)

            auxNew_Names = [
                Symbol("Term")
                Symbol("Zone")
                Symbol("Total")
                tsymbols
            ]
            rename!(df, auxNew_Names)

            df[!, :Total] = round.(sum(df[!, c] for c in tsymbols); digits = 2)

            CSV.write(joinpath(path, "balance_$(Foods[fs]).csv"), permutedims(df, "Term"))
        end
    end
end
