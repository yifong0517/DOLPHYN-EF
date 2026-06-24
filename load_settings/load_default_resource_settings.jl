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
function load_default_resource_settings(
    resource_settings::Dict,
    resource_user_settings::Dict = Dict{Any, Any}(),
)

    ## Resource settings origination dataframe
    dfResourceSettings =
        DataFrame(Scope = String[], Key = String[], Value = Any[], Origin = String[])
    resource_settings["dfResourceSettings"] = dfResourceSettings
    mkeys = collect(keys(resource_user_settings))

    resource_settings_keys =
        ["FuelPath", "ElectricityPath", "HydrogenPath", "CarbonPath", "BioenergyPath"]
    ## File name which stores prices of fuels
    set_default_resource_value!(resource_settings, "FuelPath", "Fuels_data.csv")
    ## File name which stores prices of electricity
    set_default_resource_value!(resource_settings, "ElectricityPath", "Electricity_data.csv")
    ## File name which stores prices of hydrogen
    set_default_resource_value!(resource_settings, "HydrogenPath", "Hydrogen_data.csv")
    ## File name which stores prices of bioenergy
    set_default_resource_value!(resource_settings, "BioenergyPath", "Bioenergy_data.csv")
    ## File name which stores prices of carbon
    set_default_resource_value!(resource_settings, "CarbonPath", "Carbon_data.csv")
    ## File name which stores prices of residual including straw and husk
    set_default_resource_value!(resource_settings, "ResidualPath", "Residual_data.csv")

    ## File name which stores data of carbon disposal policy
    set_default_resource_value!(resource_settings, "CarbonDisposalPath", "Carbon_disposal.csv")

    ## File name which stores data of fuels availability
    set_default_resource_value!(
        resource_settings,
        "FuelsAvailabilityPath",
        "Fuels_availability.csv",
    )
    ## File name which stores data of electricity availability
    set_default_resource_value!(
        resource_settings,
        "ElectricityAvailabilityPath",
        "Electricity_availability.csv",
    )
    ## File name which stores data of hydrogen availability
    set_default_resource_value!(
        resource_settings,
        "HydrogenAvailabilityPath",
        "Hydrogen_availability.csv",
    )
    ## File name which stores data of carbon availability
    set_default_resource_value!(
        resource_settings,
        "CarbonAvailabilityPath",
        "Carbon_availability.csv",
    )
    ## File name which stores data of bioenergy availability
    set_default_resource_value!(
        resource_settings,
        "BioenergyAvailabilityPath",
        "Bioenergy_availability.csv",
    )

    ## Default resource settings
    dfResourceSettings = resource_settings["dfResourceSettings"]
    dfResourceSettings = transform(
        dfResourceSettings,
        [:Key, :Value, :Origin] =>
            ByRow(
                (k, v, o) -> (
                    Value = k in intersect(mkeys, resource_settings_keys) ?
                            resource_user_settings[k] : v,
                    Origin = k in intersect(mkeys, resource_settings_keys) ? "user-modi" : o,
                ),
            ) => AsTable,
    )

    resource_settings["dfResourceSettings"] = dfResourceSettings

    ## Update user-defined resource settings into run-time settings
    resource_settings = merge(resource_settings, resource_user_settings)

    return resource_settings
end

@doc raw"""

"""
function set_default_resource_value!(resource_settings::Dict, key::String, default_value::Any)

    dfResourceSettings = resource_settings["dfResourceSettings"]

    if !haskey(resource_settings, key)
        resource_settings[key] = default_value
        push!(dfResourceSettings, ["Resource", key, default_value, "default"])
    else
        push!(dfResourceSettings, ["Resource", key, resource_settings[key], "user-file"])
    end
end
