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

module Modify

## User functions
export modify_settings
export modify_sector_data
export modify_sector_settings

export modify_feedstock_costs
export modify_feedstock_emission_factors
export modify_electricity_prices
export modify_electricity_emission_factors

export modify_power_settings
export modify_hydrogen_settings
export modify_carbon_settings
export modify_synfuels_settings
export modify_ammonia_settings
export modify_foodstuff_settings
export modify_bioenergy_settings

export modify_power_inputs
export modify_hydrogen_inputs
export modify_carbon_inputs
export modify_synfuels_inputs
export modify_ammonia_inputs
export modify_foodstuff_inputs
export modify_bioenergy_inputs

export modify_power_generator_capacity_factor
export modify_hydrogen_generator_capacity_factor
export modify_carbon_generator_capacity_factor
export modify_synfuels_generator_capacity_factor
export modify_ammonia_generator_capacity_factor

## External packages
using CSV
using YAML
using Dates

using DataFrames

using Revise
using Documenter

using Logging
using LoggingExtras

# Auxiliary tools
## Logging
include("../../tools/print_and_log.jl")

## Modify data
include("modify_sector_data.jl")
include("modify_sector_settings.jl")
include("modify_feedstock_costs.jl")
include("modify_feedstock_emission_factors.jl")
include("modify_electricity_prices.jl")
include("modify_electricity_emission_factors.jl")

## Modify settings
include("modify_settings.jl")

## Modify power sector data
include("power/modify_power_inputs.jl")
include("power/modify_power_settings.jl")
include("power/modify_power_generator_max_cap.jl")
include("power/modify_power_generator_existing_cap.jl")
include("power/modify_power_generator_min_cap.jl")
include("power/modify_power_generator_cap.jl")
include("power/modify_power_generator_capex.jl")
include("power/modify_power_storage_max_ene_cap.jl")
include("power/modify_power_storage_existing_ene_cap.jl")
include("power/modify_power_storage_min_ene_cap.jl")
include("power/modify_power_storage_capex.jl")
include("power/modify_power_demand.jl")
include("power/modify_power_emission_policy.jl")

include("power/modify_power_generator_capacity_factor.jl")

## Modify hydrogen sector data
include("hydrogen/modify_hydrogen_inputs.jl")
include("hydrogen/modify_hydrogen_settings.jl")
include("hydrogen/modify_hydrogen_generator_max_cap.jl")
include("hydrogen/modify_hydrogen_generator_existing_cap.jl")
include("hydrogen/modify_hydrogen_generator_min_cap.jl")
include("hydrogen/modify_hydrogen_generator_cap.jl")
include("hydrogen/modify_hydrogen_generator_flh.jl")
include("hydrogen/modify_hydrogen_generator_capex.jl")
include("hydrogen/modify_hydrogen_generator_efficiency.jl")
include("hydrogen/modify_hydrogen_storage_max_ene_cap.jl")
include("hydrogen/modify_hydrogen_storage_existing_ene_cap.jl")
include("hydrogen/modify_hydrogen_storage_min_ene_cap.jl")
include("hydrogen/modify_hydrogen_storage_capex.jl")
include("hydrogen/modify_hydrogen_demand.jl")
include("hydrogen/modify_hydrogen_emission_policy.jl")

include("hydrogen/modify_hydrogen_generator_capacity_factor.jl")

## Modify carbon sector data
include("carbon/modify_carbon_inputs.jl")
include("carbon/modify_carbon_settings.jl")
include("carbon/modify_carbon_generator_max_cap.jl")
include("carbon/modify_carbon_generator_existing_cap.jl")
include("carbon/modify_carbon_generator_min_cap.jl")
include("carbon/modify_carbon_generator_cap.jl")
include("carbon/modify_carbon_generator_flh.jl")
include("carbon/modify_carbon_generator_capex.jl")
include("carbon/modify_carbon_storage_max_ene_cap.jl")
include("carbon/modify_carbon_storage_existing_ene_cap.jl")
include("carbon/modify_carbon_storage_min_ene_cap.jl")
include("carbon/modify_carbon_storage_capex.jl")
include("carbon/modify_carbon_demand.jl")
include("carbon/modify_carbon_emission_policy.jl")

include("carbon/modify_carbon_generator_capacity_factor.jl")

## Modify synfuels sector data
include("synfuels/modify_synfuels_inputs.jl")
include("synfuels/modify_synfuels_settings.jl")
include("synfuels/modify_synfuels_generator_max_cap.jl")
include("synfuels/modify_synfuels_generator_existing_cap.jl")
include("synfuels/modify_synfuels_generator_min_cap.jl")
include("synfuels/modify_synfuels_generator_cap.jl")
include("synfuels/modify_synfuels_generator_flh.jl")
include("synfuels/modify_synfuels_generator_capex.jl")
include("synfuels/modify_synfuels_storage_max_ene_cap.jl")
include("synfuels/modify_synfuels_storage_existing_ene_cap.jl")
include("synfuels/modify_synfuels_storage_min_ene_cap.jl")
include("synfuels/modify_synfuels_storage_capex.jl")
include("synfuels/modify_synfuels_demand.jl")
include("synfuels/modify_synfuels_emission_policy.jl")

include("synfuels/modify_synfuels_generator_capacity_factor.jl")

## Modify ammonia sector data
include("ammonia/modify_ammonia_inputs.jl")
include("ammonia/modify_ammonia_settings.jl")
include("ammonia/modify_ammonia_generator_max_cap.jl")
include("ammonia/modify_ammonia_generator_existing_cap.jl")
include("ammonia/modify_ammonia_generator_min_cap.jl")
include("ammonia/modify_ammonia_generator_cap.jl")
include("ammonia/modify_ammonia_generator_flh.jl")
include("ammonia/modify_ammonia_generator_capex.jl")
include("ammonia/modify_ammonia_storage_max_ene_cap.jl")
include("ammonia/modify_ammonia_storage_existing_ene_cap.jl")
include("ammonia/modify_ammonia_storage_min_ene_cap.jl")
include("ammonia/modify_ammonia_storage_capex.jl")
include("ammonia/modify_ammonia_demand.jl")
include("ammonia/modify_ammonia_emission_policy.jl")

include("ammonia/modify_ammonia_generator_capacity_factor.jl")

## Modify foodstuff sector data
include("foodstuff/modify_foodstuff_inputs.jl")
include("foodstuff/modify_foodstuff_settings.jl")
include("foodstuff/modify_foodstuff_demand.jl")

## Modify bioenergy sector data
include("bioenergy/modify_bioenergy_inputs.jl")
include("bioenergy/modify_bioenergy_settings.jl")
include("bioenergy/modify_bioenergy_emission_policy.jl")

end # module Modify
