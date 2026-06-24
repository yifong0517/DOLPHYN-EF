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

module Bioenergy

## User functions
export load_bioenergy_settings
export update_bioenergy_settings
export load_bioenergy_inputs
export generate_bioenergy
export write_bioenergy_analysis
export write_bioenergy_outputs

## External packages
### Data manipulation
using CSV
using YAML
using JSON
using JLD2
using Dates

### Data structures
using DataFrames

### Calculus
using StatsBase

### Model interface
using JuMP
using MathOptInterface

### Revision
using Revise

### Utilities
using SQLite

# Auxilary tools
include("../../tools/print_and_log.jl")

# Utilities
include("../../base/hours_before.jl")

## Load bioenergy sector settings
include("load_inputs/load_bioenergy_settings.jl")
include("load_inputs/load_bioenergy_default_settings.jl")
include("load_inputs/update_bioenergy_settings.jl")
include("load_inputs/override_bioenergy_sector_settings.jl")

## Load bioenergy sector inputs
include("load_inputs/load_bioenergy_inputs.jl")
include("load_inputs/load_bioenergy_residual_types.jl")
include("load_inputs/load_bioenergy_storage.jl")
include("load_inputs/load_bioenergy_routes.jl")
include("load_inputs/load_bioenergy_trucks.jl")
include("load_inputs/load_bioenergy_emission_policy.jl")

## Synfuels sector model
include("base/consumption_in_bioenergy.jl")
include("base/generate_bioenergy.jl")

include("model/consumption/consumption.jl")
include("model/consumption/consumption_bfg.jl")
include("model/consumption/consumption_bmg.jl")
include("model/consumption/consumption_blg.jl")

include("model/residuals/bioenergy_residuals.jl")
include("model/residuals/foodstuff_residuals_straw.jl")
include("model/residuals/foodstuff_residuals_production.jl")

include("model/transmission/residual_transport.jl")
include("model/transmission/truck_all.jl")
include("model/transmission/truck_investment.jl")

include("model/storage/storage_volume.jl")
include("model/storage/storage_investment_volume.jl")

include("model/demand/demand_all.jl")
include("model/demand/demand_additional.jl")

## Synfuels sector carbon policies
include("polices/bioenergy_emission_policy.jl")

## Write bioenergy sector outputs
include("write_outputs/write_bioenergy_analysis.jl")
include("write_outputs/write_bioenergy_outputs.jl")
include("write_outputs/write_bioenergy_fuels_consumption.jl")
include("write_outputs/write_bioenergy_electricity_consumption.jl")
include("write_outputs/write_bioenergy_hydrogen_consumption.jl")
include("write_outputs/write_bioenergy_straw_consumption.jl")
include("write_outputs/write_bioenergy_husk_consumption.jl")
include("write_outputs/write_bioenergy_expenses.jl")
include("write_outputs/write_bioenergy_costs.jl")
include("write_outputs/write_bioenergy_transport_flow.jl")
include("write_outputs/write_bioenergy_transport_flux.jl")
include("write_outputs/write_bioenergy_truck_capacity.jl")
include("write_outputs/write_bioenergy_truck_flow.jl")
include("write_outputs/write_bioenergy_storage.jl")
include("write_outputs/write_bioenergy_storage_capacities.jl")
include("write_outputs/write_bioenergy_demand.jl")
include("write_outputs/write_bioenergy_balance.jl")
include("write_outputs/write_bioenergy_emissions.jl")
include("write_outputs/write_bioenergy_captured_carbon.jl")

end # module Bioenergy
