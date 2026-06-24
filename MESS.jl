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

module MESS

## User functions
### basic utilities
export compare_results
export print_and_log
export showtime
export load_settings
export load_default_settings
export configure_solver
export load_inputs
export hours_after
export hours_before
export generate
export solve
export write_outputs
export mga

### Uncertainty modeling
export generate_modifications

### Fake data
export fake_scenario
export fake_power_sector
export fake_hydrogen_sector
export fake_carbon_sector
export fake_synfuels_sector
export fake_ammonia_sector
export fake_foodstuff_sector
export fake_bioenergy_sector

### Modify data & settings
export load_modifications
export load_settings_with_modifications
export load_inputs_with_modification
export modify_sector_settings
export modify_sector_data
export modify_settings

### Results sniffer
export static_sniffers

### Time Aggregation - clustering
export merge_inputs
export cluster

### General case runners
export run_mess_case
export run_general_model
export run_power_model
export run_hydrogen_model
export run_carbon_model
export run_synfuels_model
export run_ammonia_model
export run_foodstuff_model
export run_bioenergy_model

### General cases runners
export run_stochastic_cases
export run_user_single_case
export run_user_multi_cases

### Specific cases
#### Agriculture bioenergy case
export run_agriculture_bioenergy_case
export run_agriculture_bioenergy_cases
export agriculture_bioenergy_case_inputs_patch
export agriculture_bioenergy_case_model_patch
export agriculture_bioenergy_case_write_patch

#### Direct air capture case patches
export run_direct_air_capture_case
export run_direct_air_capture_cases
export direct_air_capture_case_inputs_patch
export direct_air_capture_case_model_patch
export direct_air_capture_case_write_patch

#### Energy food synergy case patches
export run_energy_food_synergy_case
export run_energy_food_synergy_cases
export energy_food_synergy_case_inputs_patch
export energy_food_synergy_case_model_patch
export energy_food_synergy_case_write_patch

#### Hydrogen storage case patches
export run_hydrogen_storage_case
export run_hydrogen_storage_cases
export hydrogen_storage_case_inputs_patch
export hydrogen_storage_case_model_patch
export hydrogen_storage_case_write_patch

#### Shipping fuels substitue case patches
export run_shipping_case
export run_shipping_cases
export shipping_fuels_substitute_case_inputs_patch
export shipping_fuels_substitute_case_model_patch
export shipping_fuels_substitute_case_write_patch

#### Shared renewable case patches
export shared_renewable_case_inputs_patch
export shared_renewable_case_model_patch
export shared_renewable_case_write_patch

#### Solein (renewable protein) case patches
export solein_case_inputs_patch
export solein_case_model_patch
export solein_case_write_patch

#### Transportation fuels substitue case patches
export run_transportation_case
export run_transportation_cases
export transport_fuels_substitute_case_inputs_patch
export transport_fuels_substitute_case_model_patch
export transport_fuels_substitute_case_write_patch

## External packages
### Data manipulation
using CSV
using YAML
using JSON
using JLD2
using Dates

### Data structures
using IterTools
using DataFrames
using Combinatorics
using DataStructures
using DataFramesMeta
using DataFrameMacros

### Calculus
using Distances
using StatsBase
using Clustering
using Statistics
using Distributions

### Distributed computing
using Distributed
using SlurmClusterManager

### Model interface
using JuMP
using MathOptInterface

### Solvers
using Gurobi
using HiGHS
using COPT
using Clp
using Cbc

### Revision
using Revise

### Utilities
using SQLite
using Logging
using LoggingExtras
using TimerOutputs
using Humanize

# Auxiliary tools
## Comparison
include("tools/compare_results.jl")

## Logging
include("tools/print_and_log.jl")

## Timer
include("tools/showtime.jl")

# Modification, Setting and Modify systems
## Uncertainty modeling
include("stochastic/Stochastic.jl")
using .Stochastic

## Fake data
include("tools/fake_data/FakeData.jl")
using .FakeData

## Modify settings and inputs
include("tools/modify_case/Modify.jl")
using .Modify

## Sniff cases
include("tools/sniffer/Sniffer.jl")
using .Sniffer

## Clustering for time scaling
include("tools/clustering/Clustering.jl")
using .Clustering

## Case runners
include("tools/case_runners/run_mess_case.jl")
include("tools/case_runners/run_general_model.jl")
include("tools/case_runners/run_power_model.jl")
include("tools/case_runners/run_hydrogen_model.jl")
include("tools/case_runners/run_carbon_model.jl")
include("tools/case_runners/run_synfuels_model.jl")
include("tools/case_runners/run_ammonia_model.jl")
include("tools/case_runners/run_foodstuff_model.jl")
include("tools/case_runners/run_bioenergy_model.jl")

## Cases runners
include("tools/cases_runners/run_stochastic_cases.jl")
include("tools/cases_runners/run_user_single_case.jl")
include("tools/cases_runners/run_user_multi_cases.jl")

