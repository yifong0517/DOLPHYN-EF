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
function load_bioenergy_prices(path::AbstractString, settings::Dict, inputs::Dict)

    Zones = inputs["Zones"]
    Time_Index = inputs["Time_Index"]

    ## Read in bioenergy prices file
    bioenergy_in = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Bioenergy type index
    Bioenergy_Index = filter(x -> any(occursin.(string.(Zones), x)), names(bioenergy_in)[2:end])
    if isempty(Bioenergy_Index)
        print_and_log(
            settings,
            "w",
            "Adopting Unified Bioenergy Prices in the Model, Please Check Bioenergy Type Binding",
        )
        Bioenergy_Index = names(bioenergy_in)[2:end]
    end

    ## Bioenergy costs time series ($/MMBtu)
    costs = Matrix{Float64}(bioenergy_in[Time_Index .+ 1, Symbol.(Bioenergy_Index)])
    ## Bioenergy CO2 emission rate (tonne-CO2/MMBtu)
    carbon_rate = bioenergy_in[1, Symbol.(Bioenergy_Index)]

    bioenergy_costs = Dict{AbstractString, Array{Float64}}()
    bioenergy_CO2 = Dict{AbstractString, Float64}()
    for i in eachindex(Bioenergy_Index)
        bioenergy_costs[string(Bioenergy_Index[i])] = costs[:, i]
        bioenergy_CO2[string(Bioenergy_Index[i])] = carbon_rate[i]
    end

    inputs["Bioenergy_Index"] = Bioenergy_Index
    inputs["bioenergy_costs"] = bioenergy_costs
    inputs["bioenergy_CO2"] = bioenergy_CO2

    print_and_log(settings, "i", "Bioenergy Price Data Successfully Read from $path")

    return inputs
end
