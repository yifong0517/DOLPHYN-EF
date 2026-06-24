module Foodstuff

## User functions
export load_foodstuff_settings
export update_foodstuff_settings
export load_foodstuff_inputs
export load_foodstuff_time_series
export generate_foodstuff
export write_foodstuff_analysis
export write_foodstuff_outputs

## External packages
using CSV
using YAML
using JSON
using JLD2
using Dates

using IterTools
using StatsBase
using DataFrames

using JuMP
using MathOptInterface

using Revise
using Documenter

# Auxilary tools
include("../../tools/print_and_log.jl")

# Utilities
include("../../base/hours_before.jl")

## Load foodstuff sector settings
include("load_inputs/load_foodstuff_settings.jl")
include("load_inputs/load_foodstuff_default_settings.jl")
include("load_inputs/update_foodstuff_settings.jl")
include("load_inputs/override_foodstuff_sector_settings.jl")

## Load foodstuff sector inputs
include("load_inputs/load_foodstuff_inputs.jl")
include("load_inputs/load_foodstuff_time_series.jl")
include("load_inputs/load_foodstuff_land.jl")
include("load_inputs/load_foodstuff_crops.jl")
include("load_inputs/load_foodstuff_food.jl")
include("load_inputs/load_foodstuff_crops_time.jl")
include("load_inputs/load_foodstuff_trucks.jl")
include("load_inputs/load_foodstuff_routes.jl")
include("load_inputs/load_foodstuff_storage.jl")
include("load_inputs/load_foodstuff_demand.jl")
include("load_inputs/load_foodstuff_import.jl")
include("load_inputs/load_foodstuff_export.jl")

## Foodstuff sector model
include("base/consumption_in_foodstuff.jl")
include("base/generate_foodstuff.jl")

include("model/import/crop_import.jl")
include("model/import/crop_import_limit.jl")

include("model/export/crop_export.jl")
include("model/export/crop_export_limit.jl")

include("model/farming/crop_farming_all.jl")
include("model/farming/crop_land.jl")
include("model/farming/crop_sowing.jl")
include("model/farming/crop_growth.jl")
include("model/farming/crop_fertilizer.jl")
include("model/farming/crop_harvest.jl")
include("model/farming/crop_residuals.jl")

include("model/warehouse/crop_warehouse_all.jl")

include("model/production/production_all.jl")
include("model/production/production_food.jl")
include("model/production/production_residuals.jl")

include("model/warehouse/food_warehouse_volume.jl")
include("model/warehouse/food_warehouse_investment_volume.jl")

include("model/transmission/crop_transport.jl")
include("model/transmission/food_transport.jl")
include("model/transmission/truck_all.jl")
include("model/transmission/truck_investment.jl")

include("model/demand/demand_all.jl")
include("model/demand/demand_additional.jl")

include("model/consumption/consumption.jl")

## Write foodstuff sector outputs
include("write_outputs/write_foodstuff_analysis.jl")
include("write_outputs/write_foodstuff_outputs.jl")
include("write_outputs/write_foodstuff_fuels_consumption.jl")
include("write_outputs/write_foodstuff_electricity_consumption.jl")
include("write_outputs/write_foodstuff_hydrogen_consumption.jl")
include("write_outputs/write_foodstuff_carbon_consumption.jl")
include("write_outputs/write_foodstuff_expenses.jl")
include("write_outputs/write_foodstuff_costs.jl")
include("write_outputs/write_foodstuff_crop_import.jl")
include("write_outputs/write_foodstuff_crop_export.jl")
include("write_outputs/write_foodstuff_land_usage.jl")
include("write_outputs/write_foodstuff_fertizer_usage.jl")
include("write_outputs/write_foodstuff_crop_yield.jl")
include("write_outputs/write_foodstuff_crop_warehouse.jl")
include("write_outputs/write_foodstuff_crop_transport_flow.jl")
include("write_outputs/write_foodstuff_crop_transport_flux.jl")
include("write_outputs/write_foodstuff_food_production.jl")
include("write_outputs/write_foodstuff_residuals.jl")
include("write_outputs/write_foodstuff_food_transport_flow.jl")
include("write_outputs/write_foodstuff_food_transport_flux.jl")
include("write_outputs/write_foodstuff_truck_capacity.jl")
include("write_outputs/write_foodstuff_truck_flow.jl")
include("write_outputs/write_foodstuff_food_warehouse.jl")
include("write_outputs/write_foodstuff_demand.jl")
include("write_outputs/write_foodstuff_additional_demand_decomposition.jl")
include("write_outputs/write_foodstuff_balance.jl")
include("write_outputs/write_foodstuff_emissions.jl")
include("write_outputs/write_foodstuff_captured_carbon.jl")

end # module Foodstuff
