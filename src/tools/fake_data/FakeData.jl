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

module FakeData

## User functions
export fake_scenario
export fake_power_sector
export fake_hydrogen_sector
export fake_carbon_sector
export fake_synfuels_sector
export fake_ammonia_sector
export fake_foodstuff_sector
export fake_bioenergy_sector

## External packages
using CSV
using YAML
using Dates

using DataFrames
using Combinatorics

using Revise
using Documenter

using Logging
using LoggingExtras

## Fake scenario
include("fake_scenario.jl")

## Fake modifications
include("fake_modifications.jl")

## Fake data
include("fake_data.jl")

## Fake resources data
include("resources/fake_resources.jl")
include("resources/fake_fuels_price.jl")
include("resources/fake_carbons_price.jl")
include("resources/fake_electricitys_price.jl")
include("resources/fake_hydrogens_price.jl")
include("resources/fake_bioenergys_price.jl")
include("resources/fake_fuels_availability.jl")
include("resources/fake_carbons_availability.jl")
include("resources/fake_electricitys_availability.jl")
include("resources/fake_hydrogens_availability.jl")
include("resources/fake_bioenergys_availability.jl")

## Fake power sector data
include("power/fake_power_sector.jl")
include("power/fake_power_generators.jl")
include("power/fake_power_generators_variability.jl")
include("power/fake_power_network.jl")
include("power/fake_power_storage.jl")
include("power/fake_power_demand.jl")
include("power/fake_power_nse.jl")
include("power/fake_power_carbon_cap.jl")
include("power/fake_power_primary_reserve.jl")
include("power/fake_power_energy_share.jl")
include("power/fake_power_minimum_capacity.jl")
include("power/fake_power_maximum_capacity.jl")

## Fake hydrogen sector data
include("hydrogen/fake_hydrogen_sector.jl")
include("hydrogen/fake_hydrogen_generators.jl")
include("hydrogen/fake_hydrogen_generators_variability.jl")
include("hydrogen/fake_hydrogen_pipelines.jl")
include("hydrogen/fake_hydrogen_trucks.jl")
include("hydrogen/fake_hydrogen_routes.jl")
include("hydrogen/fake_hydrogen_storage.jl")
include("hydrogen/fake_hydrogen_demand.jl")
include("hydrogen/fake_hydrogen_nse.jl")
include("hydrogen/fake_hydrogen_carbon_cap.jl")
include("hydrogen/fake_hydrogen_minimum_capacity.jl")
include("hydrogen/fake_hydrogen_maximum_capacity.jl")

## Fake carbon sector data
include("carbon/fake_carbon_sector.jl")
include("carbon/fake_carbon_generators.jl")
include("carbon/fake_carbon_generators_variability.jl")
include("carbon/fake_carbon_pipelines.jl")
include("carbon/fake_carbon_trucks.jl")
include("carbon/fake_carbon_routes.jl")
include("carbon/fake_carbon_storage.jl")
include("carbon/fake_carbon_demand.jl")
include("carbon/fake_carbon_nse.jl")
include("carbon/fake_carbon_carbon_cap.jl")

## Fake synfuels sector data
include("synfuels/fake_synfuels_sector.jl")
include("synfuels/fake_synfuels_generators.jl")
include("synfuels/fake_synfuels_generators_variability.jl")
include("synfuels/fake_synfuels_pipelines.jl")
include("synfuels/fake_synfuels_trucks.jl")
include("synfuels/fake_synfuels_routes.jl")
include("synfuels/fake_synfuels_storage.jl")
include("synfuels/fake_synfuels_demand.jl")
include("synfuels/fake_synfuels_nse.jl")
include("synfuels/fake_synfuels_carbon_cap.jl")

## Fake ammonia sector data
include("ammonia/fake_ammonia_sector.jl")
include("ammonia/fake_ammonia_generators.jl")
include("ammonia/fake_ammonia_generators_variability.jl")
include("ammonia/fake_ammonia_pipelines.jl")
include("ammonia/fake_ammonia_trucks.jl")
include("ammonia/fake_ammonia_routes.jl")
include("ammonia/fake_ammonia_storage.jl")
include("ammonia/fake_ammonia_demand.jl")
include("ammonia/fake_ammonia_nse.jl")
include("ammonia/fake_ammonia_carbon_cap.jl")

## Fake foodstuff sector data
include("foodstuff/fake_foodstuff_sector.jl")
include("foodstuff/fake_foodstuff_crops.jl")
include("foodstuff/fake_foodstuff_land_area.jl")
include("foodstuff/fake_foodstuff_crop_time.jl")
include("foodstuff/fake_foodstuff_trucks.jl")
include("foodstuff/fake_foodstuff_routes.jl")
include("foodstuff/fake_foodstuff_warehouse.jl")
include("foodstuff/fake_foodstuff_demand.jl")
include("foodstuff/fake_foodstuff_nse.jl")

## Fake bioenergy sector data
include("bioenergy/fake_bioenergy_sector.jl")
include("bioenergy/fake_bioenergy_generators.jl")
include("bioenergy/fake_bioenergy_generators_variability.jl")
include("bioenergy/fake_bioenergy_trucks.jl")
include("bioenergy/fake_bioenergy_routes.jl")
include("bioenergy/fake_bioenergy_warehouse.jl")
include("bioenergy/fake_bioenergy_demand.jl")
include("bioenergy/fake_bioenergy_nse.jl")
include("bioenergy/fake_bioenergy_carbon_cap.jl")

end # module FakeData
