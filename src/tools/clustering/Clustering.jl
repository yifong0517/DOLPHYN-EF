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

module Clustering

## User functions
export cluster
export merge_inputs

## External packages
using YAML
using Dates

using StatsBase
using Clustering
using Distances

using DataFrames

using Revise
using Documenter

using Logging
using LoggingExtras

# Auxiliary functions
include("../print_and_log.jl")

## Cluster features to obtain time aggregation
include("cluster.jl")
include("cluster_features.jl")

## Load clustering settings
include("load_time_aggregation_settings.jl")
include("load_default_time_aggregation_settings.jl")

## Merge inputs data to construct features dataframe
include("merge_inputs.jl")
include("merge_feedstock_prices.jl")
include("merge_power_inputs.jl")
include("merge_hydrogen_inputs.jl")
include("merge_carbon_inputs.jl")
include("merge_synfuels_inputs.jl")
include("merge_ammonia_inputs.jl")

## Parse features dataframe
include("remove_const_cols.jl")
include("normalize_profiles.jl")
include("stack_profiles.jl")

## Statistics
include("check_condition.jl")
include("rmse_score.jl")

end
