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
function generate_modification(
    certainty::AbstractDict{Any, Any},
    combination::AbstractDict{Any, Any},
)

    ## Generate modification from certainty block
    modification_certainty = DataFrame(certainty)

    ## Values of combination block
    components = collect(values(combination))
    products = vec(collect(product(components...)))

    ## Generate modification from combination block
    modification_combination = reduce(
        vcat,
        [DataFrame(Dict(collect(keys(combination)) .=> product)) for product in products],
    )

    ## Merge modification from certainty and combination blocks
    modification = hcat(
        repeat(modification_certainty, size(modification_combination, 1)),
        modification_combination,
    )

    return modification
end
