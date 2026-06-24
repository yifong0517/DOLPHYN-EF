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
function load_electricity_prices(path::AbstractString, settings::Dict, inputs::Dict)

    Zones = inputs["Zones"]
    Time_Index = inputs["Time_Index"]

    ## Read in electricity prices file
    electricity_in = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Electricity type index
    Electricity_Index = filter(x -> any(occursin.(string.(Zones), x)), names(electricity_in)[2:end])
    if isempty(Electricity_Index)
        print_and_log(
            settings,
            "w",
            "Adopting Unified Electricity Prices in the Model, Please Check Electricity Type Binding",
        )
        Electricity_Index = names(electricity_in)[2:end]
    end

    ## Electricity costs time series ($/MW)
    costs = Matrix{Float64}(electricity_in[Time_Index .+ 1, Symbol.(Electricity_Index)])
    ## Electricity CO2 emission rate (tonne-CO2/MW)
    carbon_rate = electricity_in[1, Symbol.(Electricity_Index)]

    electricity_costs = Dict{AbstractString, Array{Float64}}()
    electricity_CO2 = Dict{AbstractString, Float64}()
    for i in eachindex(Electricity_Index)
        electricity_costs[string(Electricity_Index[i])] = costs[:, i]
        electricity_CO2[string(Electricity_Index[i])] = carbon_rate[i]
    end

    inputs["Electricity_Index"] = Electricity_Index
    inputs["electricity_costs"] = electricity_costs
    inputs["electricity_CO2"] = electricity_CO2

    print_and_log(settings, "i", "Electricity Price Data Successfully Read from $path")

    return inputs
end
