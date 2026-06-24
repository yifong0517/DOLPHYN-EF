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

module Sniffer

## User functions
export dynamic_sniffers
export static_sniffers
export write_sniffer

## External packages
### Data manipulation
using CSV
using Dates

### Data structures
using DataFrames
using DataStructures

### Model interface
using JuMP

### Revision
using Revise

### Utilities
using Logging
using LoggingExtras

# Auxiliary tools
## Logging
include("../../tools/print_and_log.jl")

# Dynamic sniffers
include("dynamic_sniffers.jl")

# Static sniffers
include("static_sniffers.jl")

# System sniffer
include("system_sniffer.jl")

# Settings sniffer
include("settings_sniffer.jl")

# Sector sniffer
include("sector_sniffer.jl")

## Power sector sniffer
include("power/power_sniffer.jl")
include("power/power_gen_sinffier.jl")
include("power/power_sto_sniffer.jl")
include("power/power_tra_sniffer.jl")
include("power/power_demand_sniffer.jl")

## Hydrogen sector sniffer
include("hydrogen/hydrogen_sniffer.jl")
include("hydrogen/hydrogen_gen_sniffer.jl")
include("hydrogen/hydrogen_sto_sniffer.jl")
include("hydrogen/hydrogen_tra_sniffer.jl")
include("hydrogen/hydrogen_demand_sniffer.jl")

## Carbon sector sniffer
include("carbon/carbon_sniffer.jl")
include("carbon/carbon_gen_sniffer.jl")
include("carbon/carbon_sto_sniffer.jl")
include("carbon/carbon_tra_sniffer.jl")
include("carbon/carbon_demand_sniffer.jl")

## Synfuels sector sniffer
include("synfuels/synfuels_sniffer.jl")
include("synfuels/synfuels_gen_sniffer.jl")
include("synfuels/synfuels_sto_sniffer.jl")
include("synfuels/synfuels_tra_sniffer.jl")
include("synfuels/synfuels_demand_sniffer.jl")

## Ammonia sector sniffer
include("ammonia/ammonia_sniffer.jl")
include("ammonia/ammonia_gen_sniffer.jl")
include("ammonia/ammonia_sto_sniffer.jl")
include("ammonia/ammonia_demand_sniffer.jl")

## Write sniffer into file
include("write_sniffer.jl")

end # module Sniffer
