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
function write_carbon_balance(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        carbon_settings = settings["CarbonSettings"]
        path = carbon_settings["SavePath"]

        ## Flags
        AllowDis = carbon_settings["AllowDis"]
        AllowNse = carbon_settings["AllowNse"]
        SimpleTransport = carbon_settings["SimpleTransport"]
        ModelPipelines = carbon_settings["ModelPipelines"]
        ModelTrucks = carbon_settings["ModelTrucks"]
        ModelStorage = carbon_settings["ModelStorage"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        carbon_inputs = inputs["CarbonInputs"]

        dfs = []
        ## Carbon balance from capture
        df = DataFrame(Term = ["Capture By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(round.(value.(MESS[:eCCapture]); digits = 2), :auto))

        push!(dfs, df)

        ## Carbon balance from storage
        if ModelStorage == 1
            df = DataFrame(Term = ["Storage By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

            df = hcat(df, DataFrame(round.(value.(MESS[:eCBalanceSto]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Carbon balance from transmission
        df = DataFrame(Term = ["Transmission By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(round.(value.(MESS[:eCTransmission]); digits = 2), :auto))

        push!(dfs, df)

        ## Carbon balance from demand
        df = DataFrame(Term = ["Demand By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(-round.(value.(MESS[:eCDemand]); digits = 2), :auto))

        push!(dfs, df)

        ## Capture from direct air
        df = DataFrame(
            Term = ["Direct Air Capture By $(Zones[z])" for z in 1:Z],
            Zone = Zones,
            Total = 0,
        )

        df = hcat(df, DataFrame(round.(value.(MESS[:eCCaptureDirectAir]); digits = 2), :auto))

        push!(dfs, df)

        ## Capture from point source
        df = DataFrame(
            Term = ["Point Source Capture By $(Zones[z])" for z in 1:Z],
            Zone = Zones,
            Total = 0,
        )

        df = hcat(df, DataFrame(round.(value.(MESS[:eCapturePointSource]); digits = 2), :auto))

        push!(dfs, df)

        ## Transmission with simple transport
        if SimpleTransport == 1
            df = DataFrame(
                Term = ["Simple Transport By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(
                df,
                DataFrame(round.(value.(MESS[:eCBalanceTransportFlow]); digits = 2), :auto),
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

            df = hcat(df, DataFrame(round.(value.(MESS[:eCBalancePipeFlow]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Transmission from truck
        if ModelTrucks == 1
            df = DataFrame(
                Term = ["Truck Transmission By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eCBalanceTruckFlow]); digits = 2), :auto))

            push!(dfs, df)
        end

        if ModelStorage == 1
            if AllowDis == 1
                ## Storage from discharge
                df = DataFrame(
                    Term = ["Storage Discharge By $(Zones[z])" for z in 1:Z],
                    Zone = Zones,
                    Total = 0,
                )

                df = hcat(df, DataFrame(round.(value.(MESS[:eCBalanceStoDis]); digits = 2), :auto))

                push!(dfs, df)
            end

            ## Storage from charge
            df = DataFrame(
                Term = ["Storage Charge By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eCBalanceStoCha]); digits = 2), :auto))

            push!(dfs, df)
        end

        if AllowNse == 1
            ## Demand from non-served energy
            df = DataFrame(
                Term = ["Non Served Demand By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eCBalanceNse]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Demand from inputs
        df =
            DataFrame(Term = ["Inputs Demand By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(-round.(carbon_inputs["D"]; digits = 2), :auto))

        push!(dfs, df)

        ## Demand from additional demand
        df = DataFrame(
            Term = ["Additional Demand By $(Zones[z])" for z in 1:Z],
            Zone = Zones,
            Total = 0,
        )

        df = hcat(df, DataFrame(-round.(value.(MESS[:eCDemandAddition]); digits = 2), :auto))

        push!(dfs, df)

        ## Gather all balance dataframes into one
        df = reduce(vcat, dfs)

        auxNew_Names = [
            Symbol("Term")
            Symbol("Zone")
            Symbol("Total")
            [Symbol("$t") for t in 1:T]
        ]
        rename!(df, auxNew_Names)

        df[!, :Total] = round.(sum(df[!, c] for c in tsymbols); sigdigits = 4)

        ## CSV writing
        CSV.write(joinpath(path, "balance.csv"), permutedims(df, "Term"))
    end
end
