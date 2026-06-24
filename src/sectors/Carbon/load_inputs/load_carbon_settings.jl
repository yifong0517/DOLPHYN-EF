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
function load_carbon_settings(settings::Dict)

    ## Read carbon sector settings
    print_and_log(settings, "i", "Reading Settings for Carbon Sector")

    ## Load carbon sector settings from setting file
    carbon_settings_path = joinpath(settings["SettingPath"], settings["CarbonSettings"])
    carbon_settings = YAML.load(open(carbon_settings_path))

    ## Store log settings into carbon sector settings
    carbon_settings["Log"] = settings["Log"]
    ## Store console log settings into carbon sector settings
    carbon_settings["Silent"] = settings["Silent"]

    ## Override carbon sector settings from settings
    if haskey(settings, "Carbon")
        carbon_settings = override_carbon_sector_settings(carbon_settings, settings["Carbon"])
    end

    ## Load default carbon sector settings
    carbon_settings = load_carbon_default_settings(carbon_settings)

    ## Override expansion and operation settings
    if settings["ModelMode"] == "EP"
        ## Expansion Problem (EP)
        carbon_settings["GenerationExpansion"] = 1
        carbon_settings["IncludeExistingGen"] = 0
        carbon_settings["NetworkExpansion"] = 1
        carbon_settings["IncludeExistingNetwork"] = 0
        carbon_settings["StorageExpansion"] = 1
        carbon_settings["IncludeExistingSto"] = 0
    elseif settings["ModelMode"] == "OP"
        ## Operation Problem (OP)
        carbon_settings["GenerationExpansion"] = -1
        carbon_settings["IncludeExistingGen"] = 1
        carbon_settings["NetworkExpansion"] = -1
        carbon_settings["IncludeExistingNetwork"] = 1
        carbon_settings["StorageExpansion"] = -1
        carbon_settings["IncludeExistingSto"] = 1
    elseif settings["ModelMode"] == "DD"
        ## Data Driven (DD)
        carbon_settings["GenerationExpansion"] = 0
        carbon_settings["StorageExpansion"] = 0
    end

    ## Store carbon sector carbon policy setting
    if !in(-1, settings["CO2Policy"])
        print_and_log(
            settings,
            "i",
            "Set Carbon Sector CO2Policy as Global CO2Policy $(settings["CO2Policy"])",
        )
        carbon_settings["CO2Policy"] = settings["CO2Policy"]
    end

    ## Turn on DAC when no point source capture is available
    if settings["ModelPower"] != 1 &&
       settings["ModelHydrogen"] != 1 &&
       settings["ModelSynfuels"] != 1 &&
       settings["ModelBioenergy"] != 1
        carbon_settings["ModelDAC"] = 1
        print_and_log(
            settings,
            "i",
            "Modeling Direct Air Capture Since No Point Source Capture Available",
        )
    end

    ## Carbon transport mode
    if carbon_settings["TransportMode"] == 0
        carbon_settings["SimpleTransport"] = 0
        carbon_settings["ModelPipelines"] = 0
        carbon_settings["ModelTrucks"] = 0
    elseif carbon_settings["TransportMode"] == 1
        carbon_settings["SimpleTransport"] = 1
        carbon_settings["ModelPipelines"] = 0
        carbon_settings["ModelTrucks"] = 0
    elseif carbon_settings["TransportMode"] == 2
        carbon_settings["SimpleTransport"] = 0
        carbon_settings["ModelPipelines"] = 1
        carbon_settings["ModelTrucks"] = 0
    elseif carbon_settings["TransportMode"] == 3
        carbon_settings["SimpleTransport"] = 0
        carbon_settings["ModelPipelines"] = 0
        carbon_settings["ModelTrucks"] = 1
    elseif carbon_settings["TransportMode"] == 4
        carbon_settings["SimpleTransport"] = 0
        carbon_settings["ModelPipelines"] = 1
        carbon_settings["ModelTrucks"] = 1
    end

    ## Carbon storage mode
    if !haskey(carbon_settings, "StorageOnly")
        carbon_settings["StorageOnly"] = 0
    end

    ## Store carbon sector fuels modeling setting
    carbon_settings["ModelFuels"] = settings["ModelFuels"]

    ## Store carbon sector zones list
    carbon_settings["Zones"] =
        (haskey(carbon_settings, "Zones") && !in("All", carbon_settings["Zones"])) ?
        carbon_settings["Zones"] : ["All"]

    ## Store carbon sector sub zone setting
    carbon_settings["SubZone"] =
        haskey(carbon_settings, "SubZone") &&
        carbon_settings["SubZone"] == 1 &&
        haskey(carbon_settings, "SubZoneKey")

    return carbon_settings
end
