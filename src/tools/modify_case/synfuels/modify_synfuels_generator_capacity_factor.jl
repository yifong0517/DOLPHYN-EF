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
function modify_synfuels_generator_capacity_factor(
    synfuels_settings::Dict,
    synfuels_inputs::Dict,
    generator_index::Union{String, Int64},
    capacity_factor::Vector{Float64},
)

    print_and_log(
        synfuels_settings,
        "i",
        "Modifying Synfuels Sector Generator Maximum Capacity Factor",
    )

    P_Max = synfuels_inputs["P_Max"]

    ## Modify synfuels sector generator maximum capacity factor given specific generator index
    if typeof(generator_index) == String
        GenResources = synfuels_inputs["GenResources"]
        P_Max[findfirst(x -> x == generator_index, GenResources), :] .= capacity_factor
    elseif typeof(generator_index) == Int64
        P_Max[generator_index, :] .= capacity_factor
    end

    synfuels_inputs["P_Max"] = P_Max

    return synfuels_inputs
end
