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

module Ammonia

## User functions
export load_ammonia_settings
export update_ammonia_settings
export load_ammonia_inputs
export load_ammonia_time_series
export generate_ammonia
export write_ammonia_analysis_balance
export write_ammonia_analysis_generation
export write_ammonia_outputs
export ammonia_mga_objective
export ammonia_mga_variables


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

# Geo information
include("../../tools/geo/subzone.jl")

## Load ammonia sector settings
include("load_inputs/load_ammonia_settings.jl")
include("load_inputs/load_ammonia_default_settings.jl")
include("load_inputs/update_ammonia_settings.jl")
include("load_inputs/override_ammonia_sector_settings.jl")

## Load ammonia sector inputs
include("load_inputs/load_ammonia_inputs.jl")
include("load_inputs/load_ammonia_time_series.jl")
include("load_inputs/load_ammonia_generators.jl")
include("load_inputs/load_ammonia_generators_variability.jl")
include("load_inputs/load_ammonia_routes.jl")
include("load_inputs/load_ammonia_storage.jl")
include("load_inputs/load_ammonia_demand.jl")
include("load_inputs/load_ammonia_nse.jl")
include("load_inputs/load_ammonia_trucks.jl")
include("load_inputs/load_ammonia_emission_policy.jl")
include("load_inputs/load_ammonia_capacity_minimum.jl")
include("load_inputs/load_ammonia_capacity_maximum.jl")
include("load_inputs/load_ammonia_carbon_disposal.jl")

## Synfuels sector model
include("base/carbon_disposal_in_ammonia.jl")
include("base/consumption_in_ammonia.jl")
include("base/generate_ammonia.jl")

include("model/consumption/consumption.jl")

include("model/generation/generation_all.jl")
include("model/generation/generation_investment.jl")
include("model/generation/generation_ele.jl")
include("model/generation/generation_thermal.jl")
include("model/generation/generation_commit.jl")
include("model/generation/generation_no_commit.jl")
include("model/generation/generation_bmg.jl")
include("model/generation/generation_ccs.jl")

include("model/transmission/ammonia_transport.jl")

include("model/transmission/truck_all.jl")
include("model/transmission/truck_investment.jl")

include("model/storage/storage_all.jl")
include("model/storage/storage_energy.jl")
include("model/storage/storage_charge.jl")
include("model/storage/storage_discharge.jl")
include("model/storage/storage_investment.jl")
include("model/storage/storage_investment_energy.jl")
include("model/storage/storage_investment_charge.jl")
include("model/storage/storage_investment_discharge.jl")

include("model/demand/demand_all.jl")
include("model/demand/demand_non_served.jl")
include("model/demand/demand_additional.jl")

## MGA modeling
include("mga/ammonia_mga_objective.jl")
include("mga/ammonia_mga_variables.jl")

## Synfuels sector carbon policies
include("polices/ammonia_emission_policy.jl")
include("polices/ammonia_capacity_minimum.jl")
include("polices/ammonia_capacity_maximum.jl")

## Write ammonia sector outputs
include("write_outputs/write_ammonia_analysis_balance.jl")
include("write_outputs/write_ammonia_analysis_generation.jl")
include("write_outputs/write_ammonia_outputs.jl")
include("write_outputs/write_ammonia_fuels_consumption.jl")
include("write_outputs/write_ammonia_electricity_consumption.jl")
include("write_outputs/write_ammonia_hydrogen_consumption.jl")
include("write_outputs/write_ammonia_bioenergy_consumption.jl")
include("write_outputs/write_ammonia_expenses.jl")
include("write_outputs/write_ammonia_costs.jl")
include("write_outputs/write_ammonia_generation.jl")
include("write_outputs/write_ammonia_nitrogen_consumption.jl")
include("write_outputs/write_ammonia_generation_capacities.jl")
include("write_outputs/write_ammonia_generation_lcoa.jl")
include("write_outputs/write_ammonia_generation_composition.jl")
include("write_outputs/write_ammonia_generation_capacity_factor.jl")
include("write_outputs/write_ammonia_generation_sub_zonal.jl")
include("write_outputs/write_ammonia_generation_composition_sub_zonal.jl")
include("write_outputs/write_ammonia_commit.jl")
include("write_outputs/write_ammonia_transport_flow.jl")
include("write_outputs/write_ammonia_transport_flux.jl")
include("write_outputs/write_ammonia_truck_capacity.jl")
include("write_outputs/write_ammonia_truck_flow.jl")
include("write_outputs/write_ammonia_truck_lcoa.jl")
include("write_outputs/write_ammonia_storage.jl")
include("write_outputs/write_ammonia_storage_capacities.jl")
include("write_outputs/write_ammonia_storage_lcos.jl")
include("write_outputs/write_ammonia_demand.jl")
include("write_outputs/write_ammonia_additional_demand_decomposition.jl")
include("write_outputs/write_ammonia_balance.jl")
include("write_outputs/write_ammonia_balance_shadow_price.jl")
include("write_outputs/write_ammonia_generator_revenues.jl")
include("write_outputs/write_ammonia_storage_revenues.jl")
include("write_outputs/write_ammonia_emissions.jl")
include("write_outputs/write_ammonia_captured_carbon.jl")

end # module Ammonia
