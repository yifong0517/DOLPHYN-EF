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
function write_ammonia_balance(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        ammonia_settings = settings["AmmoniaSettings"]
        path = ammonia_settings["SavePath"]

        ## Flags
        AllowNse = ammonia_settings["AllowNse"]
        SimpleTransport = ammonia_settings["SimpleTransport"]
        ModelTrucks = ammonia_settings["ModelTrucks"]
        ModelStorage = ammonia_settings["ModelStorage"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        ammonia_inputs = inputs["AmmoniaInputs"]
        THERM = ammonia_inputs["THERM"]
        ELE = ammonia_inputs["ELE"]

        dfs = []
        ## Ammonia balance from generation
        df = DataFrame(Term = ["Generation By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(round.(value.(MESS[:eAGeneration]); digits = 2), :auto))

        push!(dfs, df)

        ## Ammonia balance from storage
        if ModelStorage == 1
            df = DataFrame(Term = ["Storage By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

            df = hcat(df, DataFrame(round.(value.(MESS[:eABalanceSto]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Ammonia balance from transmission
        df = DataFrame(Term = ["Transmission By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(round.(value.(MESS[:eATransmission]); digits = 2), :auto))

        push!(dfs, df)

        ## Ammonia balance from demand
        df = DataFrame(Term = ["Demand By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(-round.(value.(MESS[:eADemand]); digits = 2), :auto))

        push!(dfs, df)

        ## Generation from thermal resources
        if !isempty(THERM)
            df = DataFrame(
                Term = ["Generation Therm By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eABalanceTherm]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Generation from electrolysis resources
        if !isempty(ELE)
            df = DataFrame(
                Term = ["Generation Electrolysis By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eABalanceELE]); digits = 2), :auto))

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
                DataFrame(round.(value.(MESS[:eABalanceTransportFlow]); digits = 2), :auto),
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

            df = hcat(df, DataFrame(round.(value.(MESS[:eABalanceTruckFlow]); digits = 2), :auto))

            push!(dfs, df)
        end

        if ModelStorage == 1
            ## Storage from discharge
            df = DataFrame(
                Term = ["Storage Discharge By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eABalanceStoDis]); digits = 2), :auto))

            push!(dfs, df)

            ## Storage from charge
            df = DataFrame(
                Term = ["Storage Charge By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eABalanceStoCha]); digits = 2), :auto))

            push!(dfs, df)
        end

        if AllowNse == 1
            ## Demand from non-served energy
            df = DataFrame(
                Term = ["Non Served Demand By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eABalanceNse]); digits = 2), :auto))

            push!(dfs, df)
        end

        ## Demand from inputs
        df =
            DataFrame(Term = ["Inputs Demand By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(-round.(ammonia_inputs["D"]; digits = 2), :auto))

        push!(dfs, df)

        ## Demand from additional demand
        df = DataFrame(
            Term = ["Additional Demand By $(Zones[z])" for z in 1:Z],
            Zone = Zones,
            Total = 0,
        )

        df = hcat(df, DataFrame(-round.(value.(MESS[:eADemandAddition]); digits = 2), :auto))

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
