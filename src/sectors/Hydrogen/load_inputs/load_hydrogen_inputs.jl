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
	load_hydrogen_inputs(settings::Dict, inputs::Dict)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function
"""
function load_hydrogen_inputs(settings::Dict, inputs::Dict)

    ## Read hydrogen sector settings
    if typeof(settings["HydrogenSettings"]) != String
        hydrogen_settings = settings["HydrogenSettings"]
    else
        hydrogen_settings = load_hydrogen_settings(settings)
        settings["HydrogenSettings"] = hydrogen_settings
    end

    ## Read hydrogen sector spatial inputs
    Zones = inputs["Zones"] # List of modeled zones
    if haskey(hydrogen_settings, "Zones") && !in("All", hydrogen_settings["Zones"])
        ## Exclude some zones from zone list using "!"
        excluded = filter(x -> startswith(x, "!"), hydrogen_settings["Zones"])
        included = setdiff(hydrogen_settings["Zones"], excluded)
        excluded = chop.(excluded, head = 1, tail = 0)
        ## Filter some zones from zone list using wildcard
        wildcard = filter(x -> startswith(x, "*"), hydrogen_settings["Zones"])
        included = setdiff(included, wildcard)
        wildcard = chop.(wildcard, head = 1, tail = 0)

        ## Filter some zones from zone list after exclusion
        Zones = setdiff(Zones, excluded)
        ## Filter some zones from zone list using inclusion and wildcard
        Zones = union(intersect(Zones, included), filter(x -> any(occursin.(wildcard, x)), Zones))
        if !isempty(Zones)
            print_and_log(hydrogen_settings, "i", "Using Partial Zones in Hydrogen Sector: $Zones")
        else
            print_and_log(
                hydrogen_settings,
                "w",
                "No Zones Specified for Hydrogen Sector are Found",
            )
        end
    end

    ## Read input files
    print_and_log(settings, "i", "Reading Input Files for Hydrogen Sector")

    ## Hydrogen sector data path
    path = joinpath(settings["RootPath"], settings["HydrogenInputs"])

    ## Hydrogen inputs dictionary
    hydrogen_inputs = Dict()

    ## Hydrogen sector spatial scope
    hydrogen_inputs["Zones"] = Zones
    if length(Zones) == 1 || inputs["OneZone"] == 1
        hydrogen_inputs["OneZone"] = true
        hydrogen_settings["SimpleTransport"] = 0
        hydrogen_settings["ModelPipelines"] = 0
        hydrogen_settings["ModelTrucks"] = 0
        print_and_log(
            hydrogen_settings,
            "i",
            "Disable Hydrogen Sector Transport with One Zone Modeled",
        )
    else
        hydrogen_inputs["OneZone"] = false
    end

    inputs["HydrogenInputs"] = hydrogen_inputs

    ## Read in hydrogen sector generator/resource related inputs
    inputs = load_hydrogen_generators(path, hydrogen_settings, inputs)

    ## Read in hydrogen sector generator/resource availability profiles
    inputs = load_hydrogen_generators_variability(path, hydrogen_settings, inputs)

    ## Read in hydrogen sector transport network topology and operating attributes
    if hydrogen_settings["SimpleTransport"] == 1
        inputs = load_hydrogen_routes(path, hydrogen_settings, inputs)
    end

    ## Read in hydrogen sector network topology, operating and expansion attributes
    if hydrogen_settings["ModelPipelines"] == 1
        inputs = load_hydrogen_network(path, hydrogen_settings, inputs)
    end

    ## Read in hydrogen sector truck network topology, operating and expansion attributes
    if hydrogen_settings["ModelTrucks"] == 1
        inputs = load_hydrogen_routes(path, hydrogen_settings, inputs)
        inputs = load_hydrogen_trucks(path, hydrogen_settings, inputs)
    end

    ## Read in hydrogen sector storage resources
    if hydrogen_settings["ModelStorage"] == 1
        inputs = load_hydrogen_storage(path, hydrogen_settings, inputs)
    end

    ## Read in hydrogen sector demand data
    inputs = load_hydrogen_demand(path, hydrogen_settings, inputs)

    ## Read in hydrogen sector non served demand data
    if hydrogen_settings["AllowNse"] == 1
        inputs = load_hydrogen_nse(path, hydrogen_settings, inputs)
    end

    ## Policies
    ### Emission policies
    if !in(0, hydrogen_settings["CO2Policy"])
        inputs = load_hydrogen_emission_policy(path, hydrogen_settings, inputs)
    end

    ### Minimum capacity requirements policies
    if hydrogen_settings["MinCapacity"] >= 1
        inputs = load_hydrogen_capacity_minimum(path, hydrogen_settings, inputs)
    end

    ### Maximum capacity requirements policies
    if hydrogen_settings["MaxCapacity"] >= 1
        inputs = load_hydrogen_capacity_maximum(path, hydrogen_settings, inputs)
    end

    ### Carbon disposal policies
    if hydrogen_settings["CO2Disposal"] == 1
        if settings["CO2Disposal"] == 1
            inputs = load_hydrogen_carbon_disposal(path, hydrogen_settings, inputs)
        elseif settings["CO2Disposal"] == 2
            inputs["HydrogenInputs"]["dfDisposal"] = inputs["dfDisposal"]
        end
    end

    print_and_log(settings, "i", "Input Files for Hydrogen Sector Successfully Read in from $path")

    return inputs
end
