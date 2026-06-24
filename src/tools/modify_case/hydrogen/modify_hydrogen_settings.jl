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
function modify_hydrogen_settings(settings::Dict, modification::Dict)

    print_and_log(settings, "i", "Modifying Hydrogen Settings According to User's Modification")

    hydrogen_settings = settings["HydrogenSettings"]
    dfHydrogenSettings = hydrogen_settings["dfHydrogenSettings"]
    mkeys = collect(keys(modification))

    ## Hydrogen sector settings
    hydrogen_settings_keys = [
        "H_GenerationExpansion",
        "H_IncludeExistingGen",
        "H_GenCommit",
        "H_ModelFLH",
        "H_TransportMode",
        "H_SimpleTransport",
        "H_NetworkExpansion",
        "H_IncludeExistingNetwork",
        "H_ModelPipelines",
        "H_PipeInteger",
        "H_ModelTrucks",
        "H_TruckInteger",
        "H_ModelStorage",
        "H_StorageExpansion",
        "H_IncludeExistingSto",
        "H_AllowNse",
        "H_ScaleEffect",
        "H_MinCapacity",
        "H_MaxCapacity",
        "H_GeneratorPath",
        "H_VariabilityPath",
        "H_NetworkPath",
        "H_TrucksPath",
        "H_RoutesPath",
        "H_StoragePath",
        "H_DemandPath",
        "H_NsePath",
        "H_EmissionPath",
        "H_MinCapacityPath",
        "H_MaxCapacityPath",
        "H_DisposalPath",
        "H_SubZone",
        "H_SubZoneKey",
    ]

    ## Modify hydrogen sector settings
    for (key, value) in modification
        if key in hydrogen_settings_keys
            ## Modify hydrogen sector demand according to modification
            hydrogen_settings[split(key, "_")[2]] = value
            delete!(modification, key)
        elseif key == "H_CO2Policy" && in(-1, settings["CO2Policy"])
            if typeof(value) == Int64
                hydrogen_settings[split(key, "_")[2]] = [value]
            elseif typeof(value) <: AbstractString
                hydrogen_settings[split(key, "_")[2]] = parse.(Int64, split(value, "+"))
            end
            delete!(modification, key)
        elseif key in [
            "H_Zones",
            "H_GeneratorSet",
            "H_GeneratorIndex",
            "H_PipeSet",
            "H_TruckSet",
            "H_StorageSet",
            "H_StorageIndex",
        ]
            hydrogen_settings[split(key, "_")[2]] = [value]
            delete!(modification, key)
        end
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

    ## Update hydrogen settings origination dataframe
    hydrogen_settings_keys =
        chop.(
            intersect(
                mkeys,
                union(
                    hydrogen_settings_keys,
                    [
                        "H_CO2Policy",
                        "H_Zones",
                        "H_GeneratorSet",
                        "H_GeneratorIndex",
                        "H_LineSet",
                        "H_StorageSet",
                        "H_StorageIndex",
                    ],
                ),
            ),
            head = 2,
            tail = 0,
        )

    ## Update hydrogen settings origination dataframe
    dfHydrogenSettings = transform(
        dfHydrogenSettings,
        [:Key, :Value, :Origin] =>
            ByRow(
                (k, v, o) -> (
                    Value = k in hydrogen_settings_keys ? hydrogen_settings[k] : v,
                    Origin = k in hydrogen_settings_keys ? "user-modi" : o,
                ),
            ) => AsTable,
    )
    hydrogen_settings["dfHydrogenSettings"] = dfHydrogenSettings
    settings["HydrogenSettings"] = hydrogen_settings

    ## Store modification dict into settings for data modification
    settings["Modification"] = modification

    return settings
end
