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
	load_synfuels_generators_variability(path::AbstractString, synfuels_settings::Dict, inputs::Dict)

Function for reading input parameters related to hourly maximum capacity factors for all generators.
"""
function load_synfuels_generators_variability(
    path::AbstractString,
    synfuels_settings::Dict,
    inputs::Dict,
)

    ## Set indices for internal use
    T = inputs["T"]   # Number of time steps (hours)

    ## Synfuels sector inputs dictionary
    synfuels_inputs = inputs["SynfuelsInputs"]

    ## Set indices for internal use
    G = synfuels_inputs["G"]

    path = joinpath(path, synfuels_settings["VariabilityPath"])
    dfVar = DataFrame(CSV.File(path, header = true), copycols = true)

    if length(synfuels_inputs["GenResources"]) == length(unique(synfuels_inputs["GenResources"]))
        ## Reorder DataFrame to R_ID order (order provided in GeneratorPath)
        select!(dfVar, [:Time_Index; Symbol.(synfuels_inputs["GenResources"])])

        ## Maximum synfuels output and variability of each energy resource
        synfuels_inputs["P_Max"] = transpose(Matrix{Float64}(dfVar[1:T, 2:(G + 1)]))
    else
        ## Maximum synfuels output and variability of each energy resource
        synfuels_inputs["P_Max"] = transpose(
            Matrix{Float64}(hcat([dfVar[1:T, gr] for gr in synfuels_inputs["GenResources"]]...)),
        )
    end

    print_and_log(synfuels_settings, "i", "Generators'availability Successfully Read from $path")

    inputs["SynfuelsInputs"] = synfuels_inputs

    return inputs
end
