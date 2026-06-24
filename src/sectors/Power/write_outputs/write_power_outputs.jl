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

@doc raw"""

"""
function write_power_outputs(settings::Dict, inputs::Dict, MESS::Model)

    power_settings = settings["PowerSettings"]
    path = power_settings["SavePath"]
    PReserve = power_settings["PReserve"]
    SubZone = power_settings["SubZone"]
    ModelTransmission = power_settings["ModelTransmission"]
    ModelStorage = power_settings["ModelStorage"]

    LinearModel = inputs["LinearModel"]

    power_inputs = inputs["PowerInputs"]
    COMMIT = power_inputs["COMMIT"]
    HYDRO = power_inputs["HYDRO"]
    Renewable = power_inputs["Renewable"]

    ## Check whether save path exists, if not, create it
    if !ispath(path)
        mkdir(path)
    end

    print_and_log(settings, "i", "Writing Outputs for Power Sector to $path")

    ## Write fuels consumption
    if settings["ModelFuels"] == 1
        write_power_fuels_consumption(settings, inputs, MESS)
    end

    ## Write hydrogen consumption
    if !(settings["ModelHydrogen"] == 1)
        write_power_hydrogen_consumption(settings, inputs, MESS)
    end

    ## Write carbon consumption
    if !(settings["ModelCarbon"] == 1)
        write_power_carbon_consumption(settings, inputs, MESS)
    end

    ## Write bioenergy consumption
    if !(settings["ModelBioenergy"] == 1)
        write_power_bioenergy_consumption(settings, inputs, MESS)
    end

    ## Write expenses for purchasing feedstocks from markets
    write_power_expenses(settings, inputs, MESS)

    ## Write power sector costs
    write_power_costs(settings, inputs, MESS)

    ## Write power sector generation by generators
    write_power_generation(settings, inputs, MESS)

    ## Write power sector generation capacities
    write_power_generation_capacities(settings, inputs, MESS)

    ## Write power sector generation capacity factor
    write_power_generation_capacity_factor(settings, inputs, MESS)

    ## Write power sector generation levelized cost of energy (LCOE)
    if settings["WriteAnalysis"] == 1
        write_power_generation_lcoe(settings, inputs, MESS)
    end

    ## Write power sector generation by types
    write_power_generation_composition(settings, inputs, MESS)

    ## Write power sector generation in each sub zone
    if SubZone == 1
        write_power_generation_sub_zonal(settings, inputs, MESS)
        write_power_generation_composition_sub_zonal(settings, inputs, MESS)
    end

    ## Write power sector renewable generation
    if !isempty(Renewable)
        ## Write power sector renewable curtailment
        write_power_renewable_curtailment(settings, inputs, MESS)
        ## Write power sector available renewable
        write_power_renewable_available(settings, inputs, MESS)
    end

    ## Write power sector reservoir storage level
    if !isempty(HYDRO)
        write_power_hydro_level(settings, inputs, MESS)
    end

    ## Write power sector commits
    if !isempty(COMMIT)
        write_power_commit(settings, inputs, MESS)
    end

    ## Write power sector generators reserve
    if PReserve == 1
        write_power_generator_reserve(settings, inputs, MESS)
    end

    ## Write power sector network
    if ModelTransmission == 1
        ## Write power sector network expansion
        if power_settings["NetworkExpansion"] != -1
            write_power_expansion(settings, inputs, MESS)
        end

        ## Write power sector flow
        write_power_flow(settings, inputs, MESS)

        ## Write power sector transmission angle
        if power_settings["DCPowerFlow"] == 1
            write_power_transmission_angle(settings, inputs, MESS)
        end

        ## Write power sector transmission LCOE
        if settings["WriteAnalysis"] == 1
            write_power_transmission_lcoe(settings, inputs, MESS)
        end
    end

    if ModelStorage == 1
        ## Write power sector storage capacities
        write_power_storage_capacities(settings, inputs, MESS)

        ## Write power sector storage levelized costs of storage (LCOS)
        if settings["WriteAnalysis"] == 1
            write_power_storage_lcos(settings, inputs, MESS)
        end

        ## Write power sector storage
        write_power_storage(settings, inputs, MESS)

        ## Write power sector storage reserve
        if PReserve == 1
            write_power_storage_reserve(settings, inputs, MESS)
        end
    end

    ## Write power sector demand
    write_power_demand(settings, inputs, MESS)

    ## Write power sector additional demand decomposition
    write_power_additional_demand_decomposition(settings, inputs, MESS)

    ## Write power sector balance
    write_power_balance(settings, inputs, MESS)

    ## Write power sector shadow price and component revenues
    if haskey(MESS, :cPBalance) && LinearModel == 1
        ## Write power sector balance shadow price
        write_power_balance_shadow_price(settings, inputs, MESS)
        ## Write power sector generator revenues
        write_power_generator_revenues(settings, inputs, MESS)
        ## Write power sector storage revenues
        if ModelStorage == 1
            write_power_storage_revenues(settings, inputs, MESS)
        end
    end

    ## Write power sector emissions
    write_power_emissions(settings, inputs, MESS)

    ## Write power sector captured carbon
    write_power_captured_carbon(settings, inputs, MESS)

    return nothing
end
