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
	load_fuels_prices(path::AbstractString, settings::Dict, inputs::Dict)

Function for reading input parameters related to fuel costs and CO$_2$ emission intensity of fuels.
"""
function load_fuels_prices(path::AbstractString, settings::Dict, inputs::Dict)

    Zones = inputs["Zones"]
    Time_Index = inputs["Time_Index"]

    ## Read in fuels prices file
    fuels_in = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Fuels type index
    Fuels_Index = filter(x -> any(occursin.(string.(Zones), x)), names(fuels_in)[2:end])
    if isempty(Fuels_Index)
        print_and_log(
            settings,
            "w",
            "Adopting Unified Fuel Prices in the Model, Please Check Fuel Type Binding",
        )
        Fuels_Index = names(fuels_in)[2:end]
    end

    ## Fuels costs time series ($/MMBtu)
    costs = Matrix{Float64}(fuels_in[Time_Index .+ 1, Symbol.(Fuels_Index)])
    ## Fuels CO2 emission rate (tonne-CO2/MMBtu)
    carbon_rate = fuels_in[1, Symbol.(Fuels_Index)]

    fuels_costs = Dict{AbstractString, Array{Float64}}()
    fuels_CO2 = Dict{AbstractString, Float64}()
    for i in eachindex(Fuels_Index)
        fuels_costs[string(Fuels_Index[i])] = costs[:, i]
        fuels_CO2[string(Fuels_Index[i])] = carbon_rate[i]
    end

    inputs["Fuels_Index"] = Fuels_Index
    inputs["fuels_costs"] = fuels_costs
    inputs["fuels_CO2"] = fuels_CO2

    print_and_log(settings, "i", "Fuels Price Data Successfully Read from $path")

    return inputs
end
