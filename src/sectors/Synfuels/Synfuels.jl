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

module Synfuels

## User functions
export load_synfuels_settings
export update_synfuels_settings
export load_synfuels_inputs
export load_synfuels_time_series
export generate_synfuels
export write_synfuels_analysis_balance
export write_synfuels_analysis_generation
export write_synfuels_outputs
export synfuels_mga_objective
export synfuels_mga_variables


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

## Load synfuels sector settings
include("load_inputs/load_synfuels_settings.jl")
include("load_inputs/load_synfuels_default_settings.jl")
include("load_inputs/update_synfuels_settings.jl")
include("load_inputs/override_synfuels_sector_settings.jl")

## Load synfuels sector inputs
include("load_inputs/load_synfuels_inputs.jl")
include("load_inputs/load_synfuels_time_series.jl")
include("load_inputs/load_synfuels_generators.jl")
include("load_inputs/load_synfuels_generators_variability.jl")
include("load_inputs/load_synfuels_routes.jl")
include("load_inputs/load_synfuels_network.jl")
include("load_inputs/load_synfuels_storage.jl")
include("load_inputs/load_synfuels_demand.jl")
include("load_inputs/load_synfuels_nse.jl")
include("load_inputs/load_synfuels_trucks.jl")
include("load_inputs/load_synfuels_emission_policy.jl")
include("load_inputs/load_synfuels_capacity_minimum.jl")
include("load_inputs/load_synfuels_capacity_maximum.jl")
include("load_inputs/load_synfuels_carbon_disposal.jl")

## Synfuels sector model
include("base/carbon_disposal_in_synfuels.jl")
include("base/consumption_in_synfuels.jl")
include("base/generate_synfuels.jl")

include("model/consumption/consumption.jl")

include("model/generation/generation_all.jl")
include("model/generation/generation_investment.jl")
include("model/generation/generation_ele.jl")
include("model/generation/generation_clg.jl")
include("model/generation/generation_glg.jl")
include("model/generation/generation_blg.jl")
include("model/generation/generation_thermal.jl")
include("model/generation/generation_commit.jl")
include("model/generation/generation_no_commit.jl")
include("model/generation/generation_ccs.jl")

include("model/transmission/synfuels_transport.jl")

include("model/transmission/pipeline_all.jl")
include("model/transmission/pipeline_investment.jl")
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
include("model/demand/demand_emission.jl")
include("model/demand/demand_non_served.jl")
include("model/demand/demand_additional.jl")

## MGA modeling
include("mga/synfuels_mga_objective.jl")
include("mga/synfuels_mga_variables.jl")

## Synfuels sector carbon policies
include("polices/synfuels_emission_policy.jl")
include("polices/synfuels_capacity_minimum.jl")
include("polices/synfuels_capacity_maximum.jl")

## Write synfuels sector outputs
include("write_outputs/write_synfuels_analysis_balance.jl")
include("write_outputs/write_synfuels_analysis_generation.jl")
include("write_outputs/write_synfuels_outputs.jl")
include("write_outputs/write_synfuels_fuels_consumption.jl")
include("write_outputs/write_synfuels_electricity_consumption.jl")
include("write_outputs/write_synfuels_hydrogen_consumption.jl")
include("write_outputs/write_synfuels_carbon_consumption.jl")
include("write_outputs/write_synfuels_bioenergy_consumption.jl")
include("write_outputs/write_synfuels_expenses.jl")
include("write_outputs/write_synfuels_costs.jl")
include("write_outputs/write_synfuels_generation.jl")
include("write_outputs/write_synfuels_generation_capacities.jl")
include("write_outputs/write_synfuels_generation_lcof.jl")
include("write_outputs/write_synfuels_generation_composition.jl")
include("write_outputs/write_synfuels_generation_capacity_factor.jl")
include("write_outputs/write_synfuels_generation_sub_zonal.jl")
include("write_outputs/write_synfuels_generation_composition_sub_zonal.jl")
include("write_outputs/write_synfuels_commit.jl")
include("write_outputs/write_synfuels_transport_flow.jl")
include("write_outputs/write_synfuels_transport_flux.jl")
include("write_outputs/write_synfuels_pipe_expansion.jl")
include("write_outputs/write_synfuels_pipe_flow.jl")
include("write_outputs/write_synfuels_pipe_lcof.jl")
include("write_outputs/write_synfuels_truck_capacity.jl")
include("write_outputs/write_synfuels_truck_flow.jl")
include("write_outputs/write_synfuels_truck_lcof.jl")
include("write_outputs/write_synfuels_storage.jl")
include("write_outputs/write_synfuels_storage_capacities.jl")
include("write_outputs/write_synfuels_storage_lcos.jl")
include("write_outputs/write_synfuels_demand.jl")
include("write_outputs/write_synfuels_additional_demand_decomposition.jl")
include("write_outputs/write_synfuels_balance.jl")
include("write_outputs/write_synfuels_balance_shadow_price.jl")
include("write_outputs/write_synfuels_generator_revenues.jl")
include("write_outputs/write_synfuels_storage_revenues.jl")
include("write_outputs/write_synfuels_emissions.jl")
include("write_outputs/write_synfuels_captured_carbon.jl")

end # module Synfuels
