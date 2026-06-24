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
function modify_synfuels_settings(settings::Dict, modification::Dict)

    print_and_log(settings, "i", "Modifying Synfuels Settings According to User's Modification")

    synfuels_settings = settings["SynfuelsSettings"]
    dfSynfuelsSettings = synfuels_settings["dfSynfuelsSettings"]
    mkeys = collect(keys(modification))

    ## Synfuels sector settings
    synfuels_settings_keys = [
        "S_GenerationExpansion",
        "S_IncludeExistingGen",
        "S_GenCommit",
        "S_ModelFLH",
        "S_TransportMode",
        "S_SimpleTransport",
        "S_NetworkExpansion",
        "S_IncludeExistingNetwork",
        "S_ModelPipelines",
        "S_PipeInteger",
        "S_ModelTrucks",
        "S_TruckInteger",
        "S_ModelStorage",
        "S_IncludeExistingSto",
        "S_StorageExpansion",
        "S_AllowNse",
        "S_ScaleEffect",
        "S_MinCapacity",
        "S_MaxCapacity",
        "S_GeneratorPath",
        "S_VariabilityPath",
        "S_NetworkPath",
        "S_TrucksPath",
        "S_RoutesPath",
        "S_StoragePath",
        "S_DemandPath",
        "S_NsePath",
        "S_EmissionPath",
        "S_MinCapacityPath",
        "S_MaxCapacityPath",
        "S_DisposalPath",
        "S_SubZone",
        "S_SubZoneKey",
    ]

    ## Modify synfuels sector settings
    for (key, value) in modification
        if key in synfuels_settings_keys
            ## Modify synfuels sector demand according to modification
            synfuels_settings[split(key, "_")[2]] = value
            delete!(modification, key)
        elseif key == "S_CO2Policy" && in(-1, settings["CO2Policy"])
            if typeof(value) == Int64
                synfuels_settings[split(key, "_")[2]] = [value]
            elseif typeof(value) <: AbstractString
                synfuels_settings[split(key, "_")[2]] = parse.(Int64, split(value, "+"))
            end
            delete!(modification, key)
        elseif key in [
            "S_Zones",
            "S_GeneratorSet",
            "S_GeneratorIndex",
            "S_PipeSet",
            "S_TruckSet",
            "S_StorageSet",
            "S_StorageIndex",
        ]
            synfuels_settings[split(key, "_")[2]] = [value]
            delete!(modification, key)
        end
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

    ## Update synfuels settings origination dataframe
    synfuels_settings_keys =
        chop.(
            intersect(
                mkeys,
                union(
                    synfuels_settings_keys,
                    ["S_CO2Policy", "S_Zones", "S_GeneratorSet", "S_LineSet", "S_StorageSet"],
                ),
            ),
            head = 2,
            tail = 0,
        )

    ## Update synfuels settings origination dataframe
    dfSynfuelsSettings = transform(
        dfSynfuelsSettings,
        [:Key, :Value, :Origin] =>
            ByRow(
                (k, v, o) -> (
                    Value = k in synfuels_settings_keys ? synfuels_settings[k] : v,
                    Origin = k in synfuels_settings_keys ? "user-modi" : o,
                ),
            ) => AsTable,
    )
    synfuels_settings["dfSynfuelsSettings"] = dfSynfuelsSettings
    settings["SynfuelsSettings"] = synfuels_settings

    ## Store modification dict into settings for data modification
    settings["Modification"] = modification

    return settings
end
