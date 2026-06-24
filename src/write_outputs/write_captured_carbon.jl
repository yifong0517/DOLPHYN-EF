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
function write_captured_carbon(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        path = settings["SavePath"]

        ## Basic model spatial and temporal information
        ### Spatial information
        Z = inputs["Z"]
        Zones = inputs["Zones"]

        ### Temporal information
        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        tsymbols = [Symbol("$t") for t in 1:T]

        ## Initialize captured carbon dataframe
        dfCapture = DataFrame(Zone = Zones, Total = zeros(Z))

        ## Merge captured carbon into captured carbon dataframe
        dfCapture =
            hcat(dfCapture, DataFrame(round.(value.(MESS[:eCapture]); sigdigits = 6), :auto))

        ## Rename captured carbon dataframe
        names = [Symbol("Zone"); Symbol("Total"); [Symbol("$t") for t in 1:T]]
        rename!(dfCapture, names)

        ## Get total sum value via summation over all time indexes
        dfCapture[!, :Total] = round.([sum(dfCapture[z, tsymbols]) for z in 1:Z]; sigdigits = 6)

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(
                stack(
                    dfCapture[!, [Symbol("Zone"); tsymbols]],
                    tsymbols,
                    variable_name = :TimeStamp,
                    value_name = :CapturedCarbon,
                ),
                settings["DB"],
                "CapturedCarbon",
            )
        end

        ## CSV writing
        CSV.write(joinpath(path, "carbon_captured.csv"), permutedims(dfCapture, "Zone"))

        ## Initialize direct air captured carbon dataframe
        dfCapture = DataFrame(Zone = Zones, Total = zeros(Z))

        ## Merge captured carbon into captured carbon dataframe
        dfCapture =
            hcat(dfCapture, DataFrame(round.(value.(MESS[:eDCapture]); sigdigits = 6), :auto))

        ## Rename captured carbon dataframe
        names = [Symbol("Zone"); Symbol("Total"); [Symbol("$t") for t in 1:T]]
        rename!(dfCapture, names)

        ## Get total sum value via summation over all time indexes
        dfCapture[!, :Total] = round.([sum(dfCapture[z, tsymbols]) for z in 1:Z]; sigdigits = 6)

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(
                stack(
                    dfCapture[!, [Symbol("Zone"); tsymbols]],
                    tsymbols,
                    variable_name = :TimeStamp,
                    value_name = :CapturedCarbon,
                ),
                settings["DB"],
                "CapturedCarbonDirectAir",
            )
        end

        ## CSV writing
        CSV.write(joinpath(path, "carbon_captured_direct_air.csv"), permutedims(dfCapture, "Zone"))

        dfs = []
        ## Captured carbon from point source in each sector in each time step
        df = DataFrame(
            Term = ["Point Source Captured Carbon By $(Zones[z])" for z in 1:Z],
            Zone = Zones,
            Total = 0,
        )

        df = hcat(df, DataFrame(round.(value.(MESS[:eCapturePointSource]); sigdigits = 6), :auto))

        push!(dfs, df)

        ## Captured carbon from power sector in each zone in each time step
        if settings["ModelPower"] == 1
            power_inputs = inputs["PowerInputs"]
            CCS = power_inputs["CCS"]

            if !isempty(CCS)
                df = DataFrame(
                    Term = ["Point Source Captured Carbon From Power By $(Zones[z])" for z in 1:Z],
                    Zone = Zones,
                    Total = 0,
                )
                df = hcat(df, DataFrame(round.(value.(MESS[:ePCapture]); sigdigits = 6), :auto))
                push!(dfs, df)
            end
        end

        ## Captured carbon from hydrogen sector in each zone in each time step
        if settings["ModelHydrogen"] == 1
            hydrogen_inputs = inputs["HydrogenInputs"]
            CCS = hydrogen_inputs["CCS"]

            if !isempty(CCS)
                df = DataFrame(
                    Term = [
                        "Point Source Captured Carbon From Hydrogen By $(Zones[z])" for z in 1:Z
                    ],
                    Zone = Zones,
                    Total = 0,
                )
                df = hcat(df, DataFrame(round.(value.(MESS[:eHCapture]); sigdigits = 6), :auto))
                push!(dfs, df)
            end
        end

        ## Captured carbon from synfuels sector in each zone in each time step
        if settings["ModelSynfuels"] == 1
            synfuels_inputs = inputs["SynfuelsInputs"]
            CCS = synfuels_inputs["CCS"]

            if !isempty(CCS)
                df = DataFrame(
                    Term = [
                        "Point Source Captured Carbon From Synfuels By $(Zones[z])" for z in 1:Z
                    ],
                    Zone = Zones,
                    Total = 0,
                )
                df = hcat(df, DataFrame(round.(value.(MESS[:eSCapture]); sigdigits = 6), :auto))
                push!(dfs, df)
            end
        end

        ## Captured carbon from ammonia sector in each zone in each time step
        if settings["ModelAmmonia"] == 1
            ammonia_inputs = inputs["AmmoniaInputs"]
            CCS = ammonia_inputs["CCS"]

            if !isempty(CCS)
                df = DataFrame(
                    Term = [
                        "Point Source Captured Carbon From Ammonia By $(Zones[z])" for z in 1:Z
                    ],
                    Zone = Zones,
                    Total = 0,
                )
                df = hcat(df, DataFrame(round.(value.(MESS[:eACapture]); sigdigits = 6), :auto))
                push!(dfs, df)
            end
        end

        ## TODO: Alignment with ```generate_foodstuff.jl``` line 137
        # ## Captured carbon from foodstuff sector in each zone in each time step
        # if settings["ModelFoodstuff"] == 1
        #     foodstuff_inputs = inputs["FoodstuffInputs"]
        #     CCS = foodstuff_inputs["CCS"]

        #     if !isempty(CCS)
        #         df = DataFrame(
        #             Term = ["Point Source Captured Carbon From Foodstuff By $(Zones[z])" for z in 1:Z],
        #             Zone = Zones,
        #             Total = 0,
        #         )
        #         df = hcat(df, DataFrame(round.(value.(MESS[:eFCapture]); sigdigits = 6), :auto))
        #         push!(dfs, df)
        #     end
        # end

        ## Captured carbon from bioenergy sector in each zone in each time step
        if settings["ModelBioenergy"] == 1
            df = DataFrame(
                Term = ["Point Source Captured Carbon From Bioenergy By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )
            df = hcat(df, DataFrame(round.(value.(MESS[:eBCapture]); sigdigits = 6), :auto))
            push!(dfs, df)
        end

        ## Gather all captured carbon dataframes into one
        df = reduce(vcat, dfs)

        auxNew_Names = [
            Symbol("Term")
            Symbol("Zone")
            Symbol("Total")
            tsymbols
        ]
        rename!(df, auxNew_Names)

        df[!, :Total] = round.(sum(df[!, c] for c in tsymbols); sigdigits = 6)

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(
                stack(
                    df[!, [Symbol("Term"); Symbol("Zone"); tsymbols]],
                    tsymbols,
                    variable_name = :TimeStamp,
                    value_name = :CapturedCarbon,
                ),
                settings["DB"],
                "CapturedCarbonPointSource",
            )
        end

        ## CSV writing
        CSV.write(joinpath(path, "carbon_captured_point_source.csv"), permutedims(df, "Term"))
    end
end
