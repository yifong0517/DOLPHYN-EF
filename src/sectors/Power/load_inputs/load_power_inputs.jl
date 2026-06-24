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
	load_power_inputs(settings::Dict, inputs::Dict)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function
"""
function load_power_inputs(settings::Dict, inputs::Dict)

    ## Read power sector settings
    if typeof(settings["PowerSettings"]) != String
        power_settings = settings["PowerSettings"]
    else
        power_settings = load_power_settings(settings)
        settings["PowerSettings"] = power_settings
    end

    ## Read power sector spatial inputs
    Zones = inputs["Zones"] # List of modeled zones
    if !in("All", power_settings["Zones"])
        ## Exclude some zones from zone list using "!"
        excluded = filter(x -> startswith(x, "!"), power_settings["Zones"])
        included = setdiff(power_settings["Zones"], excluded)
        excluded = chop.(excluded, head = 1, tail = 0)
        ## Filter some zones from zone list using wildcard
        wildcard = filter(x -> startswith(x, "*"), power_settings["Zones"])
        included = setdiff(included, wildcard)
        wildcard = chop.(wildcard, head = 1, tail = 0)

        ## Filter some zones from zone list after exclusion
        Zones = setdiff(Zones, excluded)
        ## Filter some zones from zone list using inclusion and wildcard
        Zones = union(intersect(Zones, included), filter(x -> any(occursin.(wildcard, x)), Zones))
        if !isempty(Zones)
            print_and_log(power_settings, "i", "Using Partial Zones in Power Sector: $Zones")
        else
            print_and_log(power_settings, "w", "No Zones Specified for Power Sector are Found")
        end
    end

    ## Read input files
    print_and_log(settings, "i", "Reading Inputs Files for Power Sector")

    ## Power sector data path
    path = joinpath(settings["RootPath"], settings["PowerInputs"])

    ## Power inputs dictionary
    power_inputs = Dict()

    ## Power sector spatial scope
    power_inputs["Zones"] = Zones
    if length(Zones) == 1 || inputs["OneZone"] == 1
        power_inputs["OneZone"] = true
        power_settings["ModelTransmission"] = 0
        print_and_log(
            power_settings,
            "i",
            "Disable Power Sector Transmission with One Zone Modeled",
        )
    else
        power_inputs["OneZone"] = false
    end

    inputs["PowerInputs"] = power_inputs

    ## Read in power sector generator/resource related inputs
    inputs = load_power_generators(path, power_settings, inputs)

    ## Read in power sector generator/resource availability profiles
    inputs = load_power_generators_variability(path, power_settings, inputs)

    ## Read in power sector network topology, operating and expansion attributes

    if power_settings["ModelTransmission"] == 1
        print_and_log(settings, "i", "Loading Power Network Topology with Multiple Zones Modeled")
        inputs = load_power_network(path, power_settings, inputs)
    else
        print_and_log(
            settings,
            "i",
            "Aborting Loading Power Network Topology with no Network Modeled",
        )
    end

    ## Read in power sector storage resources
    if power_settings["ModelStorage"] == 1
        inputs = load_power_storage(path, power_settings, inputs)
    end

    ## Read in power sector demand data
    inputs = load_power_demand(path, power_settings, inputs)

    ## Read in power sector non served demand data
    if power_settings["AllowNse"] >= 1
        inputs = load_power_nse(path, power_settings, inputs)
    end

    ## Policies
    ### Emission policies
    if !in(0, power_settings["CO2Policy"])
        inputs = load_power_emission_policy(path, power_settings, inputs)
    end

    ### Capacity reserve policies
    if power_settings["CapReserve"] >= 1
        inputs = load_power_capacity_reserve(path, power_settings, inputs)
    end

    ### Primary reserve policies
    if power_settings["PReserve"] == 1
        inputs = load_power_primary_reserve(path, power_settings, inputs)
    end

    ### Minimum capacity requirements policies
    if power_settings["MinCapacity"] >= 1
        inputs = load_power_capacity_minimum(path, power_settings, inputs)
    end

    ### Maximum capacity requirements policies
    if power_settings["MaxCapacity"] >= 1
        inputs = load_power_capacity_maximum(path, power_settings, inputs)
    end

    ### Energy share policies
    if power_settings["EnergyShareStandard"] >= 1
        inputs = load_power_energy_share(path, power_settings, inputs)
    end

    ### Carbon disposal policies
    if power_settings["CO2Disposal"] == 1
        if settings["CO2Disposal"] == 1
            inputs = load_power_carbon_disposal(path, power_settings, inputs)
        elseif settings["CO2Disposal"] == 2
            inputs["PowerInputs"]["dfDisposal"] = inputs["dfDisposal"]
        end
    end

    print_and_log(settings, "i", "Input Files for Power Sector Successfully Read in from $path")

    return inputs
end
