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
function load_carbon_availability(path::AbstractString, settings::Dict, inputs::Dict)

    Zones = inputs["Zones"]
    Time_Index = inputs["Time_Index"]

    ## Potantial carbon list from carbon prices
    Carbon_Index = inputs["Carbon_Index"]

    ## Read in carbon availability file
    carbon_in = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Carbon availability time series (tonne)
    availability = Matrix{Float64}(carbon_in[Time_Index .+ 1, Symbol.(Carbon_Index)])

    carbon_availability = Dict{AbstractString, Array{Float64}}()

    for i in eachindex(Carbon_Index)
        carbon_availability[string(Carbon_Index[i])] = availability[:, i]
    end

    inputs["Carbon_Availability"] = carbon_availability

    print_and_log(settings, "i", "Carbon Availability Data Successfully Read from $path")

    return inputs
end
