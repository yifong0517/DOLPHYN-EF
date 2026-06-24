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
function write_ammonia_outputs(settings::Dict, inputs::Dict, MESS::Model)

    ammonia_settings = settings["AmmoniaSettings"]
    path = ammonia_settings["SavePath"]
    SubZone = ammonia_settings["SubZone"]
    SimpleTransport = ammonia_settings["SimpleTransport"]
    NetworkExpansion = ammonia_settings["NetworkExpansion"]
    ModelTrucks = ammonia_settings["ModelTrucks"]
    ModelStorage = ammonia_settings["ModelStorage"]

    LinearModel = inputs["LinearModel"]

    ammonia_inputs = inputs["AmmoniaInputs"]
    THERM_COMMIT = ammonia_inputs["THERM_COMMIT"]

    ## Check whether save path exists, if not, create it
    if !ispath(path)
        mkdir(path)
    end

    print_and_log(settings, "i", "Writing Outputs for Ammonia Sector to $path")

    ## Write fuels consumption
    if settings["ModelFuels"] == 1
        write_ammonia_fuels_consumption(settings, inputs, MESS)
    end

    ## Write electricity consumption
    if !(settings["ModelPower"] == 1)
        write_ammonia_electricity_consumption(settings, inputs, MESS)
    end

    ## Write ammonia consumption
    if !(settings["ModelHydrogen"] == 1)
        write_ammonia_hydrogen_consumption(settings, inputs, MESS)
    end

    ## Write ammonia sector nitrogen consumption
    write_ammonia_nitrogen_consumption(settings, inputs, MESS)

    ## Write bioenergy consumption
    if !(settings["ModelBioenergy"] == 1)
        write_ammonia_bioenergy_consumption(settings, inputs, MESS)
    end

    ## Write expenses for purchasing feedstocks from markets
    write_ammonia_expenses(settings, inputs, MESS)

    ## Write ammonia sector costs
    write_ammonia_costs(settings, inputs, MESS)

    ## Write ammonia sector generation
    write_ammonia_generation(settings, inputs, MESS)

    ## Write ammonia sector generation capacities
    write_ammonia_generation_capacities(settings, inputs, MESS)

    ## Write ammonia sector generation capacity factors
    write_ammonia_generation_capacity_factor(settings, inputs, MESS)

    ## Write ammonia sector generation lcoa
    if settings["WriteAnalysis"] == 1
        write_ammonia_generation_lcoa(settings, inputs, MESS)
    end

    ## Write ammonia sector generation composition
    write_ammonia_generation_composition(settings, inputs, MESS)

    ## Write ammonia sector generation in each sub zone
    if SubZone == 1
        write_ammonia_generation_sub_zonal(settings, inputs, MESS)
        write_ammonia_generation_composition_sub_zonal(settings, inputs, MESS)
    end

    if !isempty(THERM_COMMIT)
        ## Write ammonia sector commits
        write_ammonia_commit(settings, inputs, MESS)
    end

    ## Write ammonia sector simple transport
    if SimpleTransport == 1
        write_ammonia_transport_flow(settings, inputs, MESS)
        write_ammonia_transport_flux(settings, inputs, MESS)
    end

    ## Write ammonia sector transmission via trucks
    if ModelTrucks == 1
        ## Write ammonia sector truck capacity
        write_ammonia_truck_capacity(settings, inputs, MESS)
        ## Write ammonia sector truck flow
        write_ammonia_truck_flow(settings, inputs, MESS)
        ## Write ammonia sector truck lcoa
        if settings["WriteAnalysis"] == 1
            write_ammonia_truck_lcoa(settings, inputs, MESS)
        end
    end

    if ModelStorage == 1
        ## Write ammonia sector storage capacities
        write_ammonia_storage_capacities(settings, inputs, MESS)

        ## Write ammonia sector storage levelized costs of storage (LCOS)
        if settings["WriteAnalysis"] == 1
            write_ammonia_storage_lcos(settings, inputs, MESS)
        end

        ## Write ammonia sector storage
        write_ammonia_storage(settings, inputs, MESS)
    end

    ## Write ammonia sector demand
    write_ammonia_demand(settings, inputs, MESS)

    ## Write ammonia sector additional demand decomposition
    write_ammonia_additional_demand_decomposition(settings, inputs, MESS)

    ## Write ammonia sector balance
    write_ammonia_balance(settings, inputs, MESS)

    ## Write ammonia sector balance shadow price and component revenues
    if haskey(MESS, :cSBalance) && LinearModel == 1
        ## Write ammonia sector balance shadow price
        write_ammonia_balance_shadow_price(settings, inputs, MESS)
        ## Write ammonia sector generator revenues
        write_ammonia_generator_revenues(settings, inputs, MESS)
        ## Write ammonia sector storage revenues
        if ModelStorage == 1
            write_ammonia_storage_revenues(settings, inputs, MESS)
        end
    end

    ## Write ammonia sector emissions
    write_ammonia_emissions(settings, inputs, MESS)

    ## Write ammonia sector captured carbon
    write_ammonia_captured_carbon(settings, inputs, MESS)

    return nothing
end
