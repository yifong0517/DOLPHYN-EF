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
function modify_power_settings(settings::Dict, modification::Dict)

    print_and_log(settings, "i", "Modifying Power Settings According to User's Modification")

    power_settings = settings["PowerSettings"]
    dfPowerSettings = power_settings["dfPowerSettings"]
    mkeys = collect(keys(modification))

    ## Power sector settings
    power_settings_keys = [
        "P_GenerationExpansion",
        "P_IncludeExistingGen",
        "P_UCommit",
        "P_ModelTransmission",
        "P_NetworkExpansion",
        "P_IncludeExistingNetwork",
        "P_LineLossSegments",
        "P_DCPowerFlow",
        "P_ModelStorage",
        "P_StorageExpansion",
        "P_IncludeExistingSto",
        "P_BatteryAging",
        "P_AllowNse",
        "P_ScaleEffect",
        "P_CapReserve",
        "P_MinCapacity",
        "P_MaxCapacity",
        "P_EnergyShareStandard",
        "P_GeneratorPath",
        "P_VariabilityPath",
        "P_NetworkPath",
        "P_StoragePath",
        "P_DemandPath",
        "P_NsePath",
        "P_EmissionPath",
        "P_CapReservePath",
        "P_MinCapacityPath",
        "P_MaxCapacityPath",
        "P_EnergySharePath",
        "P_DisposalPath",
        "P_SubZone",
        "P_SubZoneKey",
    ]

    ## Modify power sector settings
    for (key, value) in modification
        if key in power_settings_keys
            ## Modify power sector demand according to modification
            power_settings[split(key, "_")[2]] = value
            delete!(modification, key)
        elseif key == "P_CO2Policy" && in(-1, settings["CO2Policy"])
            if typeof(value) == Int64
                power_settings[split(key, "_")[2]] = [value]
            elseif typeof(value) <: AbstractString
                power_settings[split(key, "_")[2]] = parse.(Int64, split(value, "+"))
            end
            delete!(modification, key)
        elseif key in ["PReserve", "ReservePath"]
            power_settings[key] = value
        elseif key in [
            "P_Zones",
            "P_GeneratorSet",
            "P_GeneratorIndex",
            "P_LineSet",
            "P_StorageSet",
            "P_StorageIndex",
        ]
            power_settings[split(key, "_")[2]] = [value]
            delete!(modification, key)
        end
    end

    ## Update power settings origination dataframe
    power_settings_keys = vcat(
        chop.(
            intersect(
                mkeys,
                union(
                    power_settings_keys,
                    [
                        "P_CO2Policy",
                        "P_Zones",
                        "P_GeneratorSet",
                        "P_GeneratorIndex",
                        "P_LineSet",
                        "P_StorageSet",
                        "P_StorageIndex",
                    ],
                ),
            ),
            head = 2,
            tail = 0,
        ),
        intersect(mkeys, ["PReserve", "ReservePath"]),
    )

    ## Update power settings origination dataframe
    dfPowerSettings = transform(
        dfPowerSettings,
        [:Key, :Value, :Origin] =>
            ByRow(
                (k, v, o) -> (
                    Value = k in power_settings_keys ? power_settings[k] : v,
                    Origin = k in power_settings_keys ? "user-modi" : o,
                ),
            ) => AsTable,
    )
    power_settings["dfPowerSettings"] = dfPowerSettings
    settings["PowerSettings"] = power_settings

    ## Store modification dict into settings for data modification
    settings["Modification"] = modification

    return settings
end