## Agriculture bioenergy case runners
include("specify_case/agriculture_bioenergy/run_agriculture_bioenergy_case.jl")
include("specify_case/agriculture_bioenergy/run_agriculture_bioenergy_cases.jl")

## Direct air capture case runners
include("specify_case/direct_air_capture/run_direct_air_capture_case.jl")
include("specify_case/direct_air_capture/run_direct_air_capture_cases.jl")

### Energy food synergy case runners
include("specify_case/energy_food_synergy/run_energy_food_synergy_case.jl")
include("specify_case/energy_food_synergy/run_energy_food_synergy_cases.jl")

### Hydrogen storage case runners
include("specify_case/hydrogen_storage/run_hydrogen_storage_case.jl")
include("specify_case/hydrogen_storage/run_hydrogen_storage_cases.jl")

### Shipping fuel substitution case runners
include("specify_case/shipping_fuels_substitute/run_shipping_case.jl")
include("specify_case/shipping_fuels_substitute/run_shipping_cases.jl")

### Transportation fuel substitution case runners
include("specify_case/transport_fuels_substitute/run_transportation_case.jl")
include("specify_case/transport_fuels_substitute/run_transportation_cases.jl")

## Specific cases
include("specify_case/SpecificCases.jl")
using .SpecificCases

## Load generic settings
include("load_settings/load_settings.jl")
include("load_settings/load_default_settings.jl")
include("load_settings/load_default_resource_settings.jl")
include("load_settings/load_modifications.jl")
include("load_settings/load_settings_with_modifications.jl")

## Solver settings
include("configure_solver/configure_cbc.jl")
include("configure_solver/configure_clp.jl")
include("configure_solver/configure_cplex.jl")
include("configure_solver/configure_copt.jl")
include("configure_solver/configure_highs.jl")
include("configure_solver/configure_gurobi.jl")

include("configure_solver/configure_solver.jl")

## Load generaic inputs
include("load_inputs/load_inputs.jl")
include("load_inputs/load_inputs_with_settings.jl")
include("load_inputs/load_inputs_with_modification.jl")
include("load_inputs/load_spatial_inputs.jl")
include("load_inputs/load_temporal_inputs.jl")
include("load_inputs/load_time_index.jl")
include("load_inputs/load_time_series.jl")
include("load_inputs/load_external_inputs.jl")
include("load_inputs/load_fuels_prices.jl")
include("load_inputs/load_fuels_availability.jl")
include("load_inputs/load_electricity_prices.jl")
include("load_inputs/load_electricity_availability.jl")
include("load_inputs/load_hydrogen_prices.jl")
include("load_inputs/load_hydrogen_availability.jl")
include("load_inputs/load_bioenergy_prices.jl")
include("load_inputs/load_bioenergy_availability.jl")
include("load_inputs/load_carbon_prices.jl")
include("load_inputs/load_carbon_availability.jl")
include("load_inputs/load_disposal_prices.jl")
include("load_inputs/load_auxiliary_inputs.jl")

## General Macro Energy Synthesis System (MESS) model
include("base/hours_after.jl")
include("base/hours_before.jl")
include("base/generate.jl")
include("base/generate_from_source.jl")
include("base/generate_from_file.jl")
include("base/solve.jl")
include("base/consumption_in_base.jl")
include("base/consumption.jl")
include("base/availability.jl")
include("base/capture_psc.jl")
include("base/capture_disposal.jl")
include("base/emission_cap.jl")
include("base/demand_additional.jl")
include("base/model_balance.jl")

## Multi energy sectors
include("sectors/Power/Power.jl")
using .Power
include("sectors/Hydrogen/Hydrogen.jl")
using .Hydrogen
include("sectors/Carbon/Carbon.jl")
using .Carbon
include("sectors/Synfuels/Synfuels.jl")
using .Synfuels
include("sectors/Ammonia/Ammonia.jl")
using .Ammonia
include("sectors/Bioenergy/Bioenergy.jl")
using .Bioenergy
include("sectors/Foodstuff/Foodstuff.jl")
using .Foodstuff

## Write outputs
include("write_outputs/write_outputs.jl")
include("write_outputs/write_settings.jl")
include("write_outputs/write_fuels_consumption.jl")
include("write_outputs/write_electricity_consumption.jl")
include("write_outputs/write_hydrogen_consumption.jl")
include("write_outputs/write_carbon_consumption.jl")
include("write_outputs/write_bioenergy_consumption.jl")
include("write_outputs/write_expenses.jl")
include("write_outputs/write_emissions.jl")
include("write_outputs/write_emissions_composition.jl")
include("write_outputs/write_captured_carbon.jl")
include("write_outputs/write_captured_carbon_disposal_costs.jl")
include("write_outputs/write_sector_analysis_balance.jl")
include("write_outputs/write_sector_analysis_generation.jl")

## Modeling to generate alternative
include("mga/mga.jl")
include("mga/mga_settings.jl")
include("mga/mga_objective.jl")
include("mga/mga_variables.jl")
include("mga/solve_mga_max.jl")
include("mga/solve_mga_min.jl")

end # module MESS
