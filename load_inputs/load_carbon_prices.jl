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
function load_carbon_prices(path::AbstractString, settings::Dict, inputs::Dict)

    Zones = inputs["Zones"]
    Time_Index = inputs["Time_Index"]

    ## Read in carbon prices file
    carbon_in = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Carbon type index
    Carbon_Index = filter(x -> any(occursin.(string.(Zones), x)), names(carbon_in)[2:end])
    if isempty(Carbon_Index)
        print_and_log(
            settings,
            "w",
            "Adopting Unified Carbon Prices in the Model, Please Check Carbon Type Binding",
        )
        Carbon_Index = names(carbon_in)[2:end]
    end

    ## Carbon costs time series ($/tonne-CO2)
    costs = Matrix{Float64}(carbon_in[Time_Index .+ 1, Symbol.(Carbon_Index)])
    ## Carbon CO2 emission rate (tonne-CO2/tonne-CO2)
    ## Note: Carbon here is regareded as goods in market for sale with certain emission
    ## rate and we force its emission rate to be zero no matter what in input file
    carbon_rate = zeros(length(Carbon_Index))

    carbon_costs = Dict{AbstractString, Array{Float64}}()
    carbon_CO2 = Dict{AbstractString, Float64}()
    for i in eachindex(Carbon_Index)
        carbon_costs[string(Carbon_Index[i])] = costs[:, i]
        carbon_CO2[string(Carbon_Index[i])] = carbon_rate[i]
    end

    inputs["Carbon_Index"] = Carbon_Index
    inputs["carbon_costs"] = carbon_costs
    inputs["carbon_CO2"] = carbon_CO2

    print_and_log(settings, "i", "Carbon Price Data Successfully Read from $path")

    return inputs
end
