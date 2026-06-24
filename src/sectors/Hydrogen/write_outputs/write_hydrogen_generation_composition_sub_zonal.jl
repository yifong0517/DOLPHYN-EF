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
function write_hydrogen_generation_composition_sub_zonal(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 4
        hydrogen_settings = settings["HydrogenSettings"]
        path = hydrogen_settings["SavePath"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        tsymbols = [Symbol("$t") for t in 1:T]

        hydrogen_inputs = inputs["HydrogenInputs"]
        SubZones = hydrogen_inputs["SubZones"]

        ELE = hydrogen_inputs["ELE"]
        SMR = hydrogen_inputs["SMR"]
        CGF = hydrogen_inputs["CGF"]
        BMG = hydrogen_inputs["BMG"]

        dfs = []
        ## Hydrogen generation from all types of generators
        df = DataFrame(
            Term = ["Generation By $(SubZones[z])" for z in eachindex(SubZones)],
            SubZone = SubZones,
            Total = 0,
        )

        df = hcat(
            df,
            DataFrame(round.(value.(MESS[:eHGenerationSubZonal]).data; sigdigits = 4), :auto),
        )

        push!(dfs, df)

        ## Hydrogen generation from electrolyzer sources
        if !isempty(ELE)
            df = DataFrame(
                Term = [
                    "Generation From Electrolyzer By $(SubZones[z])" for z in eachindex(SubZones)
                ],
                SubZone = SubZones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eHBalanceELE]); sigdigits = 4), :auto))

            push!(dfs, df)
        end

        ## Hydrogen generation from steam methane reformation resources
        if !isempty(SMR)
            df = DataFrame(
                Term = [
                    "Generation From Steam Methane Reformation By $(SubZones[z])" for
                    z in eachindex(SubZones)
                ],
                SubZone = SubZones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eHGenerationSMR]); sigdigits = 4), :auto))

            push!(dfs, df)
        end

        ## Hydrogen generation from coal gasification resources
        if !isempty(CGF)
            df = DataFrame(
                Term = [
                    "Generation From Coal Gasification By $(SubZones[z])" for
                    z in eachindex(SubZones)
                ],
                SubZone = SubZones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eHGenerationCGF]); sigdigits = 4), :auto))

            push!(dfs, df)
        end

        ## Hydrogen generation from biomass gasification resources
        if !isempty(BMG)
            df = DataFrame(
                Term = [
                    "Generation From Biomass Gasification By $(SubZones[z])" for
                    z in eachindex(SubZones)
                ],
                SubZone = SubZones,
                Total = 0,
            )

            df = hcat(df, DataFrame(round.(value.(MESS[:eHGenerationBMG]); sigdigits = 4), :auto))

            push!(dfs, df)
        end

        ## Gather all generation dataframes into one
        df = reduce(vcat, dfs)

        auxNew_Names = [
            Symbol("Term")
            Symbol("SubZone")
            Symbol("Total")
            tsymbols
        ]
        rename!(df, auxNew_Names)

        df[!, :Total] = round.(sum(df[!, c] for c in tsymbols); sigdigits = 4)

        ## CSV writing
        CSV.write(joinpath(path, "generation_sub_zonal_by_type.csv"), permutedims(df, "Term"))
    end
end
