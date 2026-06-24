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
function write_power_additional_demand_decomposition(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 4
        power_settings = settings["PowerSettings"]
        path = power_settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        power_inputs = inputs["PowerInputs"]

        dfs = []

        ## Additional demand
        df = DataFrame(
            Term = ["Additional Power Demand By $(Zones[z])" for z in 1:Z],
            Zone = Zones,
            Sector = "Total",
            Total = 0,
        )

        df = hcat(df, DataFrame(round.(value.(MESS[:ePDemandAddition]); sigdigits = 4), :auto))

        push!(dfs, df)

        if settings["ModelHydrogen"] == 1
            hydrogen_inputs = inputs["HydrogenInputs"]
            hydrogen_settings = settings["HydrogenSettings"]
            ELE = hydrogen_inputs["ELE"]

            ## Additional demand from hydrogen electrolyser
            if !isempty(ELE)
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Electrolyser By $(Zones[z])" for z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Hydrogen Electrolyser",
                    Total = 0,
                )

                df = hcat(df, DataFrame(round.(value.(MESS[:ePBalanceHELE]); sigdigits = 4), :auto))

                push!(dfs, df)
            end

            ## Additional demand from hydrogen charge conditioning
            if hydrogen_settings["ModelStorage"] == 1
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Hydrogen Charge Conditioning By $(Zones[z])"
                        for z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Hydrogen Charge Conditioning",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(
                        round.(value.(MESS[:ePBalanceHStoChaCondition]); sigdigits = 4),
                        :auto,
                    ),
                )

                push!(dfs, df)
            end

            hydrogen_settings = settings["HydrogenSettings"]
            if hydrogen_settings["ModelPipelines"] == 1
                ## Additional demand from hydrogen pipeline compression
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Hydrogen Pipeline Compression By $(Zones[z])"
                        for z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Hydrogen Pipeline Compression",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:ePBalanceHPipeComp]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end
            if hydrogen_settings["ModelTrucks"] == 1
                ## Additional demand from hydrogen truck travel
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Hydrogen Truck Travel By $(Zones[z])" for
                        z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Hydrogen Truck Travel",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:ePBalanceHTruckTravel]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
                ## Additional demand from hydrogen truck compression
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Hydrogen Truck Compression By $(Zones[z])"
                        for z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Hydrogen Truck Compression",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:ePBalanceHTruckComp]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end
        end

        if settings["ModelCarbon"] == 1
            carbon_inputs = inputs["CarbonInputs"]
            carbon_settings = settings["CarbonSettings"]

            ## Additional demand from carbon charge conditioning
            if carbon_settings["ModelStorage"] == 1
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Carbon Charge Conditioning By $(Zones[z])"
                        for z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Carbon Charge Conditioning",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(
                        round.(value.(MESS[:ePBalanceCStoChaCondition]); sigdigits = 4),
                        :auto,
                    ),
                )

                push!(dfs, df)
            end

            ## Additional demand from carbon direct air capture
            if carbon_settings["ModelDAC"] == 1
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Direct Air Carbon Capture By $(Zones[z])"
                        for z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Carbon Direct Air Capture",
                    Total = 0,
                )

                df = hcat(df, DataFrame(round.(value.(MESS[:ePBalanceCCap]); sigdigits = 4), :auto))

                push!(dfs, df)
            end

            if carbon_settings["ModelPipelines"] == 1
                ## Additional demand from carbon pipeline compression
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Carbon Pipeline Compression By $(Zones[z])"
                        for z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Carbon Pipeline Compression",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:ePBalanceCPipeComp]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end
            if carbon_settings["ModelTrucks"] == 1
                ## Additional demand from carbon truck travel
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Carbon Truck Travel By $(Zones[z])" for
                        z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Carbon Truck Travel",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:ePBalanceCTruckTravel]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
                ## Additional demand from carbon truck compression
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Carbon Truck Compression By $(Zones[z])"
                        for z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Carbon Truck Compression",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:ePBalanceCTruckComp]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end
        end

        if settings["ModelSynfuels"] == 1
            synfuels_settings = settings["SynfuelsSettings"]
            ## Additional demand from synfuels generation
            df = DataFrame(
                Term = [
                    "Additional Power Demand From Synfuels Generation By $(Zones[z])" for z in 1:Z
                ],
                Zone = Zones,
                Sector = "Synfuels Generation",
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePBalanceSGen]); sigdigits = 4), :auto))

            push!(dfs, df)

            if synfuels_settings["ModelPipelines"] == 1
                ## Additional demand from synfuels pipeline compression
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Synfuels Pipeline Compression By $(Zones[z])"
                        for z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Synfuels Pipeline Compression",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:ePBalanceSPipeComp]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end

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
                    DataFrame(round.(value.(MESS[:ePBalanceSTruckTravel]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
                ## Additional demand from carbon truck compression
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Synfuels Truck Compression By $(Zones[z])"
                        for z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Synfuels Truck Compression",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:ePBalanceSTruckComp]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end
        end

        if settings["ModelAmmonia"] == 1
            ammonia_settings = settings["AmmoniaSettings"]
            ## Additional demand from ammonia generation
            df = DataFrame(
                Term = [
                    "Additional Power Demand From Ammonia Generation By $(Zones[z])" for z in 1:Z
                ],
                Zone = Zones,
                Sector = "Ammonia Generation",
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePBalanceAGen]); sigdigits = 4), :auto))

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
                    DataFrame(round.(value.(MESS[:ePBalanceATruckTravel]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
                ## Additional demand from carbon truck compression
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Ammonia Truck Compression By $(Zones[z])"
                        for z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Ammonia Truck Compression",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:ePBalanceATruckComp]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end
        end

        if settings["ModelFoodstuff"] == 1
            ## Additional demand from crop sowing
            df = DataFrame(
                Term = ["Additional Power Demand From Crop Sowing By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Sector = "Foodstuff Crop Sowing",
                Total = 0,
            )

            df = hcat(
                df,
                DataFrame(round.(value.(MESS[:ePBalanceCropSowing]); sigdigits = 4), :auto),
            )

            push!(dfs, df)
        end

        if settings["ModelBioenergy"] == 1
            bioenergy_settings = settings["BioenergySettings"]
            if bioenergy_settings["ModelTrucks"] == 1
                ## Additional demand from bioenergy truck travel
                df = DataFrame(
                    Term = [
                        "Additional Power Demand From Bioenergy Truck Travel By $(Zones[z])" for
                        z in 1:Z
                    ],
                    Zone = Zones,
                    Sector = "Bioenergy Truck Travel",
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:ePBalanceBTruckTravel]); sigdigits = 4), :auto),
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

        df[!, :Total] = round.(sum(df[!, c] for c in tsymbols); sigdigits = 4)

        ## CSV writing
        CSV.write(joinpath(path, "additional_demand_decomposition.csv"), permutedims(df, "Term"))
    end
end
