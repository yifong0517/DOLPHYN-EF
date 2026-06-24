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
function write_emissions_composition(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 4
        path = settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        dfs = []

        ## Power sector emission composition
        if settings["ModelPower"] == 1
            ## Emission from power generation in each zone in each time step
            df = DataFrame(
                Term = ["Emission From Power Generation By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePEmissionsByGen]); sigdigits = 4), :auto))

            push!(dfs, df)
        end

        ## Hydrogen sector emission composition
        if settings["ModelHydrogen"] == 1
            hydrogen_settings = settings["HydrogenSettings"]
            ## Emission from hydrogen generation in each zone in each time step
            df = DataFrame(
                Term = ["Emission From Hydrogen Generation By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eHEmissionsByGen]); sigdigits = 4), :auto))

            push!(dfs, df)

            if hydrogen_settings["ModelFuels"] == 1 && hydrogen_settings["ModelTrucks"] == 1
                ## Emission from truck travel in each zone in each time step
                df = DataFrame(
                    Term = ["Emission From Hydrogen Truck By $(Zones[z])" for z in 1:Z],
                    Zone = Zones,
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:eHEmissionsByTruck]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end
        end

        ## Carbon sector emission composition
        if settings["ModelCarbon"] == 1
            carbon_settings = settings["CarbonSettings"]
            if carbon_settings["ModelDAC"] == 1
                ## Emission from direct air capture in each zone in each time step
                df = DataFrame(
                    Term = ["Emission From DAC By $(Zones[z])" for z in 1:Z],
                    Zone = Zones,
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:eCEmissionsByCap]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end

            if carbon_settings["ModelFuels"] == 1 && carbon_settings["ModelTrucks"] == 1
                ## Emission from truck travel in each zone in each time step
                df = DataFrame(
                    Term = ["Emission From Carbon Truck By $(Zones[z])" for z in 1:Z],
                    Zone = Zones,
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:eCEmissionsByTruck]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end
        end

        ## Synfuels sector emission composition
        if settings["ModelSynfuels"] == 1
            synfuels_settings = settings["SynfuelsSettings"]
            ## Emission from synfuels generation in each zone in each time step
            df = DataFrame(
                Term = ["Emission From Synfuels Generation By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eSEmissionsByGen]); sigdigits = 4), :auto))

            push!(dfs, df)

            if synfuels_settings["ModelFuels"] == 1 && synfuels_settings["ModelTrucks"] == 1
                ## Emission from truck travel in each zone in each time step
                df = DataFrame(
                    Term = ["Emission From Synfuels Truck By $(Zones[z])" for z in 1:Z],
                    Zone = Zones,
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:eSEmissionsByTruck]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end

            ## Emission from demand consumption in each zone in each time step
            df = DataFrame(
                Term = ["Emission From Demand By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(
                df,
                DataFrame(round.(value.(MESS[:eSEmissionsZonalByDemand]); sigdigits = 4), :auto),
            )

            push!(dfs, df)
        end

        ## Ammonia sector emission composition
        if settings["ModelAmmonia"] == 1
            ammonia_settings = settings["AmmoniaSettings"]
            ## Emission from ammonia generation in each zone in each time step
            df = DataFrame(
                Term = ["Emission From Ammonia Generation By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eAEmissionsByGen]); sigdigits = 4), :auto))

            push!(dfs, df)

            if ammonia_settings["ModelFuels"] == 1 && ammonia_settings["ModelTrucks"] == 1
                ## Emission from truck travel in each zone in each time step
                df = DataFrame(
                    Term = ["Emission From Ammonia Truck By $(Zones[z])" for z in 1:Z],
                    Zone = Zones,
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(round.(value.(MESS[:eAEmissionsByTruck]); sigdigits = 4), :auto),
                )

                push!(dfs, df)
            end
        end

        ## Foodstuff sector emission composition
        if settings["ModelFoodstuff"] == 1
            foodstuff_settings = settings["FoodstuffSettings"]
            if foodstuff_settings["ModelFuels"] == 1 && foodstuff_settings["ModelTrucks"] == 1
                ## Emission from foodstuff truck travel in each zone in each time step
                df = DataFrame(
                    Term = ["Emission From Foodstuff Truck By $(Zones[z])" for z in 1:Z],
                    Zone = Zones,
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(
                        round.(value.(MESS[:eFEmissionsFoodTruckTravel]); sigdigits = 6),
                        :auto,
                    ),
                )

                push!(dfs, df)
            end
            ## Emission from methane in each zone in each time step
            df = DataFrame(
                Term = ["Emission CO2-eq From Agriculture Methane By $(Zones[z])" for z in 1:Z],
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
                Term = ["Emission CO2-eq From Agriculture N2O By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(
                df,
                DataFrame(round.(value.(MESS[:eFCropEmissionsCO2eqN2O]); sigdigits = 6), :auto),
            )

            push!(dfs, df)
        end

        ## Bioenergy sector emission composition
        if settings["ModelBioenergy"] == 1
            bioenergy_settings = settings["BioenergySettings"]
            if bioenergy_settings["ModelFuels"] == 1 && bioenergy_settings["ModelTrucks"] == 1
                ## Emission from truck travel in each zone in each time step
                df = DataFrame(
                    Term = ["Emission From Bioenergy Truck By $(Zones[z])" for z in 1:Z],
                    Zone = Zones,
                    Total = 0,
                )

                df = hcat(
                    df,
                    DataFrame(
                        round.(value.(MESS[:eBEmissionsResidualTruckTravel]); sigdigits = 4),
                        :auto,
                    ),
                )

                push!(dfs, df)
            end
        end

        ## Gather all emission dataframes into one
        if !isempty(dfs)
            df = reduce(vcat, dfs)

            auxNew_Names = [
                Symbol("Term")
                Symbol("Zone")
                Symbol("Total")
                tsymbols
            ]
            rename!(df, auxNew_Names)

            df[!, :Total] = round.(sum(df[!, c] for c in tsymbols); sigdigits = 4)

            ## CSV writing
            CSV.write(joinpath(path, "emissions_composition.csv"), permutedims(df, "Term"))
        end
    end
end
