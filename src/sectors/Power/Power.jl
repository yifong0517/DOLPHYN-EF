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

module Power

## User functions
export load_power_settings
export update_power_settings
export load_power_inputs
export load_power_time_series
export generate_power
export write_power_analysis_generation
export write_power_analysis_renewable
export write_power_analysis_balance
export write_power_outputs
export power_mga_objective
export power_mga_variables

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

## Load power sector settings
include("load_inputs/load_power_settings.jl")
include("load_inputs/load_power_default_settings.jl")
include("load_inputs/update_power_settings.jl")
include("load_inputs/override_power_sector_settings.jl")

## Load power sector inputs
include("load_inputs/load_power_inputs.jl")
include("load_inputs/load_power_time_series.jl")
include("load_inputs/load_power_generators.jl")
include("load_inputs/load_power_generators_variability.jl")
include("load_inputs/load_power_network.jl")
include("load_inputs/load_power_storage.jl")
include("load_inputs/load_power_demand.jl")
include("load_inputs/load_power_nse.jl")
include("load_inputs/load_power_emission_policy.jl")
include("load_inputs/load_power_capacity_reserve.jl")
include("load_inputs/load_power_primary_reserve.jl")
include("load_inputs/load_power_capacity_minimum.jl")
include("load_inputs/load_power_capacity_maximum.jl")
include("load_inputs/load_power_energy_share.jl")
include("load_inputs/load_power_carbon_disposal.jl")

## Power sector model
include("base/carbon_disposal_in_power.jl")
include("base/consumption_in_power.jl")
include("base/generate_power.jl")

include("model/consumption/consumption.jl")

include("model/generation/generation_all.jl")
include("model/generation/generation_investment.jl")
include("model/generation/generation_vre.jl")
include("model/generation/generation_cfg.jl")
include("model/generation/generation_gfg.jl")
include("model/generation/generation_ofg.jl")
include("model/generation/generation_hfg.jl")
include("model/generation/generation_nfg.jl")
include("model/generation/generation_bfg.jl")
include("model/generation/generation_hydro.jl")
include("model/generation/generation_thermal.jl")
include("model/generation/generation_commit.jl")
include("model/generation/generation_no_commit.jl")
include("model/generation/generation_must_run.jl")
include("model/generation/generation_ccs.jl")

include("model/transmission/transmission_all.jl")
include("model/transmission/transmission_dcopf.jl")
include("model/transmission/transmission_investment.jl")

include("model/storage/storage_all.jl")
include("model/storage/storage_energy.jl")
include("model/storage/storage_charge.jl")
include("model/storage/storage_discharge.jl")
include("model/storage/storage_aging.jl")
include("model/storage/storage_investment.jl")
include("model/storage/storage_investment_energy.jl")
include("model/storage/storage_investment_charge.jl")
include("model/storage/storage_investment_discharge.jl")

include("model/demand/demand_all.jl")
include("model/demand/demand_non_served.jl")
include("model/demand/demand_additional.jl")

## MGA modeling
include("mga/power_mga_objective.jl")
include("mga/power_mga_variables.jl")

## Power sector carbon policies
include("polices/power_emission_policy.jl")
include("polices/power_capacity_reserve.jl")
include("polices/power_primary_reserve.jl")
include("polices/power_capacity_minimum.jl")
include("polices/power_capacity_maximum.jl")
include("polices/power_energy_share.jl")

## Write power sector outputs
include("write_outputs/write_power_analysis_balance.jl")
include("write_outputs/write_power_analysis_generation.jl")
include("write_outputs/write_power_analysis_renewable.jl")
include("write_outputs/write_power_outputs.jl")
include("write_outputs/write_power_fuels_consumption.jl")
include("write_outputs/write_power_hydrogen_consumption.jl")
include("write_outputs/write_power_carbon_consumption.jl")
include("write_outputs/write_power_bioenergy_consumption.jl")
include("write_outputs/write_power_expenses.jl")
include("write_outputs/write_power_costs.jl")
include("write_outputs/write_power_generation.jl")
include("write_outputs/write_power_generation_sub_zonal.jl")
include("write_outputs/write_power_generation_capacities.jl")
include("write_outputs/write_power_generation_lcoe.jl")
include("write_outputs/write_power_generation_composition.jl")
include("write_outputs/write_power_generation_composition_sub_zonal.jl")
include("write_outputs/write_power_generation_capacity_factor.jl")
include("write_outputs/write_power_hydro_level.jl")
include("write_outputs/write_power_renewable_curtailment.jl")
include("write_outputs/write_power_renewable_available.jl")
include("write_outputs/write_power_commit.jl")
include("write_outputs/write_power_generator_reserve.jl")
include("write_outputs/write_power_flow.jl")
include("write_outputs/write_power_transmission_angle.jl")
include("write_outputs/write_power_transmission_lcoe.jl")
include("write_outputs/write_power_expansion.jl")
include("write_outputs/write_power_storage.jl")
include("write_outputs/write_power_storage_reserve.jl")
include("write_outputs/write_power_storage_capacities.jl")
include("write_outputs/write_power_storage_lcos.jl")
include("write_outputs/write_power_demand.jl")
include("write_outputs/write_power_additional_demand_decomposition.jl")
include("write_outputs/write_power_balance.jl")
include("write_outputs/write_power_balance_shadow_price.jl")
include("write_outputs/write_power_generator_revenues.jl")
include("write_outputs/write_power_storage_revenues.jl")
include("write_outputs/write_power_emissions.jl")
include("write_outputs/write_power_captured_carbon.jl")

end # module Power
