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
function write_bioenergy_husk_consumption(settings::Dict, inputs::Dict, MESS::Model)

    bioenergy_settings = settings["BioenergySettings"]
    path = bioenergy_settings["SavePath"]

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]
    tsymbols = [Symbol("$t") for t in 1:T]

    bioenergy_inputs = inputs["BioenergyInputs"]

    dfs = []
    ## Husk consumption in each zone in each time step
    df = DataFrame(Term = ["Husk Consumption By $(Zones[z])" for z in 1:Z], Zone = Zones, Total = 0)

    df = hcat(df, DataFrame(round.(value.(MESS[:eBHuskConsumption]); sigdigits = 4), :auto))

    push!(dfs, df)

    ## Husk consumption from biosolid fuels in each zone in each time step
    df = DataFrame(
        Term = ["Husk Consumption From Generation By $(Zones[z])" for z in 1:Z],
        Zone = Zones,
        Total = 0,
    )

    df = hcat(df, DataFrame(round.(value.(MESS[:eBHuskConsumptionByGen]); sigdigits = 4), :auto))

    push!(dfs, df)

    ## Gather all straw consumption dataframes into one
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
    CSV.write(joinpath(path, "bioenergy_husk_consumption_by_zone.csv"), permutedims(df, "Term"))
end
