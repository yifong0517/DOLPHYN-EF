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
function write_hydrogen_outputs(settings::Dict, inputs::Dict, MESS::Model)

    hydrogen_settings = settings["HydrogenSettings"]
    path = hydrogen_settings["SavePath"]
    SubZone = hydrogen_settings["SubZone"]
    SimpleTransport = hydrogen_settings["SimpleTransport"]
    ModelPipelines = hydrogen_settings["ModelPipelines"]
    NetworkExpansion = hydrogen_settings["NetworkExpansion"]
    ModelTrucks = hydrogen_settings["ModelTrucks"]
    ModelStorage = hydrogen_settings["ModelStorage"]

    LinearModel = inputs["LinearModel"]

    hydrogen_inputs = inputs["HydrogenInputs"]
    COMMIT = hydrogen_inputs["COMMIT"]

    ## Check whether save path exists, if not, create it
    if !ispath(path)
        mkdir(path)
    end

    print_and_log(settings, "i", "Writing Outputs for Hydrogen Sector to $path")

    ## Write fuels consumption
    if settings["ModelFuels"] == 1
        write_hydrogen_fuels_consumption(settings, inputs, MESS)
    end

    ## Write electricity consumption
    if !(settings["ModelPower"] == 1)
        write_hydrogen_electricity_consumption(settings, inputs, MESS)
    end

    ## Write carbon consumption
    if !(settings["ModelCarbon"] == 1)
        write_hydrogen_carbon_consumption(settings, inputs, MESS)
    end

    ## Write bioenergy consumption
    if !(settings["ModelBioenergy"] == 1)
        write_hydrogen_bioenergy_consumption(settings, inputs, MESS)
    end

    ## Write expenses for purchasing feedstocks from markets
    write_hydrogen_expenses(settings, inputs, MESS)

    ## Write hydrogen sector costs
    write_hydrogen_costs(settings, inputs, MESS)

    ## Write hydrogen sector generation
    write_hydrogen_generation(settings, inputs, MESS)

    ## Write hydrogen sector generation capacities
    write_hydrogen_generation_capacities(settings, inputs, MESS)

    ## Write hydrogen sector generation capacity factor
    write_hydrogen_generation_capacity_factor(settings, inputs, MESS)

    ## Write hydrogen sector generation lcoh
    if settings["WriteAnalysis"] == 1
        write_hydrogen_generation_lcoh(settings, inputs, MESS)
    end

    ## Write hydrogen sector generation by fuel
    write_hydrogen_generation_composition(settings, inputs, MESS)

    ## Write hydrogen sector generation in each sub zone
    if SubZone == 1
        write_hydrogen_generation_sub_zonal(settings, inputs, MESS)
        write_hydrogen_generation_composition_sub_zonal(settings, inputs, MESS)
    end

    ## Write hydrogen sector commits
    if !isempty(COMMIT)
        write_hydrogen_commit(settings, inputs, MESS)
    end

    ## Write hydrogen sector simple transport
    if SimpleTransport == 1
        write_hydrogen_transport_flow(settings, inputs, MESS)
        write_hydrogen_transport_flux(settings, inputs, MESS)
    end

    ## Write hydrogen sector transmission via pipelines
    if ModelPipelines == 1
        if NetworkExpansion != -1
            ## Write hydrogen sector pipeline expansion
            write_hydrogen_pipe_expansion(settings, inputs, MESS)
        end
        ## Write hydrogen sector pipeline flow
        write_hydrogen_pipe_flow(settings, inputs, MESS)
        ## Write hydrogen sector pipeline lcoh
        if settings["WriteAnalysis"] == 1
            write_hydrogen_pipe_lcoh(settings, inputs, MESS)
        end
    end

    ## Write hydrogen sector transmission via trucks
    if ModelTrucks == 1
        ## Write hydrogen sector truck capacity
        write_hydrogen_truck_capacity(settings, inputs, MESS)
        ## Write hydrogen sector truck flow
        write_hydrogen_truck_flow(settings, inputs, MESS)
        ## Write hydrogen sector truck lcoh
        if settings["WriteAnalysis"] == 1
            write_hydrogen_truck_lcoh(settings, inputs, MESS)
        end
    end

    if ModelStorage == 1
        ## Write hydrogen sector storage capacities
        write_hydrogen_storage_capacities(settings, inputs, MESS)

        ## Write hydrogen sector storage levelized costs of storage (LCOS)
        if settings["WriteAnalysis"] == 1
            write_hydrogen_storage_lcos(settings, inputs, MESS)
        end

        ## Write hydrogen sector storage
        write_hydrogen_storage(settings, inputs, MESS)
    end

    ## Write hydrogen sector demand
    write_hydrogen_demand(settings, inputs, MESS)

    ## Write hydrogen sector additional demand decomposition
    write_hydrogen_additional_demand_decomposition(settings, inputs, MESS)

    ## Write hydrogen sector balance
    write_hydrogen_balance(settings, inputs, MESS)

    ## Write hydrogen sector balance shadow price and component revenues
    if haskey(MESS, :cHBalance) && LinearModel == 1
        ## Write hydrogen sector balance shadow price
        write_hydrogen_balance_shadow_price(settings, inputs, MESS)
        ## Write hydrogen sector generator revenues
        write_hydrogen_generator_revenues(settings, inputs, MESS)
        ## Write hydrogen sector storage revenues
        if ModelStorage == 1
            write_hydrogen_storage_revenues(settings, inputs, MESS)
        end
    end

    ## Write hydrogen sector emissions
    write_hydrogen_emissions(settings, inputs, MESS)

    ## Write hydrogen sector captured carbon
    write_hydrogen_captured_carbon(settings, inputs, MESS)

    return nothing
end
