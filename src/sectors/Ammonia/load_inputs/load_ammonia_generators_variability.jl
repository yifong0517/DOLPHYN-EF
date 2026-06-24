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
	load_ammonia_generators_variability(path::AbstractString, ammonia_settings::Dict, inputs::Dict)

Function for reading input parameters related to hourly maximum capacity factors for all generators.
"""
function load_ammonia_generators_variability(
    path::AbstractString,
    ammonia_settings::Dict,
    inputs::Dict,
)

    ## Set indices for internal use
    T = inputs["T"]   # Number of time steps (hours)

    ## Ammonia sector inputs dictionary
    ammonia_inputs = inputs["AmmoniaInputs"]

    ## Set indices for internal use
    G = ammonia_inputs["G"]

    path = joinpath(path, ammonia_settings["VariabilityPath"])
    dfVar = DataFrame(CSV.File(path, header = true), copycols = true)

    if length(ammonia_inputs["GenResources"]) == length(unique(ammonia_inputs["GenResources"]))
        ## Reorder DataFrame to R_ID order (order provided in GeneratorPath)
        select!(dfVar, [:Time_Index; Symbol.(ammonia_inputs["GenResources"])])

        ## Maximum ammonia output and variability of each energy resource
        ammonia_inputs["P_Max"] = transpose(Matrix{Float64}(dfVar[1:T, 2:(G + 1)]))
    else
        ## Maximum ammonia output and variability of each energy resource
        ammonia_inputs["P_Max"] = transpose(
            Matrix{Float64}(hcat([dfVar[1:T, gr] for gr in ammonia_inputs["GenResources"]]...)),
        )
    end

    print_and_log(ammonia_settings, "i", "Generators'availability Successfully Read from $path")

    inputs["AmmoniaInputs"] = ammonia_inputs

    return inputs
end
