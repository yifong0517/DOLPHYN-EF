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
function write_power_generation_composition(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 4
        power_settings = settings["PowerSettings"]
        path = power_settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        tsymbols = [Symbol("$t") for t in 1:T]

        power_inputs = inputs["PowerInputs"]
        VRE = power_inputs["VRE"]
        HYDRO = power_inputs["HYDRO"]
        CFG = power_inputs["CFG"]
        GFG = power_inputs["GFG"]
        OFG = power_inputs["OFG"]
        HFG = power_inputs["HFG"]
        NFG = power_inputs["NFG"]
        BFG = power_inputs["BFG"]

        dfs = []
        ## Power generation from all types of generators
        df = DataFrame(Term = ["Generation By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

        df = hcat(df, DataFrame(round.(value.(MESS[:ePGeneration]); sigdigits = 4), :auto))

        push!(dfs, df)

        if !isempty(VRE)
            ## Power generation from renewable energy sources
            df = DataFrame(
                Term = ["Generation From VRE By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePBalanceVRE]); sigdigits = 4), :auto))

            push!(dfs, df)
        end

        if !isempty(HYDRO)
            ## Power generation from hydro power plants
            df = DataFrame(
                Term = ["Generation From Hydro By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePBalanceHydro]); sigdigits = 4), :auto))

            push!(dfs, df)
        end

        if !isempty(CFG)
            ## Power generation from coal fired generators
            df = DataFrame(
                Term = ["Generation From Coal Fired By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePGenerationCFG]); sigdigits = 4), :auto))

            push!(dfs, df)
        end

        if !isempty(GFG)
            ## Power generation from natural gas fired generators
            df = DataFrame(
                Term = ["Generation From Natural Gas Fired By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePGenerationGFG]); sigdigits = 4), :auto))

            push!(dfs, df)
        end

        if !isempty(OFG)
            ## Power generation from oil fired generators
            df = DataFrame(
                Term = ["Generation From Oil Fired By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePGenerationOFG]); sigdigits = 4), :auto))

            push!(dfs, df)
        end

        if !isempty(HFG)
            ## Power generation from hydrogen fired generators
            df = DataFrame(
                Term = ["Generation From Hydrogen By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePGenerationHFG]); sigdigits = 4), :auto))

            push!(dfs, df)
        end

        if !isempty(NFG)
            ## Power generation from nuclear fired generators
            df = DataFrame(
                Term = ["Generation From Nuclear By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePGenerationNFG]); sigdigits = 4), :auto))

            push!(dfs, df)
        end

        if !isempty(BFG)
            ## Power generation from biomass fired generators
            df = DataFrame(
                Term = ["Generation From Biomass Solid Fuels By $(Zones[z])" for z in 1:Z],
                Zone = Zones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:ePGenerationBFG]); sigdigits = 4), :auto))

            push!(dfs, df)
        end

        ## Gather all generation dataframes into one
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
        CSV.write(joinpath(path, "generation_zonal_by_type.csv"), permutedims(df, "Term"))
    end
end
