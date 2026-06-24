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
function load_external_inputs(settings::Dict, inputs::Dict)

    print_and_log(
        settings,
        "i",
        "Loading Multi Energy System External Resources Price and Availability",
    )

    ## Resources settings
    resources = settings["ResourceSettings"]

    resources_data_path = joinpath(settings["RootPath"], settings["ResourceInputs"])

    ## Store flags for resource signals
    flags = Dict()

    ## Load common fuels prices ($/MMBtu) and carbon intensity (tonne-CO2/MMBtu)
    if settings["ModelFuels"] == 1
        fuels_price_path = joinpath(resources_data_path, resources["FuelPath"])
        if isfile(fuels_price_path)
            inputs = load_fuels_prices(fuels_price_path, settings, inputs)
            flags["FuelsPrice"] = 1
        end
    end
    ## Load common fuels availability
    if settings["ModelFuels"] == 1 && settings["ResourceAvailability"] == 1
        fuels_availability_path = joinpath(resources_data_path, resources["FuelsAvailabilityPath"])
        if isfile(fuels_availability_path)
            inputs = load_fuels_availability(fuels_availability_path, settings, inputs)
            flags["FuelsAvailability"] = 1
        end
    end
    if !(settings["ModelFuels"] == 1)
        print_and_log(settings, "w", "Fuel Prices and Availability Will not be Loaded and Modeled")
    end

    ## Load grid electricity prices ($/MW)
    if !(settings["ModelPower"] == 1)
        electricity_prices_path = joinpath(resources_data_path, resources["ElectricityPath"])
        if isfile(electricity_prices_path)
            inputs = load_electricity_prices(electricity_prices_path, settings, inputs)
            flags["ElectricityPrice"] = 1
        end
    end
    ## Load electricity availability
    if !(settings["ModelPower"] == 1) && settings["ResourceAvailability"] == 1
        electricity_availability_path =
            joinpath(resources_data_path, prices["ElectricityAvailabilityPath"])
        if isfile(electricity_availability_path)
            inputs = load_electricity_availability(electricity_availability_path, settings, inputs)
            flags["ElectricityAvailability"] = 1
        end
    end

    ## Load dedicated hydrogen prices ($/tonne-H2)
    if !(settings["ModelHydrogen"] == 1)
        hydrogen_price_path = joinpath(resources_data_path, resources["HydrogenPath"])
        if isfile(hydrogen_price_path)
            inputs = load_hydrogen_prices(hydrogen_price_path, settings, inputs)
            flags["HydrogenPrice"] = 1
        end
    end
    ## Load hydrogen availability
    if !(settings["ModelHydrogen"] == 1) && settings["ResourceAvailability"] == 1
        hydrogen_availability_path =
            joinpath(resources_data_path, resources["HydrogenAvailabilityPath"])
        if isfile(hydrogen_availability_path)
            inputs = load_hydrogen_availability(hydrogen_availability_path, settings, inputs)
            flags["HydrogenAvailability"] = 1
        end
    end

    ## Load carbon prices from policy ($/tonne-CO2)
    if !(settings["ModelCarbon"] == 1)
        carbon_price_path = joinpath(resources_data_path, resources["CarbonPath"])
        if isfile(carbon_price_path)
            inputs = load_carbon_prices(carbon_price_path, settings, inputs)
            flags["CarbonPrice"] = 1
        end
    end
    ## Load carbon availability
    if !(settings["ModelCarbon"] == 1) && settings["ResourceAvailability"] == 1
        carbon_availability_path =
            joinpath(resources_data_path, resources["CarbonAvailabilityPath"])
        if isfile(carbon_availability_path)
            inputs = load_carbon_availability(carbon_availability_path, settings, inputs)
            flags["CarbonAvailability"] = 1
        end
    end

    ## Load solid bioenergy prices ($/MMBtu)
    if !(settings["ModelBioenergy"] == 1)
        bioenergy_price_path = joinpath(resources_data_path, resources["BioenergyPath"])
        if isfile(bioenergy_price_path)
            inputs = load_bioenergy_prices(bioenergy_price_path, settings, inputs)
            flags["BioenergyPrice"] = 1
        end
    end
    ## Load bioenergy availability
    if !(settings["ModelBioenergy"] == 1) && settings["ResourceAvailability"] == 1
        bioenergy_availability_path =
            joinpath(resources_data_path, resources["BioenergyAvailabilityPath"])
        if isfile(bioenergy_availability_path)
            inputs = load_bioenergy_availability(bioenergy_availability_path, settings, inputs)
            flags["BioenergyAvailability"] = 1
        end
    end

    ## Load carbon disposal prices including transmission and storage when carbon sector is not modeled and carbon disposal is modeled
    if settings["ModelCarbon"] == 0 &&
       haskey(settings, "CO2Disposal") &&
       settings["CO2Disposal"] == 2
        carbon_disposal_path = joinpath(resources_data_path, resources["DisposalPath"])
        if isfile(carbon_disposal_path)
            inputs = load_disposal_prices(carbon_disposal_path, settings, inputs)
            flags["Disposal"] = 1
        end
    end

    ## Store price signals flags
    inputs["ResourceFlags"] = flags

    return inputs
end
