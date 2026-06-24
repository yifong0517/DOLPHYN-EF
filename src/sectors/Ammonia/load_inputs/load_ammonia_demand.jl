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
	load_ammonia_demand(path::AbstractString, ammonia_settings::Dict, inputs::Dict)

Function for reading input parameters related to ammonia demand.
"""
function load_ammonia_demand(path::AbstractString, ammonia_settings::Dict, inputs::Dict)

    ## Set indices for internal use
    T = inputs["T"]   # Total number of time steps (hours)
    Zones = inputs["Zones"] # List of modeled zones

    ## Ammonia sector inputs dictionary
    ammonia_inputs = inputs["AmmoniaInputs"]

    path = joinpath(path, ammonia_settings["DemandPath"])
    load_in = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Demand in tonne for each zone
    ammonia_inputs["D"] = transpose(Matrix{Float64}(load_in[1:T, ["Load_tonne_$z" for z in Zones]]))

    print_and_log(ammonia_settings, "i", "Demand Data Successfully Read from $path")

    inputs["AmmoniaInputs"] = ammonia_inputs

    return inputs
end
