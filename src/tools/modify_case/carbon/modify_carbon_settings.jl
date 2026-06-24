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
function modify_carbon_settings(settings::Dict, modification::Dict)

    print_and_log(settings, "i", "Modifying Carbon Settings According to User's Modification")

    carbon_settings = settings["CarbonSettings"]
    dfCarbonSettings = carbon_settings["dfCarbonSettings"]
    mkeys = collect(keys(modification))

    ## Carbon sector settings
    carbon_settings_keys = [
        "C_ModelDAC",
        "C_CaptureExpansion",
        "C_IncludeExistingCap",
        "C_CapCommit",
        "C_ModelFLH",
        "C_DACOnly",
        "C_TransportMode",
        "C_SimpleTransport",
        "C_NetworkExpansion",
        "C_IncludeExistingNetwork",
        "C_ModelPipelines",
        "C_PipeInteger",
        "C_ModelTrucks",
        "C_TruckInteger",
        "C_ModelStorage",
        "C_StorageExpansion",
        "C_IncludeExistingSto",
        "C_StorageOnly",
        "C_AllowDis",
        "C_AllowNse",
        "C_ScaleEffect",
        "C_MinCapacity",
        "C_MaxCapacity",
        "C_GeneratorPath",
        "C_VariabilityPath",
        "C_NetworkPath",
        "C_TrucksPath",
        "C_RoutesPath",
        "C_StoragePath",
        "C_DemandPath",
        "C_NsePath",
        "C_EmissionPath",
        "C_MinCapacityPath",
        "C_MaxCapacityPath",
        "C_SubZone",
        "C_SubZoneKey",
    ]

    ## Modify carbon sector settings
    for (key, value) in modification
        if key in carbon_settings_keys
            ## Modify carbon sector demand according to modification
            carbon_settings[split(key, "_")[2]] = value
            delete!(modification, key)
        elseif key == "C_CO2Policy" && in(-1, settings["CO2Policy"])
            if typeof(value) == Int64
                carbon_settings[split(key, "_")[2]] = [value]
            elseif typeof(value) <: AbstractString
                carbon_settings[split(key, "_")[2]] = parse.(Int64, split(value, "+"))
            end
            delete!(modification, key)
        elseif key in [
            "C_Zones",
            "C_GeneratorSet",
            "C_GeneratorIndex",
            "C_PipeSet",
            "C_TruckSet",
            "C_StorageSet",
            "C_StorageIndex",
        ]
            carbon_settings[split(key, "_")[2]] = [value]
            delete!(modification, key)
        end
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

    ## Update carbon settings origination dataframe
    carbon_settings_keys =
        chop.(
            intersect(
                mkeys,
                union(
                    carbon_settings_keys,
                    [
                        "C_CO2Policy",
                        "C_Zones",
                        "C_GeneratorSet",
                        "C_GeneratorIndex",
                        "C_LineSet",
                        "C_StorageSet",
                        "C_StorageIndex",
                    ],
                ),
            ),
            head = 2,
            tail = 0,
        )

    ## Update carbon settings origination dataframe
    dfCarbonSettings = transform(
        dfCarbonSettings,
        [:Key, :Value, :Origin] =>
            ByRow(
                (k, v, o) -> (
                    Value = k in carbon_settings_keys ? carbon_settings[k] : v,
                    Origin = k in carbon_settings_keys ? "user-modi" : o,
                ),
            ) => AsTable,
    )
    carbon_settings["dfCarbonSettings"] = dfCarbonSettings
    settings["CarbonSettings"] = carbon_settings

    ## Store modification dict into settings for data modification
    settings["Modification"] = modification

    return settings
end
