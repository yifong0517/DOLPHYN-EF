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
function write_carbon_outputs(settings::Dict, inputs::Dict, MESS::Model)

    carbon_settings = settings["CarbonSettings"]
    path = carbon_settings["SavePath"]
    SubZone = carbon_settings["SubZone"]
    ModelDAC = carbon_settings["ModelDAC"]
    SimpleTransport = carbon_settings["SimpleTransport"]
    ModelPipelines = carbon_settings["ModelPipelines"]
    NetworkExpansion = carbon_settings["NetworkExpansion"]
    ModelTrucks = carbon_settings["ModelTrucks"]
    ModelStorage = carbon_settings["ModelStorage"]

    LinearModel = inputs["LinearModel"]

    carbon_inputs = inputs["CarbonInputs"]
    if ModelDAC == 1
        THERM_COMMIT = carbon_inputs["THERM_COMMIT"]
    end

    ## Check whether save path exists, if not, create it
    if !ispath(path)
        mkdir(path)
    end

    print_and_log(settings, "i", "Writing Outputs for Carbon Sector to $path")

    ## Write fuels consumption
    if settings["ModelFuels"] == 1
        write_carbon_fuels_consumption(settings, inputs, MESS)
    end

    ## Write electricity consumption
    if !(settings["ModelPower"] == 1)
        write_carbon_electricity_consumption(settings, inputs, MESS)
    end

    ## Write carbon consumption
    if !(settings["ModelHydrogen"] == 1)
        write_carbon_hydrogen_consumption(settings, inputs, MESS)
    end

    ## Write bioenergy consumption
    if !(settings["ModelBioenergy"] == 1)
        write_carbon_bioenergy_consumption(settings, inputs, MESS)
    end

    ## Write expenses for purchasing feedstocks from markets
    write_carbon_expenses(settings, inputs, MESS)

    ## Write carbon sector costs
    write_carbon_costs(settings, inputs, MESS)

    if ModelDAC == 1
        ## Write carbon sector generation
        write_carbon_capture(settings, inputs, MESS)

        ## Write carbon sector capture capacities
        write_carbon_capture_capacities(settings, inputs, MESS)

        ## Write carbon sector capture capacity factor
        write_carbon_capture_capacity_factor(settings, inputs, MESS)

        ## Write carbon sector capture lcoc
        if settings["WriteAnalysis"] == 1
            write_carbon_capture_lcoc(settings, inputs, MESS)
        end

        ## Write carbon sector capture in each sub zone
        if SubZone == 1
            write_carbon_capture_sub_zonal(settings, inputs, MESS)
        end

        if !isempty(THERM_COMMIT)
            ## Write carbon sector commits
            write_carbon_commit(settings, inputs, MESS)
        end
    end

    ## Write carbon sector simple transport
    if SimpleTransport == 1
        write_carbon_transport_flow(settings, inputs, MESS)
        write_carbon_transport_flux(settings, inputs, MESS)
    end

    ## Write carbon sector transmission via pipelines
    if ModelPipelines == 1
        if NetworkExpansion != -1
            ## Write carbon sector pipeline expansion
            write_carbon_pipe_expansion(settings, inputs, MESS)
        end
        ## Write carbon sector pipeline flow
        write_carbon_pipe_flow(settings, inputs, MESS)
        ## Write carbon sector pipeline lcoc
        if settings["WriteAnalysis"] == 1
            write_carbon_pipe_lcoc(settings, inputs, MESS)
        end
    end

    ## Write carbon sector transmission via trucks
    if ModelTrucks == 1
        ## Write carbon sector truck capacity
        write_carbon_truck_capacity(settings, inputs, MESS)
        ## Write carbon sector truck flow
        write_carbon_truck_flow(settings, inputs, MESS)
        ## Write carbon sector truck lcoc
        if settings["WriteAnalysis"] == 1
            write_carbon_truck_lcoc(settings, inputs, MESS)
        end
    end

    if ModelStorage == 1
        ## Write carbon sector storage capacities
        write_carbon_storage_capacities(settings, inputs, MESS)

        ## Write carbon sector storage levelized costs of storage (LCOS)
        if settings["WriteAnalysis"] == 1
            write_carbon_storage_lcos(settings, inputs, MESS)
        end

        ## Write carbon sector storage
        write_carbon_storage(settings, inputs, MESS)
    end

    ## Write carbon sector demand
    write_carbon_demand(settings, inputs, MESS)

    ## Write carbon sector additional demand decomposition
    write_carbon_additional_demand_decomposition(settings, inputs, MESS)

    ## Write carbon sector balance
    write_carbon_balance(settings, inputs, MESS)

    ## Write carbon sector balance shadow price and component revenues
    if haskey(MESS, :cCBalance) && LinearModel == 1
        ## Write carbon sector balance shadow price
        write_carbon_balance_shadow_price(settings, inputs, MESS)
        ## Write carbon sector capture revenues
        write_carbon_capture_revenues(settings, inputs, MESS)
        ## Write carbon sector storage revenues
        if ModelStorage == 1
            write_carbon_storage_revenues(settings, inputs, MESS)
        end
    end

    ## Write carbon sector emissions
    write_carbon_emissions(settings, inputs, MESS)

    ## Write carbon sector captured carbon
    write_carbon_captured_carbon(settings, inputs, MESS)

    ## Write carbon sector net emissions
    write_carbon_net_emissions(settings, inputs, MESS)

    return nothing
end
