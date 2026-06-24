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
function load_hydrogen_settings(settings::Dict)

    ## Read hydrogen sector settings
    print_and_log(settings, "i", "Reading Settings for Hydrogen Sector")

    ## Load hydrogen sector settings from setting file
    hydrogen_settings_path = joinpath(settings["SettingPath"], settings["HydrogenSettings"])
    hydrogen_settings = YAML.load(open(hydrogen_settings_path))

    ## Store log settings into hydrogen sector settings
    hydrogen_settings["Log"] = settings["Log"]
    ## Store console log settings into hydrogen sector settings
    hydrogen_settings["Silent"] = settings["Silent"]

    ## Override hydrogen sector settings from settings
    if haskey(settings, "Hydrogen")
        hydrogen_settings =
            override_hydrogen_sector_settings(hydrogen_settings, settings["Hydrogen"])
    end

    ## Load default hydrogen sector settings
    hydrogen_settings = load_hydrogen_default_settings(hydrogen_settings)

    ## Override expansion and operation settings
    if settings["ModelMode"] == "EP"
        ## Expansion Problem (EP)
        hydrogen_settings["GenerationExpansion"] = 1
        hydrogen_settings["IncludeExistingGen"] = 0
        hydrogen_settings["NetworkExpansion"] = 1
        hydrogen_settings["IncludeExistingNetwork"] = 0
        hydrogen_settings["StorageExpansion"] = 1
        hydrogen_settings["IncludeExistingSto"] = 0
    elseif settings["ModelMode"] == "OP"
        ## Operation Problem (OP)
        hydrogen_settings["GenerationExpansion"] = -1
        hydrogen_settings["IncludeExistingGen"] = 1
        hydrogen_settings["NetworkExpansion"] = -1
        hydrogen_settings["IncludeExistingNetwork"] = 1
        hydrogen_settings["StorageExpansion"] = -1
        hydrogen_settings["IncludeExistingSto"] = 1
    elseif settings["ModelMode"] == "DD"
        ## Data Driven (DD)
        hydrogen_settings["GenerationExpansion"] = 0
        hydrogen_settings["StorageExpansion"] = 0
    end

    ## Store hydrogen sector carbon policy setting
    if !in(-1, settings["CO2Policy"])
        print_and_log(
            settings,
            "i",
            "Set Hydrogen Sector CO2Policy as Global CO2Policy $(settings["CO2Policy"])",
        )
        hydrogen_settings["CO2Policy"] = settings["CO2Policy"]
    end

    ## Hydrogen transport mode
    if hydrogen_settings["TransportMode"] == 0
        hydrogen_settings["SimpleTransport"] = 0
        hydrogen_settings["ModelPipelines"] = 0
        hydrogen_settings["ModelTrucks"] = 0
    elseif hydrogen_settings["TransportMode"] == 1
        hydrogen_settings["SimpleTransport"] = 1
        hydrogen_settings["ModelPipelines"] = 0
        hydrogen_settings["ModelTrucks"] = 0
    elseif hydrogen_settings["TransportMode"] == 2
        hydrogen_settings["SimpleTransport"] = 0
        hydrogen_settings["ModelPipelines"] = 1
        hydrogen_settings["ModelTrucks"] = 0
    elseif hydrogen_settings["TransportMode"] == 3
        hydrogen_settings["SimpleTransport"] = 0
        hydrogen_settings["ModelPipelines"] = 0
        hydrogen_settings["ModelTrucks"] = 1
    elseif hydrogen_settings["TransportMode"] == 4
        hydrogen_settings["SimpleTransport"] = 0
        hydrogen_settings["ModelPipelines"] = 1
        hydrogen_settings["ModelTrucks"] = 1
    end

    ## Store hydrogen sector fuels modeling setting
    hydrogen_settings["ModelFuels"] = settings["ModelFuels"]

    ## Store hydrogen sector carbon disposal setting
    hydrogen_settings["CO2Disposal"] =
        settings["ModelCarbon"] == 0 &&
        haskey(settings, "CO2Disposal") &&
        settings["CO2Disposal"] >= 1

    ## Store hydrogen sector zones list
    hydrogen_settings["Zones"] =
        (haskey(hydrogen_settings, "Zones") && !in("All", hydrogen_settings["Zones"])) ?
        hydrogen_settings["Zones"] : ["All"]

    ## Store hydrogen sector sub zone setting
    hydrogen_settings["SubZone"] =
        haskey(hydrogen_settings, "SubZone") &&
        hydrogen_settings["SubZone"] == 1 &&
        haskey(hydrogen_settings, "SubZoneKey")

    return hydrogen_settings
end
