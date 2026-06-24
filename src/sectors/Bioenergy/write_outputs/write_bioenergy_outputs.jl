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
function write_bioenergy_outputs(settings::Dict, inputs::Dict, MESS::Model)

    bioenergy_settings = settings["BioenergySettings"]
    path = bioenergy_settings["SavePath"]

    ## Flags
    ResidualTransport = bioenergy_settings["ResidualTransport"]
    ModelTrucks = bioenergy_settings["ModelTrucks"]
    ModelStorage = bioenergy_settings["ModelStorage"]
    LinearModel = inputs["LinearModel"]

    bioenergy_inputs = inputs["BioenergyInputs"]

    ## Check whether save path exists, if not, create it
    if !ispath(path)
        mkdir(path)
    end

    print_and_log(settings, "i", "Writing Outputs for Bioenergy Sector to $path")

    ## Write fuels consumption
    if settings["ModelFuels"] == 1
        write_bioenergy_fuels_consumption(settings, inputs, MESS)
    end

    ## Write electricity consumption
    if !(settings["ModelPower"] == 1)
        write_bioenergy_electricity_consumption(settings, inputs, MESS)
    end

    ## Write bioenergy consumption
    if !(settings["ModelHydrogen"] == 1)
        write_bioenergy_hydrogen_consumption(settings, inputs, MESS)
    end

    # ## Write bioenergy straw consumption
    # write_bioenergy_straw_consumption(settings, inputs, MESS)

    # ## Write bioenergy husk consumption
    # write_bioenergy_husk_consumption(settings, inputs, MESS)

    ## Write expenses for purchasing feedstocks from markets
    write_bioenergy_expenses(settings, inputs, MESS)

    ## Write bioenergy sector costs
    write_bioenergy_costs(settings, inputs, MESS)

    ## Write bioenergy sector residuals transport
    if ResidualTransport == 1
        write_bioenergy_transport_flow(settings, inputs, MESS)
        write_bioenergy_transport_flux(settings, inputs, MESS)
    end

    ## Write bioenergy sector transmission via trucks
    if ModelTrucks == 1
        ## Write bioenergy sector truck capacity
        write_bioenergy_truck_capacity(settings, inputs, MESS)
        ## Write bioenergy sector truck flow
        write_bioenergy_truck_flow(settings, inputs, MESS)
    end

    if ModelStorage == 1
        ## Write bioenergy sector storage
        write_bioenergy_storage(settings, inputs, MESS)

        ## Write bioenergy sector storage capacities
        write_bioenergy_storage_capacities(settings, inputs, MESS)
    end

    ## Write bioenergy sector demand
    write_bioenergy_demand(settings, inputs, MESS)

    ## Write bioenergy sector balance
    write_bioenergy_balance(settings, inputs, MESS)

    ## Write bioenergy sector emissions
    write_bioenergy_emissions(settings, inputs, MESS)

    ## Write bioenergy sector captured carbon
    write_bioenergy_captured_carbon(settings, inputs, MESS)

    return nothing
end
