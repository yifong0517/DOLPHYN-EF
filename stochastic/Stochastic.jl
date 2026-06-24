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

module Stochastic

## User functions
export generate_modifications

## External packages
### Data manipulation
using CSV
using YAML

### Data structures
using IterTools
using DataFrames
using Combinatorics

## Simulation
using Random
using Distributions

using Revise
using Documenter

# Auxiliary tools

## Generate modification
include("realization/generate_modifications.jl")
include("realization/generate_modification.jl")
include("realization/generate_save_path.jl")

## Uncertainty
include("realization/realize_uncertainty.jl")
include("realization/parse_uncertainty.jl")
include("realization/uncertainty_type.jl")
include("realization/realization.jl")

### Distributions
include("uncertainty/distrib_beta.jl")
include("uncertainty/distrib_binomial.jl")
include("uncertainty/distrib_discrete.jl")
include("uncertainty/distrib_exponential.jl")
include("uncertainty/distrib_gamma.jl")
include("uncertainty/distrib_geometric.jl")
include("uncertainty/distrib_hypergeometric.jl")
include("uncertainty/distrib_log_normal.jl")
include("uncertainty/distrib_negative_binomial.jl")
include("uncertainty/distrib_normal.jl")
include("uncertainty/distrib_poisson.jl")
include("uncertainty/distrib_uniform.jl")
include("uncertainty/distrib_weibull.jl")

### Interval
include("uncertainty/interval.jl")

### Single
include("uncertainty/single.jl")

end # module Stochastic
