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

module SpecificPatches

## External packages
using CSV
using YAML
using Dates

using DataFrames

using JuMP

using Revise
using Documenter

using Logging
using LoggingExtras

export power_storage_patch
export hydrogen_storage_patch
export carbon_storage_patch
export synfuels_storage_patch
export ammonia_storage_patch

# Auxiliary tools
## Logging
include("../tools/print_and_log.jl")

## Power sector patches
include("Power/power_storage_patch.jl")

## Hydrogen sector patches
include("Hydrogen/hydrogen_storage_patch.jl")

## Carbon sector patches
include("Carbon/carbon_storage_patch.jl")

## Synfuels sector patches
include("Synfuels/synfuels_storage_patch.jl")

## Ammonia sector patches
include("Ammonia/ammonia_storage_patch.jl")

end # module SpecificPatches
