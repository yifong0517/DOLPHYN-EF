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
function modify_bioenergy_settings(settings::Dict, modification::Dict)

    print_and_log(settings, "i", "Modifying Bioenergy Settings According to User's Modification")

    bioenergy_settings = settings["BioenergySettings"]
    dfBioenergySettings = bioenergy_settings["dfBioenergySettings"]
    mkeys = collect(keys(modification))

    ## Bioenergy sector settings
    bioenergy_settings_keys = [
        "B_NetworkExpansion",
        "B_ResidualTransport",
        "B_ModelTrucks",
        "B_TruckInteger",
        "B_ModelStorage",
        "B_IncludeExistingSto",
        "B_InitialBioVolume",
        "B_TrucksPath",
        "B_RoutesPath",
        "B_StoragePath",
        "B_EmissionPath",
    ]

    ## Modify bioenergy sector settings
    for (key, value) in modification
        if key in bioenergy_settings_keys
            ## Modify bioenergy sector demand according to modification
            bioenergy_settings[split(key, "_")[2]] = value
            delete!(modification, key)
        elseif key == "B_CO2Policy" && in(-1, settings["CO2Policy"])
            bioenergy_settings[split(key, "_")[2]] = [value]
            delete!(modification, key)
        elseif key in ["B_Zones", "B_TruckSet", "B_StorageSet"]
            bioenergy_settings[split(key, "_")[2]] = [value]
            delete!(modification, key)
        end
    end

    ## Update bioenergy settings origination dataframe
    bioenergy_settings_keys =
        chop.(
            intersect(
                mkeys,
                union(bioenergy_settings_keys, ["B_CO2Policy", "B_Zones", "B_StorageSet"]),
            ),
            head = 2,
            tail = 0,
        )

    ## Update bioenergy settings origination dataframe
    dfBioenergySettings = transform(
        dfBioenergySettings,
        [:Key, :Value, :Origin] =>
            ByRow(
                (k, v, o) -> (
                    Value = k in bioenergy_settings_keys ? bioenergy_settings[k] : v,
                    Origin = k in bioenergy_settings_keys ? "user-modi" : o,
                ),
            ) => AsTable,
    )
    bioenergy_settings["dfBioenergySettings"] = dfBioenergySettings
    settings["BioenergySettings"] = bioenergy_settings

    ## Store modification dict into settings for data modification
    settings["Modification"] = modification

    return settings
end
