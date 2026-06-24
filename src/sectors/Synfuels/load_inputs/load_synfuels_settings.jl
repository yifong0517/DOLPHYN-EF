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
function load_synfuels_settings(settings::Dict)

    ## Read synfuels sector settings
    print_and_log(settings, "i", "Reading Settings for Synfuels Sector")

    ## Load synfuels sector settings from setting file
    synfuels_settings_path = joinpath(settings["SettingPath"], settings["SynfuelsSettings"])
    synfuels_settings = YAML.load(open(synfuels_settings_path))

    ## Store log settings into synfuels sector settings
    synfuels_settings["Log"] = settings["Log"]
    ## Store console log settings into synfuels sector settings
    synfuels_settings["Silent"] = settings["Silent"]

    ## Override synfuels sector settings from settings
    if haskey(settings, "Synfuels")
        synfuels_settings =
            override_synfuels_sector_settings(synfuels_settings, settings["Synfuels"])
    end

    ## Load default synfuels sector settings
    synfuels_settings = load_synfuels_default_settings(synfuels_settings)

    ## Override expansion and operation settings
    if settings["ModelMode"] == "EP"
        ## Expansion Problem (EP)
        synfuels_settings["GenerationExpansion"] = 1
        synfuels_settings["IncludeExistingGen"] = 0
        synfuels_settings["NetworkExpansion"] = 1
        synfuels_settings["IncludeExistingNetwork"] = 0
        synfuels_settings["StorageExpansion"] = 1
        synfuels_settings["IncludeExistingSto"] = 0
    elseif settings["ModelMode"] == "OP"
        ## Operation Problem (OP)
        synfuels_settings["GenerationExpansion"] = -1
        synfuels_settings["IncludeExistingGen"] = 1
        synfuels_settings["NetworkExpansion"] = -1
        synfuels_settings["IncludeExistingNetwork"] = 1
        synfuels_settings["StorageExpansion"] = -1
        synfuels_settings["IncludeExistingSto"] = 1
    elseif settings["ModelMode"] == "DD"
        ## Data Driven (DD)
        synfuels_settings["GenerationExpansion"] = 0
        synfuels_settings["StorageExpansion"] = 0
    end

    ## Store synfuels sector carbon policy setting
    if !in(-1, settings["CO2Policy"])
        print_and_log(
            settings,
            "i",
            "Set Synfuels Sector CO2Policy as Global CO2Policy $(settings["CO2Policy"])",
        )
        synfuels_settings["CO2Policy"] = settings["CO2Policy"]
    end

    ## Synfuels transport mode
    if synfuels_settings["TransportMode"] == 0
        synfuels_settings["SimpleTransport"] = 0
        synfuels_settings["ModelPipelines"] = 0
        synfuels_settings["ModelTrucks"] = 0
    elseif synfuels_settings["TransportMode"] == 1
        synfuels_settings["SimpleTransport"] = 1
        synfuels_settings["ModelPipelines"] = 0
        synfuels_settings["ModelTrucks"] = 0
    elseif synfuels_settings["TransportMode"] == 2
        synfuels_settings["SimpleTransport"] = 0
        synfuels_settings["ModelPipelines"] = 1
        synfuels_settings["ModelTrucks"] = 0
    elseif synfuels_settings["TransportMode"] == 3
        synfuels_settings["SimpleTransport"] = 0
        synfuels_settings["ModelPipelines"] = 0
        synfuels_settings["ModelTrucks"] = 1
    elseif synfuels_settings["TransportMode"] == 4
        synfuels_settings["SimpleTransport"] = 0
        synfuels_settings["ModelPipelines"] = 1
        synfuels_settings["ModelTrucks"] = 1
    end

    ## Store synfuels sector fuels modeling setting
    synfuels_settings["ModelFuels"] = settings["ModelFuels"]

    ## Store synfuels sector carbon disposal setting
    synfuels_settings["CO2Disposal"] =
        settings["ModelCarbon"] == 0 &&
        haskey(settings, "CO2Disposal") &&
        settings["CO2Disposal"] >= 1

    ## Store synfuels sector zones list
    synfuels_settings["Zones"] =
        (haskey(synfuels_settings, "Zones") && !in("All", synfuels_settings["Zones"])) ?
        synfuels_settings["Zones"] : ["All"]

    ## Store synfuels sector sub zone setting
    synfuels_settings["SubZone"] =
        haskey(synfuels_settings, "SubZone") &&
        synfuels_settings["SubZone"] == 1 &&
        haskey(synfuels_settings, "SubZoneKey")

    return synfuels_settings
end
