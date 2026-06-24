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
function generate_modifications(seeds::AbstractDict{Any, Any})

    ## Parse certainty block
    if haskey(seeds, "Certainty")
        certainty = seeds["Certainty"]
    else
        certainty = Dict{String, Any}()
    end

    ## Parse combination block
    if haskey(seeds, "Combination")
        combination = seeds["Combination"]
    else
        combination = Dict{String, Vector{Any}}()
    end

    ## Parse uncertainty block
    if haskey(seeds, "Uncertainty")
        uncertainty = seeds["Uncertainty"]
    else
        uncertainty = Dict{String, Any}()
    end

    ## Parse budget block
    if haskey(seeds, "Budget")
        budget = seeds["Budget"]
    else
        budget = 0
    end

    ## Parse random seed block
    if haskey(seeds, "Seed")
        Seed = seeds["Seed"] # Guarantee reproducibility
        rng = MersenneTwister(Seed)
    else
        rng = Random.default_rng()
    end

    ## Generate modifications
    ### Combine certainty block and combination block
    modification = generate_modification(certainty, combination)

    ### Realize uncertainty block
    modification_uncertainty = realize_uncertainty(uncertainty, budget, rng)

    ### Merge certainty, combination and uncertainty blocks
    modifications = hcat(
        repeat(modification, inner = size(modification_uncertainty, 1)),
        repeat(modification_uncertainty, outer = size(modification, 1)),
    )

    ## Generate save path from uncertainty
    modifications = generate_save_path(modifications, uncertainty, "_")

    ## Add SubCase column as unique identifier
    insertcols!(modifications, 1, :SubCase => 1:size(modifications, 1))

    CSV.write(seeds["FileName"], modifications)
end
