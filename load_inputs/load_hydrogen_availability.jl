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
function load_hydrogen_availability(path::AbstractString, settings::Dict, inputs::Dict)

    Zones = inputs["Zones"]
    Time_Index = inputs["Time_Index"]

    ## Potantial hydrogen list from hydrogen prices
    Hydrogen_Index = inputs["Hydrogen_Index"]

    ## Read in hydrogen availability file
    hydrogen_in = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Hydrogen availability time series (tonne)
    availability = Matrix{Float64}(hydrogen_in[Time_Index .+ 1, Symbol.(Hydrogen_Index)])

    hydrogen_availability = Dict{AbstractString, Array{Float64}}()

    for i in eachindex(Hydrogen_Index)
        hydrogen_availability[string(Hydrogen_Index[i])] = availability[:, i]
    end

    inputs["Hydrogen_Availability"] = hydrogen_availability

    print_and_log(settings, "i", "Hydrogen Availability Data Successfully Read from $path")

    return inputs
end
