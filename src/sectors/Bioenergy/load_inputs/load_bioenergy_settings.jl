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
function load_bioenergy_settings(settings::Dict)

    ## Read bioenergy sector settings
    print_and_log(settings, "i", "Reading Settings for Bioenergy Sector")

    ## Load default bioenergy sector settings
    bioenergy_settings_path = joinpath(settings["SettingPath"], settings["BioenergySettings"])
    bioenergy_settings = YAML.load(open(bioenergy_settings_path))

    ## Store log settings into bioenergy sector settings
    bioenergy_settings["Log"] = settings["Log"]
    ## Store console log settings into bioenergy sector settings
    bioenergy_settings["Silent"] = settings["Silent"]

    ## Override bioenergy sector settings from settings
    if haskey(settings, "Bioenergy")
        bioenergy_settings =
            override_bioenergy_sector_settings(bioenergy_settings, settings["Bioenergy"])
    end

    ## Load bioenergy sector default settings
    bioenergy_settings = load_bioenergy_default_settings(bioenergy_settings)

    ## Override expansion and operation settings
    if settings["ModelMode"] == "EP"
        ## Expansion Problem (EP)
        bioenergy_settings["GenerationExpansion"] = 1
        bioenergy_settings["IncludeExistingGen"] = 0
        bioenergy_settings["StorageExpansion"] = 1
        bioenergy_settings["IncludeExistingSto"] = 0
    elseif settings["ModelMode"] == "OP"
        ## Operation Problem (OP)
        bioenergy_settings["GenerationExpansion"] = -1
        bioenergy_settings["IncludeExistingGen"] = 1
        bioenergy_settings["StorageExpansion"] = -1
        bioenergy_settings["IncludeExistingSto"] = 1
    elseif settings["ModelMode"] == "DD"
        ## Data Driven (DD)
        bioenergy_settings["GenerationExpansion"] = 0
        bioenergy_settings["StorageExpansion"] = 0
    end

    ## Store bioenergy sector carbon policy setting
    if !in(-1, settings["CO2Policy"])
        print_and_log(
            settings,
            "i",
            "Set Bioenergy Sector CO2Policy as Global CO2Policy $(settings["CO2Policy"])",
        )
        bioenergy_settings["CO2Policy"] = settings["CO2Policy"]
    end

    ## Store bioenergy sector fuels modeling setting
    bioenergy_settings["ModelFuels"] = settings["ModelFuels"]

    ## Store bioenergy sector zones list
    bioenergy_settings["Zones"] =
        (haskey(bioenergy_settings, "Zones") && !in("All", bioenergy_settings["Zones"])) ?
        bioenergy_settings["Zones"] : ["All"]

    return bioenergy_settings
end
