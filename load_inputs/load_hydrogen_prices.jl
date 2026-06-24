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
function load_hydrogen_prices(path::AbstractString, settings::Dict, inputs::Dict)

    Zones = inputs["Zones"]
    Time_Index = inputs["Time_Index"]

    ## Read in hydrogen prices file
    hydrogen_in = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Hydrogen type index
    Hydrogen_Index = filter(x -> any(occursin.(string.(Zones), x)), names(hydrogen_in)[2:end])
    if isempty(Hydrogen_Index)
        print_and_log(
            settings,
            "w",
            "Adopting Unified Hydrogen Prices in the Model, Please Check Hydrogen Type Binding",
        )
        Hydrogen_Index = names(hydrogen_in)[2:end]
    end

    ## Hydrogen costs time series ($/tonne-H2)
    costs = Matrix{Float64}(hydrogen_in[Time_Index .+ 1, Symbol.(Hydrogen_Index)])

    ## Hydrogen CO2 emission rate (tonne-CO2/tonne-H2)
    carbon_rate = hydrogen_in[1, Symbol.(Hydrogen_Index)]

    hydrogen_costs = Dict{AbstractString, Array{Float64}}()
    hydrogen_CO2 = Dict{AbstractString, Float64}()
    for i in eachindex(Hydrogen_Index)
        hydrogen_costs[string(Hydrogen_Index[i])] = costs[:, i]
        hydrogen_CO2[string(Hydrogen_Index[i])] = carbon_rate[i]
    end

    inputs["Hydrogen_Index"] = Hydrogen_Index
    inputs["hydrogen_costs"] = hydrogen_costs
    inputs["hydrogen_CO2"] = hydrogen_CO2

    print_and_log(settings, "i", "Hydrogen Price Data Successfully Read from $path")

    return inputs
end
