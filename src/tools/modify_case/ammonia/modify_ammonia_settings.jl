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
function modify_ammonia_settings(settings::Dict, modification::Dict)

    print_and_log(settings, "i", "Modifying Ammonia Settings According to User's Modification")

    ammonia_settings = settings["AmmoniaSettings"]
    dfAmmoniaSettings = ammonia_settings["dfAmmoniaSettings"]
    mkeys = collect(keys(modification))

    ## Ammonia sector settings
    ammonia_settings_keys = [
        "A_GenerationExpansion",
        "A_IncludeExistingGen",
        "A_GenCommit",
        "A_ModelFLH",
        "A_TransportMode",
        "A_SimpleTransport",
        "A_NetworkExpansion",
        "A_ModelTrucks",
        "A_TruckInteger",
        "A_ModelStorage",
        "A_IncludeExistingSto",
        "A_StorageExpansion",
        "A_AllowNse",
        "A_ScaleEffect",
        "A_MinCapacity",
        "A_MaxCapacity",
        "A_GeneratorPath",
        "A_VariabilityPath",
        "A_TrucksPath",
        "A_RoutesPath",
        "A_StoragePath",
        "A_DemandPath",
        "A_NsePath",
        "A_EmissionPath",
        "A_MinCapacityPath",
        "A_MaxCapacityPath",
        "A_DisposalPath",
        "A_SubZone",
        "A_SubZoneKey",
    ]

    ## Modify ammonia sector settings
    for (key, value) in modification
        if key in ammonia_settings_keys
            ## Modify ammonia sector demand according to modification
            ammonia_settings[split(key, "_")[2]] = value
            delete!(modification, key)
        elseif key == "A_CO2Policy" && in(-1, settings["CO2Policy"])
            if typeof(value) == Int64
                ammonia_settings[split(key, "_")[2]] = [value]
            elseif typeof(value) <: AbstractString
                ammonia_settings[split(key, "_")[2]] = parse.(Int64, split(value, "+"))
            end
            delete!(modification, key)
        elseif key in [
            "A_Zones",
            "A_GeneratorSet",
            "A_GeneratorIndex",
            "A_TruckSet",
            "A_StorageSet",
            "A_StorageIndex",
        ]
            ammonia_settings[split(key, "_")[2]] = [value]
            delete!(modification, key)
        end
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

    ## Update ammonia settings origination dataframe
    ammonia_settings_keys =
        chop.(
            intersect(
                mkeys,
                union(
                    ammonia_settings_keys,
                    [
                        "A_CO2Policy",
                        "A_Zones",
                        "A_GeneratorSet",
                        "A_GeneratorIndex",
                        "A_LineSet",
                        "A_StorageSet",
                        "A_StorageIndex",
                    ],
                ),
            ),
            head = 2,
            tail = 0,
        )

    ## Update ammonia settings origination dataframe
    dfAmmoniaSettings = transform(
        dfAmmoniaSettings,
        [:Key, :Value, :Origin] =>
            ByRow(
                (k, v, o) -> (
                    Value = k in ammonia_settings_keys ? ammonia_settings[k] : v,
                    Origin = k in ammonia_settings_keys ? "user-modi" : o,
                ),
            ) => AsTable,
    )
    ammonia_settings["dfAmmoniaSettings"] = dfAmmoniaSettings
    settings["AmmoniaSettings"] = ammonia_settings

    ## Store modification dict into settings for data modification
    settings["Modification"] = modification

    return settings
end
