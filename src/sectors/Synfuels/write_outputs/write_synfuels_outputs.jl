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
function write_synfuels_outputs(settings::Dict, inputs::Dict, MESS::Model)

    synfuels_settings = settings["SynfuelsSettings"]
    path = synfuels_settings["SavePath"]
    SubZone = synfuels_settings["SubZone"]
    SimpleTransport = synfuels_settings["SimpleTransport"]
    ModelPipelines = synfuels_settings["ModelPipelines"]
    NetworkExpansion = synfuels_settings["NetworkExpansion"]
    ModelTrucks = synfuels_settings["ModelTrucks"]
    ModelStorage = synfuels_settings["ModelStorage"]

    LinearModel = inputs["LinearModel"]

    synfuels_inputs = inputs["SynfuelsInputs"]
    THERM_COMMIT = synfuels_inputs["THERM_COMMIT"]

    ## Check whether save path exists, if not, create it
    if !ispath(path)
        mkdir(path)
    end

    print_and_log(settings, "i", "Writing Outputs for Synfuels Sector to $path")

    ## Write fuels consumption
    if settings["ModelFuels"] == 1
        write_synfuels_fuels_consumption(settings, inputs, MESS)
    end

    ## Write electricity consumption
    if !(settings["ModelPower"] == 1)
        write_synfuels_electricity_consumption(settings, inputs, MESS)
    end

    ## Write synfuels consumption
    if !(settings["ModelHydrogen"] == 1)
        write_synfuels_hydrogen_consumption(settings, inputs, MESS)
    end

    ## Write carbon consumption
    if !(settings["ModelCarbon"] == 1)
        write_synfuels_carbon_consumption(settings, inputs, MESS)
    end

    ## Write bioenergy consumption
    if !(settings["ModelBioenergy"] == 1)
        write_synfuels_bioenergy_consumption(settings, inputs, MESS)
    end

    ## Write expenses for purchasing feedstocks from markets
    write_synfuels_expenses(settings, inputs, MESS)

    ## Write synfuels sector costs
    write_synfuels_costs(settings, inputs, MESS)

    ## Write synfuels sector generation
    write_synfuels_generation(settings, inputs, MESS)

    ## Write synfuels sector generation capacities
    write_synfuels_generation_capacities(settings, inputs, MESS)

    ## Write synfuels sector generation capacity factors
    write_synfuels_generation_capacity_factor(settings, inputs, MESS)

    ## Write synfuels sector generation lcof
    if settings["WriteAnalysis"] == 1
        write_synfuels_generation_lcof(settings, inputs, MESS)
    end

    ## Write synfuels sector generation composition
    write_synfuels_generation_composition(settings, inputs, MESS)

    ## Write synfuels sector generation in each sub zone
    if SubZone == 1
        write_synfuels_generation_sub_zonal(settings, inputs, MESS)
        write_synfuels_generation_composition_sub_zonal(settings, inputs, MESS)
    end

    if !isempty(THERM_COMMIT)
        ## Write synfuels sector commits
        write_synfuels_commit(settings, inputs, MESS)
    end

    ## Write synfuels sector transport flow and flux
    if SimpleTransport == 1
        write_synfuels_transport_flow(settings, inputs, MESS)
        write_synfuels_transport_flux(settings, inputs, MESS)
    end

    ## Write synfuels sector transmission via pipelines
    if ModelPipelines == 1
        if NetworkExpansion != -1
            ## Write synfuels sector pipeline expansion
            write_synfuels_pipe_expansion(settings, inputs, MESS)
        end
        ## Write synfuels sector pipeline flow
        write_synfuels_pipe_flow(settings, inputs, MESS)
        ## Write synfuels sector pipeline lcof
        if settings["WriteAnalysis"] == 1
            write_synfuels_pipe_lcof(settings, inputs, MESS)
        end
    end

    ## Write synfuels sector transmission via trucks
    if ModelTrucks == 1
        ## Write synfuels sector truck capacity
        write_synfuels_truck_capacity(settings, inputs, MESS)
        ## Write synfuels sector truck flow
        write_synfuels_truck_flow(settings, inputs, MESS)
        ## Write synfuels sector truck lcof
        if settings["WriteAnalysis"] == 1
            write_synfuels_truck_lcof(settings, inputs, MESS)
        end
    end

    if ModelStorage == 1
        ## Write synfuels sector storage capacities
        write_synfuels_storage_capacities(settings, inputs, MESS)

        ## Write synfuels sector storage levelized costs of storage (LCOS)
        if settings["WriteAnalysis"] == 1
            write_synfuels_storage_lcos(settings, inputs, MESS)
        end

        ## Write synfuels sector storage
        write_synfuels_storage(settings, inputs, MESS)
    end

    ## Write synfuels sector demand
    write_synfuels_demand(settings, inputs, MESS)

    ## Write synfuels sector additional demand decomposition
    write_synfuels_additional_demand_decomposition(settings, inputs, MESS)

    ## Write synfuels sector balance
    write_synfuels_balance(settings, inputs, MESS)

    ## Write synfuels sector balance shadow price and component revenues
    if haskey(MESS, :cSBalance) && LinearModel == 1
        ## Write synfuels sector balance shadow price
        write_synfuels_balance_shadow_price(settings, inputs, MESS)
        ## Write synfuels sector generator revenues
        write_synfuels_generator_revenues(settings, inputs, MESS)
        ## Write synfuels sector storage revenues
        if ModelStorage == 1
            write_synfuels_storage_revenues(settings, inputs, MESS)
        end
    end

    ## Write synfuels sector emissions
    write_synfuels_emissions(settings, inputs, MESS)

    ## Write synfuels sector captured carbon
    write_synfuels_captured_carbon(settings, inputs, MESS)

    return nothing
end
