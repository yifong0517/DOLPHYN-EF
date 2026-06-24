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

module Carbon

## User functions
export load_carbon_settings
export update_carbon_settings
export load_carbon_inputs
export load_carbon_time_series
export generate_carbon
export write_carbon_analysis_balance
export write_carbon_analysis_generation
export write_carbon_outputs
export carbon_mga_objective
export carbon_mga_variables

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

## Load carbon sector settings
include("load_inputs/load_carbon_settings.jl")
include("load_inputs/load_carbon_default_settings.jl")
include("load_inputs/update_carbon_settings.jl")
include("load_inputs/override_carbon_sector_settings.jl")

## Load carbon sector inputs
include("load_inputs/load_carbon_inputs.jl")
include("load_inputs/load_carbon_time_series.jl")
include("load_inputs/load_carbon_generators.jl")
include("load_inputs/load_carbon_generators_variability.jl")
include("load_inputs/load_carbon_routes.jl")
include("load_inputs/load_carbon_network.jl")
include("load_inputs/load_carbon_storage.jl")
include("load_inputs/load_carbon_demand.jl")
include("load_inputs/load_carbon_nse.jl")
include("load_inputs/load_carbon_trucks.jl")
include("load_inputs/load_carbon_emission_policy.jl")
include("load_inputs/load_carbon_capacity_minimum.jl")
include("load_inputs/load_carbon_capacity_maximum.jl")

## Carbon sector model
include("base/consumption_in_carbon.jl")
include("base/generate_carbon.jl")

include("model/consumption/consumption.jl")

include("model/capture/capture_all.jl")
include("model/capture/capture_investment.jl")
include("model/capture/capture_thermal.jl")
include("model/capture/capture_commit.jl")
include("model/capture/capture_no_commit.jl")

include("model/transmission/carbon_transport.jl")
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

## MGA modeling
include("mga/carbon_mga_objective.jl")
include("mga/carbon_mga_variables.jl")

## Carbon sector carbon policies
include("polices/carbon_emission_policy.jl")
include("polices/carbon_capacity_minimum.jl")
include("polices/carbon_capacity_maximum.jl")

## Write carbon sector outputs
include("write_outputs/write_carbon_analysis_balance.jl")
include("write_outputs/write_carbon_analysis_generation.jl")
include("write_outputs/write_carbon_outputs.jl")
include("write_outputs/write_carbon_fuels_consumption.jl")
include("write_outputs/write_carbon_electricity_consumption.jl")
include("write_outputs/write_carbon_hydrogen_consumption.jl")
include("write_outputs/write_carbon_bioenergy_consumption.jl")
include("write_outputs/write_carbon_expenses.jl")
include("write_outputs/write_carbon_costs.jl")
include("write_outputs/write_carbon_capture.jl")
include("write_outputs/write_carbon_capture_capacities.jl")
include("write_outputs/write_carbon_capture_lcoc.jl")
include("write_outputs/write_carbon_capture_capacity_factor.jl")
include("write_outputs/write_carbon_capture_sub_zonal.jl")
include("write_outputs/write_carbon_commit.jl")
include("write_outputs/write_carbon_transport_flow.jl")
include("write_outputs/write_carbon_transport_flux.jl")
include("write_outputs/write_carbon_pipe_expansion.jl")
include("write_outputs/write_carbon_pipe_flow.jl")
include("write_outputs/write_carbon_pipe_lcoc.jl")
include("write_outputs/write_carbon_truck_capacity.jl")
include("write_outputs/write_carbon_truck_flow.jl")
include("write_outputs/write_carbon_truck_lcoc.jl")
include("write_outputs/write_carbon_storage.jl")
include("write_outputs/write_carbon_storage_capacities.jl")
include("write_outputs/write_carbon_storage_lcos.jl")
include("write_outputs/write_carbon_demand.jl")
include("write_outputs/write_carbon_additional_demand_decomposition.jl")
include("write_outputs/write_carbon_balance.jl")
include("write_outputs/write_carbon_balance_shadow_price.jl")
include("write_outputs/write_carbon_capture_revenues.jl")
include("write_outputs/write_carbon_storage_revenues.jl")
include("write_outputs/write_carbon_emissions.jl")
include("write_outputs/write_carbon_captured_carbon.jl")
include("write_outputs/write_carbon_net_emissions.jl")

end # module Carbon
