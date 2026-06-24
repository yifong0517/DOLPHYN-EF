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
function write_hydrogen_balance(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        hydrogen_settings = settings["HydrogenSettings"]
        path = hydrogen_settings["SavePath"]

        ## Flags
        AllowNse = hydrogen_settings["AllowNse"]
        SimpleTransport = hydrogen_settings["SimpleTransport"]
        ModelPipelines = hydrogen_settings["ModelPipelines"]
        ModelTrucks = hydrogen_settings["ModelTrucks"]
        ModelStorage = hydrogen_settings["ModelStorage"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        hydrogen_inputs = inputs["HydrogenInputs"]
        THERM = hydrogen_inputs["THERM"]
        ELE = hydrogen_inputs["ELE"]

        dfs = []
        ## Hydrogen balance from generation
        df = DataFrame(Term = ["Generation By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(round.(value.(MESS[:eHGeneration]); digits = 2), :auto))

        push!(dfs, df)

        ## Hydrogen balance from storage
        if ModelStorage == 1
            df = DataFrame(Term = ["Storage By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

            df = hcat(df, DataFrame(round.(value.(MESS[:eHBalanceSto]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Hydrogen balance from transmission
        df = DataFrame(Term = ["Transmission By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(round.(value.(MESS[:eHTransmission]); digits = 2), :auto))

        push!(dfs, df)

        ## Hydrogen balance from demand
        df = DataFrame(Term = ["Demand By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(-round.(value.(MESS[:eHDemand]); digits = 2), :auto))

        push!(dfs, df)

        ## Generation from thermal resources
        if !isempty(THERM)
            df = DataFrame(
                Term = ["Generation Therm By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eHBalanceTherm]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Generation from renewable resources
        if !isempty(ELE)
            df = DataFrame(
                Term = ["GenerationELE By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eHBalanceELE]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Transmission with simple transport
        if SimpleTransport == 1
            df = DataFrame(
                Term = ["Simple Transport By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(
                df,
                DataFrame(round.(value.(MESS[:eHBalanceTransportFlow]); digits = 2), :auto),
            )

            push!(dfs, df)
        end

        ## Transmission from pipeline
        if ModelPipelines == 1
            df = DataFrame(
                Term = ["Pipeline Transmission By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eHBalancePipeFlow]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Transmission from truck
        if ModelTrucks == 1
            df = DataFrame(
                Term = ["Truck Transmission By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eHBalanceTruckFlow]); digits = 2), :auto))

            push!(dfs, df)
        end

        if ModelStorage == 1
            ## Storage from discharge
            df = DataFrame(
                Term = ["Storage Discharge By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eHBalanceStoDis]); digits = 2), :auto))

            push!(dfs, df)

            ## Storage from charge
            df = DataFrame(
                Term = ["Storage Charge By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eHBalanceStoCha]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Demand from non-served energy
        if AllowNse == 1
            df = DataFrame(
                Term = ["Non Served Demand By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eHBalanceNse]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Demand from inputs
        df =
            DataFrame(Term = ["Inputs Demand By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(-round.(hydrogen_inputs["D"]; digits = 2), :auto))

        push!(dfs, df)

        ## Demand from additional demand
        df = DataFrame(
            Term = ["Additional Demand By $(Zones[z])" for z in 1:Z],
            Zone = Zones,
            Total = 0,
        )

        df = hcat(df, DataFrame(-round.(value.(MESS[:eHDemandAddition]); digits = 2), :auto))

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

        df[!, :Total] = round.(sum(df[!, c] for c in tsymbols); sigdigits = 4)

        ## CSV writing
        CSV.write(joinpath(path, "balance.csv"), permutedims(df, "Term"))
    end
end
