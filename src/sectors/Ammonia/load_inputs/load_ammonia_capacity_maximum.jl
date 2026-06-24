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
function load_ammonia_capacity_maximum(path::AbstractString, ammonia_settings::Dict, inputs::Dict)

    ## Set indices for internal use
    T = inputs["T"]   # Number of time steps (hours)
    Zones = inputs["Zones"] # List of modeled zones

    ## Ammonia sector inputs dictionary
    ammonia_inputs = inputs["AmmoniaInputs"]

    ## Maximum capacity requirements related inputs
    path = joinpath(path, ammonia_settings["MaxCapacityPath"])
    dfMaxCap = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter resources in modeled zones
    dfMaxCap = filter(row -> (row.Zone in vcat(Zones, "All")), dfMaxCap)

    ## Store DataFrame of generators/resources input data for use in model
    ammonia_inputs["dfMaxCap"] = dfMaxCap

    print_and_log(
        ammonia_settings,
        "i",
        "Maximum Capacity Policy Data Successfully Read from $path",
    )

    inputs["AmmoniaInputs"] = ammonia_inputs

    return inputs
end
