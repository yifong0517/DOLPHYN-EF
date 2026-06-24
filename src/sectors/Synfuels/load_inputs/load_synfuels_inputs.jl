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
	load_synfuels_inputs(settings::Dict, inputs::Dict)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function
"""
function load_synfuels_inputs(settings::Dict, inputs::Dict)

    ## Read synfuels sector settings
    if typeof(settings["SynfuelsSettings"]) != String
        synfuels_settings = settings["SynfuelsSettings"]
    else
        synfuels_settings = load_synfuels_settings(settings)
        settings["SynfuelsSettings"] = synfuels_settings
    end

    ## Read synfuels sector spatial inputs
    Zones = inputs["Zones"] # List of modeled zones
    if haskey(synfuels_settings, "Zones") && !in("All", synfuels_settings["Zones"])
        ## Exclude some zones from zone list using "!"
        excluded = filter(x -> startswith(x, "!"), synfuels_settings["Zones"])
        included = setdiff(synfuels_settings["Zones"], excluded)
        excluded = chop.(excluded, head = 1, tail = 0)
        ## Filter some zones from zone list using wildcard
        wildcard = filter(x -> startswith(x, "*"), synfuels_settings["Zones"])
        included = setdiff(included, wildcard)
        wildcard = chop.(wildcard, head = 1, tail = 0)

        ## Filter some zones from zone list after exclusion
        Zones = setdiff(Zones, excluded)
        ## Filter some zones from zone list using inclusion and wildcard
        Zones = union(intersect(Zones, included), filter(x -> any(occursin.(wildcard, x)), Zones))
        if !isempty(Zones)
            print_and_log(synfuels_settings, "i", "Using Partial Zones in Synfuels Sector: $Zones")
        else
            print_and_log(
                synfuels_settings,
                "w",
                "No Zones Specified for Synfuels Sector are Found",
            )
        end
    end

    ## Read input files
    print_and_log(settings, "i", "Reading Input Files for Synfuels Sector")

    ## Synfuels sector data path
    path = joinpath(settings["RootPath"], settings["SynfuelsInputs"])

    ## Synfuels inputs dictionary
    synfuels_inputs = Dict()

    ## Synfuels sector spatial scope
    synfuels_inputs["Zones"] = Zones
    if length(Zones) == 1 || inputs["OneZone"] == 1
        synfuels_inputs["OneZone"] = true
        synfuels_settings["SimpleTransport"] = 0
        synfuels_settings["ModelPipelines"] = 0
        synfuels_settings["ModelTrucks"] = 0
        print_and_log(
            synfuels_settings,
            "i",
            "Disable Synfuels Sector Transport with One Zone Modeled",
        )
    else
        synfuels_inputs["OneZone"] = false
    end

    inputs["SynfuelsInputs"] = synfuels_inputs

    ## Read in synfuels sector generator/resource related inputs
    inputs = load_synfuels_generators(path, synfuels_settings, inputs)

    ## Read in synfuels sector generator/resource availability profiles
    inputs = load_synfuels_generators_variability(path, synfuels_settings, inputs)

    ## Read in synfuels sector transport network topology and operating attributes
    if synfuels_settings["SimpleTransport"] == 1
        inputs = load_synfuels_routes(path, synfuels_settings, inputs)
    end

    ## Read in synfuels sector network topology, operating and expansion attributes
    if synfuels_settings["ModelPipelines"] == 1
        inputs = load_synfuels_network(path, synfuels_settings, inputs)
    end

    ## Read in synfuels sector truck network topology, operating and expansion attributes
    if synfuels_settings["ModelTrucks"] == 1
        inputs = load_synfuels_routes(path, synfuels_settings, inputs)
        inputs = load_synfuels_trucks(path, synfuels_settings, inputs)
    end

    ## Read in synfuels sector storage resources
    if synfuels_settings["ModelStorage"] == 1
        inputs = load_synfuels_storage(path, synfuels_settings, inputs)
    end

    ## Read in synfuels sector demand data
    inputs = load_synfuels_demand(path, synfuels_settings, inputs)

    ## Read in synfuels sector non served demand data
    if synfuels_settings["AllowNse"] == 1
        inputs = load_synfuels_nse(path, synfuels_settings, inputs)
    end

    ## Policies
    ### Emission policies
    if !in(0, synfuels_settings["CO2Policy"])
        inputs = load_synfuels_emission_policy(path, synfuels_settings, inputs)
    end

    ### Minimum capacity requirements policies
    if synfuels_settings["MinCapacity"] >= 1
        inputs = load_synfuels_capacity_minimum(path, synfuels_settings, inputs)
    end

    ### Maximum capacity requirements policies
    if synfuels_settings["MaxCapacity"] >= 1
        inputs = load_synfuels_capacity_maximum(path, synfuels_settings, inputs)
    end

    ### Carbon disposal policies
    if synfuels_settings["CO2Disposal"] == 1
        if settings["CO2Disposal"] == 1
            inputs = load_synfuels_Synfuels_disposal(path, synfuels_settings, inputs)
        elseif settings["CO2Disposal"] == 2
            inputs["SynfuelsInputs"]["dfDisposal"] = inputs["dfDisposal"]
        end
    end

    print_and_log(settings, "i", "Input Files for Synfuels Sector Successfully Read in from $path")

    return inputs
end
