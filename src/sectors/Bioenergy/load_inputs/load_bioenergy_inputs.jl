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
	load_bioenergy_inputs(settings::Dict, inputs::Dict)

Loads various data inputs from multiple input .csv files in path directory and stores variables in a Dict (dictionary) object for use in model() function
"""
function load_bioenergy_inputs(settings::Dict, inputs::Dict)

    ## Read bioenergy sector settings
    if typeof(settings["BioenergySettings"]) != String
        bioenergy_settings = settings["BioenergySettings"]
    else
        bioenergy_settings = load_bioenergy_settings(settings)
        settings["BioenergySettings"] = bioenergy_settings
    end

    ## Read bioenergy sector spatial inputs
    Zones = inputs["Zones"] # List of modeled zones
    if haskey(bioenergy_settings, "Zones") && !in("All", bioenergy_settings["Zones"])
        ## Exclude some zones from zone list using "!"
        excluded = filter(x -> startswith(x, "!"), bioenergy_settings["Zones"])
        included = setdiff(bioenergy_settings["Zones"], excluded)
        excluded = chop.(excluded, head = 1, tail = 0)
        ## Filter some zones from zone list using wildcard
        wildcard = filter(x -> startswith(x, "*"), bioenergy_settings["Zones"])
        included = setdiff(included, wildcard)
        wildcard = chop.(wildcard, head = 1, tail = 0)

        ## Filter some zones from zone list after exclusion
        Zones = setdiff(Zones, excluded)
        ## Filter some zones from zone list using inclusion and wildcard
        Zones = union(intersect(Zones, included), filter(x -> any(occursin.(wildcard, x)), Zones))
        if !isempty(Zones)
            print_and_log(
                bioenergy_settings,
                "i",
                "Using Partial Zones in Bioenergy Sector: $Zones",
            )
        else
            print_and_log(
                bioenergy_settings,
                "w",
                "No Zones Specified for Bioenergy Sector are Found",
            )
        end
    end

    ## Read input files
    print_and_log(settings, "i", "Reading Input Files for Bioenergy Sector")

    ## Bioenergy sector data path
    path = joinpath(settings["RootPath"], settings["BioenergyInputs"])

    ## Bioenergy inputs dictionary
    bioenergy_inputs = Dict()

    ## Bioenergy sector spatial scope
    bioenergy_inputs["Zones"] = Zones
    if length(Zones) == 1 || inputs["OneZone"] == 1
        bioenergy_inputs["OneZone"] = true
        bioenergy_settings["ModelTrucks"] = 0
        bioenergy_settings["ResidualTransport"] = 0
        print_and_log(
            bioenergy_settings,
            "i",
            "Disable Bioenergy Sector Transport with One Zone Modeled",
        )
    else
        bioenergy_inputs["OneZone"] = false
    end

    inputs["BioenergyInputs"] = bioenergy_inputs

    ## Read in bioenergy sector residuals types
    inputs = load_bioenergy_residual_types(settings, inputs)

    if bioenergy_settings["ResidualTransport"] == 1
        inputs = load_bioenergy_routes(path, bioenergy_settings, inputs)
    end

    ## Read in bioenergy sector truck network topology, operating and expansion attributes
    if bioenergy_settings["ModelTrucks"] == 1
        print_and_log(settings, "i", "Loading Bioenergy Truck Topology with Multiple Zones Modeled")
        inputs = load_bioenergy_trucks(path, bioenergy_settings, inputs)
    else
        print_and_log(
            settings,
            "i",
            "Aborting Loading Bioenergy Truck Topology with No Network Modeled",
        )
    end

    ## Read in bioenergy sector storage resources
    if bioenergy_settings["ModelStorage"] == 1
        inputs = load_bioenergy_storage(path, bioenergy_settings, inputs)
    end

    ## Policies
    if !in(0, bioenergy_settings["CO2Policy"])
        inputs = load_bioenergy_emission_policy(path, bioenergy_settings, inputs)
    end

    print_and_log(settings, "i", "Input Files for Bioenergy Sector Successfully Read in from $path")

    return inputs
end
