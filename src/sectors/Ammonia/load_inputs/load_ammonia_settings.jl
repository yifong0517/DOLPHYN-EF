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
function load_ammonia_settings(settings::Dict)

    ## Read ammonia sector settings
    print_and_log(settings, "i", "Reading Settings for Ammonia Sector")

    ## Load ammonia sector settings from setting file
    ammonia_settings_path = joinpath(settings["SettingPath"], settings["AmmoniaSettings"])
    ammonia_settings = YAML.load(open(ammonia_settings_path))

    ## Store log settings into ammonia sector settings
    ammonia_settings["Log"] = settings["Log"]
    ## Store console log settings into ammonia sector settings
    ammonia_settings["Silent"] = settings["Silent"]

    ## Override ammonia sector settings from settings
    if haskey(settings, "Ammonia")
        ammonia_settings = override_ammonia_sector_settings(ammonia_settings, settings["Ammonia"])
    end

    ## Load default ammonia sector settings
    ammonia_settings = load_ammonia_default_settings(ammonia_settings)

    ## Override expansion and operation settings
    if settings["ModelMode"] == "EP"
        ## Expansion Problem (EP)
        ammonia_settings["GenerationExpansion"] = 1
        ammonia_settings["IncludeExistingGen"] = 0
        ammonia_settings["NetworkExpansion"] = 1
        ammonia_settings["IncludeExistingNetwork"] = 0
        ammonia_settings["StorageExpansion"] = 1
        ammonia_settings["IncludeExistingSto"] = 0
    elseif settings["ModelMode"] == "OP"
        ## Operation Problem (OP)
        ammonia_settings["GenerationExpansion"] = -1
        ammonia_settings["IncludeExistingGen"] = 1
        ammonia_settings["NetworkExpansion"] = -1
        ammonia_settings["IncludeExistingNetwork"] = 1
        ammonia_settings["StorageExpansion"] = -1
        ammonia_settings["IncludeExistingSto"] = 1
    elseif settings["ModelMode"] == "DD"
        ## Data Driven (DD)
        ammonia_settings["GenerationExpansion"] = 0
        ammonia_settings["StorageExpansion"] = 0
    end

    ## Store ammonia sector carbon policy setting
    if !in(-1, settings["CO2Policy"])
        print_and_log(
            settings,
            "i",
            "Set Ammonia Sector CO2Policy as Global CO2Policy $(settings["CO2Policy"])",
        )
        ammonia_settings["CO2Policy"] = settings["CO2Policy"]
    end

    ## Ammonia transport mode
    if ammonia_settings["TransportMode"] == 0
        ammonia_settings["SimpleTransport"] = 0
        ammonia_settings["ModelPipelines"] = 0
        ammonia_settings["ModelTrucks"] = 0
    elseif ammonia_settings["TransportMode"] == 1
        ammonia_settings["SimpleTransport"] = 1
        ammonia_settings["ModelPipelines"] = 0
        ammonia_settings["ModelTrucks"] = 0
    elseif ammonia_settings["TransportMode"] == 2
        ammonia_settings["SimpleTransport"] = 0
        ammonia_settings["ModelPipelines"] = 1
        ammonia_settings["ModelTrucks"] = 0
    elseif ammonia_settings["TransportMode"] == 3
        ammonia_settings["SimpleTransport"] = 0
        ammonia_settings["ModelPipelines"] = 0
        ammonia_settings["ModelTrucks"] = 1
    elseif ammonia_settings["TransportMode"] == 4
        ammonia_settings["SimpleTransport"] = 0
        ammonia_settings["ModelPipelines"] = 1
        ammonia_settings["ModelTrucks"] = 1
    end

    ## Store ammonia sector fuels model setting
    ammonia_settings["ModelFuels"] = settings["ModelFuels"]

    ## Store ammonia sector carbon disposal setting
    ammonia_settings["CO2Disposal"] =
        settings["ModelCarbon"] == 0 &&
        haskey(settings, "CO2Disposal") &&
        settings["CO2Disposal"] >= 1

    ## Store ammonia sector zones list
    ammonia_settings["Zones"] =
        (haskey(ammonia_settings, "Zones") && !in("All", ammonia_settings["Zones"])) ?
        ammonia_settings["Zones"] : ["All"]

    ## Store ammonia sector sub zone setting
    ammonia_settings["SubZone"] =
        haskey(ammonia_settings, "SubZone") &&
        ammonia_settings["SubZone"] == 1 &&
        haskey(ammonia_settings, "SubZoneKey")

    return ammonia_settings
end
