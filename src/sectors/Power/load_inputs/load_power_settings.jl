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
function load_power_settings(settings::Dict)

    ## Read power sector settings
    print_and_log(settings, "i", "Reading Settings for Power Sector")

    ## Load power sector settings from setting file
    power_settings_path = joinpath(settings["SettingPath"], settings["PowerSettings"])
    power_settings = YAML.load(open(power_settings_path))

    ## Store log settings into power sector settings
    power_settings["Log"] = settings["Log"]
    ## Store console log settings into power sector settings
    power_settings["Silent"] = settings["Silent"]

    ## Override power sector settings from settings
    if haskey(settings, "Power")
        power_settings = override_power_sector_settings(power_settings, settings["Power"])
    end

    ## Load default power sector settings
    power_settings = load_power_default_settings(power_settings)

    ## Override expansion and operation settings
    if settings["ModelMode"] == "EP"
        ## Expansion Problem (EP)
        power_settings["GenerationExpansion"] = 1
        power_settings["IncludeExistingGen"] = 0
        power_settings["NetworkExpansion"] = 1
        power_settings["IncludeExistingNetwork"] = 0
        power_settings["StorageExpansion"] = 1
        power_settings["IncludeExistingSto"] = 0
    elseif settings["ModelMode"] == "OP"
        ## Operation Problem (OP)
        power_settings["GenerationExpansion"] = -1
        power_settings["IncludeExistingGen"] = 1
        power_settings["NetworkExpansion"] = -1
        power_settings["IncludeExistingNetwork"] = 1
        power_settings["StorageExpansion"] = -1
        power_settings["IncludeExistingSto"] = 1
    elseif settings["ModelMode"] == "DD"
        ## Data Driven (DD)
        power_settings["GenerationExpansion"] = 0
        power_settings["StorageExpansion"] = 0
    end

    ## Store power sector carbon policy setting
    if !in(-1, settings["CO2Policy"])
        print_and_log(
            settings,
            "i",
            "Set Power Sector CO2Policy as Global CO2Policy $(settings["CO2Policy"])",
        )
        power_settings["CO2Policy"] = settings["CO2Policy"]
    end

    ## Store power sector primary reserve setting
    power_settings["PReserve"] =
        haskey(power_settings, "PReserve") && power_settings["PReserve"] == 1

    ## Store power sector secondary reserve setting

    ## Store power sector energy share standard
    power_settings["EnergyShareStandard"] =
        haskey(power_settings, "EnergyShareStandard") ? power_settings["EnergyShareStandard"] : 0

    ## Store power sector fuels modeling setting
    power_settings["ModelFuels"] = settings["ModelFuels"]

    ## Store power sector carbon disposal setting
    power_settings["CO2Disposal"] =
        settings["ModelCarbon"] == 0 &&
        haskey(settings, "CO2Disposal") &&
        settings["CO2Disposal"] >= 1

    ## Store power sector zones list
    power_settings["Zones"] =
        (haskey(power_settings, "Zones") && !in("All", power_settings["Zones"])) ?
        power_settings["Zones"] : ["All"]

    ## Store power sector sub zone setting
    power_settings["SubZone"] =
        haskey(power_settings, "SubZone") &&
        power_settings["SubZone"] == 1 &&
        haskey(power_settings, "SubZoneKey")

    return power_settings
end
