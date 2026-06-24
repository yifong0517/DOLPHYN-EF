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
function distrib_hypergeometric(parameters::Vector{Float64}, budget::Int64, rng::AbstractRNG)

    ## Parse parameters
    N, K, n = parameters
    N = parse(Int64, N)
    K = parse(Int64, K)
    n = parse(Int64, n)

    @assert N > 0 "N must be greater than 0"
    @assert K > 0 "K must be greater than 0"
    @assert n > 0 "n must be greater than 0"
    @assert N >= K "N must be greater than or equal to K"
    @assert N >= n "N must be greater than or equal to n"

    ## Generate hypergeometric realization
    realization = rand(rng, Hypergeometric(N, K, n), budget)

    return realization
end
