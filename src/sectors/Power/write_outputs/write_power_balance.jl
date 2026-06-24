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
function write_power_balance(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        power_settings = settings["PowerSettings"]
        path = power_settings["SavePath"]

        ## Flags
        ModelTransmission = power_settings["ModelTransmission"]
        ModelStorage = power_settings["ModelStorage"]
        AllowNse = power_settings["AllowNse"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        power_inputs = inputs["PowerInputs"]
        THERM = power_inputs["THERM"]
        VRE = power_inputs["VRE"]

        dfs = []
        ## Power balance from generation
        df = DataFrame(Term = ["Generation By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(round.(value.(MESS[:ePGeneration]); digits = 2), :auto))

        push!(dfs, df)

        ## Power balance from storage
        if ModelStorage == 1
            df = DataFrame(Term = ["Storage By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

            df = hcat(df, DataFrame(round.(value.(MESS[:ePBalanceSto]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Power balance from transmission
        if ModelTransmission == 1
            df = DataFrame(
                Term = ["Transmission By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePTransmission]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Power balance from demand
        df = DataFrame(Term = ["Demand By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(-round.(value.(MESS[:ePDemand]); digits = 2), :auto))

        push!(dfs, df)

        ## Generation from thermal resources
        if !isempty(THERM)
            df = DataFrame(
                Term = ["Generation Therm By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePBalanceTherm]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Generation from renewable resources
        if !isempty(VRE)
            df = DataFrame(
                Term = ["Generation VRE By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePBalanceVRE]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Transmission from flow
        if ModelTransmission == 1
            df = DataFrame(
                Term = ["TransmissionFlow By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePBalanceLineFlow]); digits = 2), :auto))

            push!(dfs, df)

            ## Transmission from loss
            df = DataFrame(
                Term = ["TransmissionLoss By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePBalanceLineLoss]); digits = 2), :auto))

            push!(dfs, df)
        end

        if ModelStorage == 1
            ## Storage from discharge
            df = DataFrame(
                Term = ["Storage Discharge By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePBalanceStoDis]); digits = 2), :auto))

            push!(dfs, df)

            ## Storage from charge
            df = DataFrame(
                Term = ["Storage Charge By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePBalanceStoCha]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Demand from non-served energy
        if AllowNse == 1
            df = DataFrame(
                Term = ["Non Served Demand By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePBalanceNse]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Demand from inputs
        df =
            DataFrame(Term = ["Inputs Demand By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(-round.(power_inputs["D"]; digits = 2), :auto))

        push!(dfs, df)

        ## Demand from additional demand
        df = DataFrame(
            Term = ["Additional Demand By $(Zones[z])" for z in 1:Z],
            Zone = Zones,
            Total = 0,
        )

        df = hcat(df, DataFrame(-round.(value.(MESS[:ePDemandAddition]); digits = 2), :auto))

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

        ## CSV writing
        CSV.write(joinpath(path, "balance.csv"), permutedims(df, "Term"))
    end
end
