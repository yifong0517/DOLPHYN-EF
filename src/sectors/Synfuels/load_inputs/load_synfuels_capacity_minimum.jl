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
function load_synfuels_capacity_minimum(path::AbstractString, synfuels_settings::Dict, inputs::Dict)

    ## Set indices for internal use
    T = inputs["T"]   # Number of time steps (hours)
    Zones = inputs["Zones"] # List of modeled zones

    ## Synfuels sector inputs dictionary
    synfuels_inputs = inputs["SynfuelsInputs"]

    ## Minimum capacity requirements related inputs
    path = joinpath(path, synfuels_settings["MinCapacityPath"])
    dfMinCap = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter resources in modeled zones
    dfMinCap = filter(row -> (row.Zone in vcat(Zones, "All")), dfMinCap)

    ## Store DataFrame of generators/resources input data for use in model
    synfuels_inputs["dfMinCap"] = dfMinCap

    print_and_log(
        synfuels_settings,
        "i",
        "Minimum Capacity Policy Data Successfully Read from $path",
    )

    inputs["SynfuelsInputs"] = synfuels_inputs

    return inputs
end
