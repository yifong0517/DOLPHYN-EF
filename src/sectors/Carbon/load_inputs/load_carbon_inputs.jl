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
	load_carbon_inputs(settings::Dict, inputs::Dict)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function
"""
function load_carbon_inputs(settings::Dict, inputs::Dict)

    ## Read carbon sector settings
    if typeof(settings["CarbonSettings"]) != String
        carbon_settings = settings["CarbonSettings"]
    else
        carbon_settings = load_carbon_settings(settings)
        settings["CarbonSettings"] = carbon_settings
    end

    ## Read carbon sector spatial inputs
    Zones = inputs["Zones"] # List of modeled zones
    if haskey(carbon_settings, "Zones") && !in("All", carbon_settings["Zones"])
        ## Exclude some zones from zone list using "!"
        excluded = filter(x -> startswith(x, "!"), carbon_settings["Zones"])
        included = setdiff(carbon_settings["Zones"], excluded)
        excluded = chop.(excluded, head = 1, tail = 0)
        ## Filter some zones from zone list using wildcard
        wildcard = filter(x -> startswith(x, "*"), carbon_settings["Zones"])
        included = setdiff(included, wildcard)
        wildcard = chop.(wildcard, head = 1, tail = 0)

        ## Filter some zones from zone list after exclusion
        Zones = setdiff(Zones, excluded)
        ## Filter some zones from zone list using inclusion and wildcard
        Zones = union(intersect(Zones, included), filter(x -> any(occursin.(wildcard, x)), Zones))
        if !isempty(Zones)
            print_and_log(carbon_settings, "i", "Using Partial Zones in Carbon Sector: $Zones")
        else
            print_and_log(carbon_settings, "w", "No Zones Specified for Carbon Sector are Found")
        end
    end

    ## Read input files
    print_and_log(settings, "i", "Reading Input Files for Carbon Sector")

    ## Carbon sector data path
    path = joinpath(settings["RootPath"], settings["CarbonInputs"])

    ## Carbon inputs dictionary
    carbon_inputs = Dict()

    ## Carbon sector spatial scope
    carbon_inputs["Zones"] = Zones
    if length(Zones) == 1 || inputs["OneZone"] == 1
        carbon_inputs["OneZone"] = true
        carbon_settings["SimpleTransport"] = 0
        carbon_settings["ModelPipelines"] = 0
        carbon_settings["ModelTrucks"] = 0
        print_and_log(carbon_settings, "i", "Disable Carbon Sector Transport with One Zone Modeled")
    else
        carbon_inputs["OneZone"] = false
    end

    inputs["CarbonInputs"] = carbon_inputs

    if carbon_settings["ModelDAC"] == 1
        ## Read in carbon sector generator/resource related inputs
        inputs = load_carbon_generators(path, carbon_settings, inputs)
        ## Read in carbon sector generator/resource availability profiles
        inputs = load_carbon_generators_variability(path, carbon_settings, inputs)
    end

    ## Read in carbon sector transport network topology and operating attributes
    if carbon_settings["SimpleTransport"] == 1
        inputs = load_carbon_routes(path, carbon_settings, inputs)
    end

    ## Read in carbon sector network topology, operating and expansion attributes
    if carbon_settings["ModelPipelines"] == 1
        inputs = load_carbon_network(path, carbon_settings, inputs)
    end

    ## Read in carbon sector truck network topology, operating and expansion attributes
    if carbon_settings["ModelTrucks"] == 1
        inputs = load_carbon_routes(path, carbon_settings, inputs)
        inputs = load_carbon_trucks(path, carbon_settings, inputs)
    end

    ## Read in carbon sector storage resources
    if carbon_settings["ModelStorage"] == 1
        inputs = load_carbon_storage(path, carbon_settings, inputs)
    end

    ## Read in carbon sector demand data
    inputs = load_carbon_demand(path, carbon_settings, inputs)

    if carbon_settings["AllowNse"] == 1
        ## Read in carbon sector non served demand data
        inputs = load_carbon_nse(path, carbon_settings, inputs)
    end

    ## Policies
    if !in(0, carbon_settings["CO2Policy"])
        inputs = load_carbon_emission_policy(path, carbon_settings, inputs)
    end

    ### Minimum capacity requirements policies
    if carbon_settings["MinCapacity"] >= 1
        inputs = load_carbon_capacity_minimum(path, carbon_settings, inputs)
    end

    ### Maximum capacity requirements policies
    if carbon_settings["MaxCapacity"] >= 1
        inputs = load_carbon_capacity_maximum(path, carbon_settings, inputs)
    end

    print_and_log(settings, "i", "Input Files for Carbon Sector Successfully Read in from $path")

    return inputs
end
