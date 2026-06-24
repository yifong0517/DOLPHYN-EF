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

module Hydrogen

## User functions
export load_hydrogen_settings
export update_hydrogen_settings
export load_hydrogen_inputs
export load_hydrogen_time_series
export generate_hydrogen
export write_hydrogen_analysis_balance
export write_hydrogen_analysis_generation
export write_hydrogen_outputs
export hydrogen_mga_objective
export hydrogen_mga_variables

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

## Load hydrogen sector settings
include("load_inputs/load_hydrogen_settings.jl")
include("load_inputs/load_hydrogen_default_settings.jl")
include("load_inputs/update_hydrogen_settings.jl")
include("load_inputs/override_hydrogen_sector_settings.jl")

## Load hydrogen sector inputs
include("load_inputs/load_hydrogen_inputs.jl")
include("load_inputs/load_hydrogen_time_series.jl")
include("load_inputs/load_hydrogen_generators.jl")
include("load_inputs/load_hydrogen_generators_variability.jl")
include("load_inputs/load_hydrogen_routes.jl")
include("load_inputs/load_hydrogen_network.jl")
include("load_inputs/load_hydrogen_storage.jl")
include("load_inputs/load_hydrogen_demand.jl")
include("load_inputs/load_hydrogen_nse.jl")
include("load_inputs/load_hydrogen_trucks.jl")
include("load_inputs/load_hydrogen_emission_policy.jl")
include("load_inputs/load_hydrogen_capacity_minimum.jl")
include("load_inputs/load_hydrogen_capacity_maximum.jl")
include("load_inputs/load_hydrogen_carbon_disposal.jl")

## Hydrogen sector model
include("base/carbon_disposal_in_hydrogen.jl")
include("base/consumption_in_hydrogen.jl")
include("base/generate_hydrogen.jl")

include("model/generation/generation_all.jl")
include("model/generation/generation_investment.jl")
include("model/generation/generation_ele.jl")
include("model/generation/generation_smr.jl")
include("model/generation/generation_cgf.jl")
include("model/generation/generation_bmg.jl")
include("model/generation/generation_thermal.jl")
include("model/generation/generation_commit.jl")
include("model/generation/generation_no_commit.jl")
include("model/generation/generation_ccs.jl")

include("model/transmission/hydrogen_transport.jl")

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
include("model/demand/demand_non_served.jl")
include("model/demand/demand_additional.jl")

include("model/consumption/consumption.jl")
include("model/consumption/consumption_hfg.jl")

## MGA modeling
include("mga/hydrogen_mga_objective.jl")
include("mga/hydrogen_mga_variables.jl")

## Hydrogen sector carbon policies
include("polices/hydrogen_emission_policy.jl")
include("polices/hydrogen_capacity_minimum.jl")
include("polices/hydrogen_capacity_maximum.jl")

## Write hydrogen sector outputs
include("write_outputs/write_hydrogen_analysis_balance.jl")
include("write_outputs/write_hydrogen_analysis_generation.jl")
include("write_outputs/write_hydrogen_outputs.jl")
include("write_outputs/write_hydrogen_fuels_consumption.jl")
include("write_outputs/write_hydrogen_electricity_consumption.jl")
include("write_outputs/write_hydrogen_carbon_consumption.jl")
include("write_outputs/write_hydrogen_bioenergy_consumption.jl")
include("write_outputs/write_hydrogen_expenses.jl")
include("write_outputs/write_hydrogen_costs.jl")
include("write_outputs/write_hydrogen_generation.jl")
include("write_outputs/write_hydrogen_generation_sub_zonal.jl")
include("write_outputs/write_hydrogen_generation_capacities.jl")
include("write_outputs/write_hydrogen_generation_lcoh.jl")
include("write_outputs/write_hydrogen_generation_composition.jl")
include("write_outputs/write_hydrogen_generation_composition_sub_zonal.jl")
include("write_outputs/write_hydrogen_generation_capacity_factor.jl")
include("write_outputs/write_hydrogen_commit.jl")
include("write_outputs/write_hydrogen_transport_flow.jl")
include("write_outputs/write_hydrogen_transport_flux.jl")
include("write_outputs/write_hydrogen_pipe_expansion.jl")
include("write_outputs/write_hydrogen_pipe_flow.jl")
include("write_outputs/write_hydrogen_pipe_lcoh.jl")
include("write_outputs/write_hydrogen_truck_capacity.jl")
include("write_outputs/write_hydrogen_truck_flow.jl")
include("write_outputs/write_hydrogen_truck_lcoh.jl")
include("write_outputs/write_hydrogen_storage.jl")
include("write_outputs/write_hydrogen_storage_capacities.jl")
include("write_outputs/write_hydrogen_storage_lcos.jl")
include("write_outputs/write_hydrogen_demand.jl")
include("write_outputs/write_hydrogen_additional_demand_decomposition.jl")
include("write_outputs/write_hydrogen_balance.jl")
include("write_outputs/write_hydrogen_balance_shadow_price.jl")
include("write_outputs/write_hydrogen_generator_revenues.jl")
include("write_outputs/write_hydrogen_storage_revenues.jl")
include("write_outputs/write_hydrogen_emissions.jl")
include("write_outputs/write_hydrogen_captured_carbon.jl")

end # module Hydrogen
