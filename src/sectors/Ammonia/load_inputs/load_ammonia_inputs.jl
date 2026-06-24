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
	load_ammonia_inputs(settings::Dict, inputs::Dict)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function
"""
function load_ammonia_inputs(settings::Dict, inputs::Dict)

    ## Read ammonia sector settings
    if typeof(settings["AmmoniaSettings"]) != String
        ammonia_settings = settings["AmmoniaSettings"]
    else
        ammonia_settings = load_ammonia_settings(settings)
        settings["AmmoniaSettings"] = ammonia_settings
    end

    ## Read ammonia sector spatial inputs
    Zones = inputs["Zones"] # List of modeled zones
    if haskey(ammonia_settings, "Zones") && !in("All", ammonia_settings["Zones"])
        ## Exclude some zones from zone list using "!"
        excluded = filter(x -> startswith(x, "!"), ammonia_settings["Zones"])
        included = setdiff(ammonia_settings["Zones"], excluded)
        excluded = chop.(excluded, head = 1, tail = 0)
        ## Filter some zones from zone list using wildcard
        wildcard = filter(x -> startswith(x, "*"), ammonia_settings["Zones"])
        included = setdiff(included, wildcard)
        wildcard = chop.(wildcard, head = 1, tail = 0)

        ## Filter some zones from zone list after exclusion
        Zones = setdiff(Zones, excluded)
        ## Filter some zones from zone list using inclusion and wildcard
        Zones = union(intersect(Zones, included), filter(x -> any(occursin.(wildcard, x)), Zones))
        if !isempty(Zones)
            print_and_log(ammonia_settings, "i", "Using Partial Zones in Ammonia Sector: $Zones")
        else
            print_and_log(ammonia_settings, "w", "No Zones Specified for Ammonia Sector are Found")
        end
    end

    ## Read input files
    print_and_log(settings, "i", "Reading Input Files for Ammonia Sector")

    ## Ammonia sector data path
    path = joinpath(settings["RootPath"], settings["AmmoniaInputs"])

    ## Ammonia inputs dictionary
    ammonia_inputs = Dict()

    ## Ammonia sector spatial scope
    ammonia_inputs["Zones"] = Zones
    if length(Zones) == 1 || inputs["OneZone"] == 1
        ammonia_inputs["OneZone"] = true
        ammonia_settings["SimpleTransport"] = 0
        ammonia_settings["ModelPipelines"] = 0
        ammonia_settings["ModelTrucks"] = 0
        print_and_log(
            ammonia_settings,
            "i",
            "Disable Ammonia Sector Transport with One Zone Modeled",
        )
    else
        ammonia_inputs["OneZone"] = false
    end

    inputs["AmmoniaInputs"] = ammonia_inputs

    ## Read in ammonia sector generator/resource related inputs
    inputs = load_ammonia_generators(path, ammonia_settings, inputs)

    ## Read in ammonia sector generator/resource availability profiles
    inputs = load_ammonia_generators_variability(path, ammonia_settings, inputs)

    ## Read in ammonia sector transport network topology and operating attributes
    if ammonia_settings["SimpleTransport"] == 1
        inputs = load_ammonia_routes(path, ammonia_settings, inputs)
    end

    ## Read in ammonia sector truck network topology, operating and expansion attributes
    if ammonia_settings["ModelTrucks"] == 1
        inputs = load_ammonia_routes(path, ammonia_settings, inputs)
        inputs = load_ammonia_trucks(path, ammonia_settings, inputs)
    end

    ## Read in ammonia sector storage resources
    if ammonia_settings["ModelStorage"] == 1
        inputs = load_ammonia_storage(path, ammonia_settings, inputs)
    end

    ## Read in ammonia sector demand data
    inputs = load_ammonia_demand(path, ammonia_settings, inputs)

    ## Read in ammonia sector non served demand data
    if ammonia_settings["AllowNse"] == 1
        inputs = load_ammonia_nse(path, ammonia_settings, inputs)
    end

    ## Policies
    ### Emission policies
    if !in(0, ammonia_settings["CO2Policy"])
        inputs = load_ammonia_emission_policy(path, ammonia_settings, inputs)
    end

    ### Minimum capacity requirements policies
    if ammonia_settings["MinCapacity"] >= 1
        inputs = load_ammonia_capacity_minimum(path, ammonia_settings, inputs)
    end

    ### Maximum capacity requirements policies
    if ammonia_settings["MaxCapacity"] >= 1
        inputs = load_ammonia_capacity_maximum(path, ammonia_settings, inputs)
    end

    ### Carbon disposal policies
    if ammonia_settings["CO2Disposal"] == 1
        if settings["CO2Disposal"] == 1
            inputs = load_ammonia_carbon_disposal(path, ammonia_settings, inputs)
        elseif settings["CO2Disposal"] == 2
            inputs["AmmoniaInputs"]["dfDisposal"] = inputs["dfDisposal"]
        end
    end

    print_and_log(settings, "i", "Input Files for Ammonia Sector Successfully Read in from $path")

    return inputs
end
