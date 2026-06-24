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
function load_bioenergy_default_settings(bioenergy_settings::Dict)

    ## Bioenergy sector settings origination dataframe
    dfBioenergySettings =
        DataFrame(Scope = String[], Key = String[], Value = Any[], Origin = String[])
    bioenergy_settings["dfBioenergySettings"] = dfBioenergySettings

    # Bioenergy Model Options
    ## Transmission network expansional; 0 = not active; 1 = active systemwide
    set_default_value!(bioenergy_settings, "NetworkExpansion", 1)

    ## Whether to model residual transport; 0 = not active; 1 = active
    set_default_value!(bioenergy_settings, "ResidualTransport", 1)

    ## Whether to model truck in bioenergy supply chain - 0 - not included, 1 - included
    set_default_value!(bioenergy_settings, "ModelTrucks", 1)
    ## Whether to model truck capacity as discrete or integer - 0 - continuous capacity, 1- discrete capacity
    set_default_value!(bioenergy_settings, "TruckInteger", 0)

    ## Whether to model storage in bioenergy supply chain - 0 - not included, 1 - included
    set_default_value!(bioenergy_settings, "ModelStorage", 1)
    ## Storage capacity expansion; 0 = not active; -1 = all storage should not expand; 0 = not active, stick to original inputs; 1 = all storage could expand
    set_default_value!(bioenergy_settings, "StorageExpansion", 1)
    ## Whether to include sunk costs of existing storage in objective; 0 = not active; 1 = active
    set_default_value!(bioenergy_settings, "IncludeExistingSto", 0)
    ## Initial Biomass volume in warehouse
    set_default_value!(bioenergy_settings, "InitialBioVolume", 0)

    ## CO2 emissions cap for HSC only; 0 = not active (no CO2 emission limit); 1 = mass-based emission limit constraint; 2 = load + rate-based emission limit constraint; 3 = generation + rate-based emission limit constraint; 4 = emissions penalized via a carbon price
    set_default_value!(bioenergy_settings, "CO2Policy", [4])

    # Data file name
    ## File name which stores data of trucks
    set_default_value!(bioenergy_settings, "TrucksPath", "Trucks.csv")
    ## File name which stores data of routes
    set_default_value!(bioenergy_settings, "RoutesPath", "Routes.csv")
    ## File name which stores data of storage
    set_default_value!(bioenergy_settings, "StoragePath", "Warehouse.csv")
    ## File name which stores data of emission policy
    set_default_value!(bioenergy_settings, "EmissionPath", "Policy_emission.csv")

    # Filter generator, network and storage using zones
    ## Bioenergy Zone list for modeling - 'All' denotes zone list in global settings
    set_default_value!(bioenergy_settings, "Zones", ["All"])

    # Filter network using types
    ## Modeled truck candidate type set - 'All' stands for all truck types
    set_default_value!(bioenergy_settings, "TruckSet", ["All"])

    # Filter storage using types
    ## Modeled storage candidate type set - 'All' stands for all storage types
    set_default_value!(bioenergy_settings, "StorageSet", ["All"])

    return bioenergy_settings
end

@doc raw"""

"""
function set_default_value!(bioenergy_settings::Dict, key::String, default_value::Any)

    dfBioenergySettings = bioenergy_settings["dfBioenergySettings"]
    if !haskey(bioenergy_settings, key)
        bioenergy_settings[key] = default_value
    else
        push!(dfBioenergySettings, ["Bioenergy", key, bioenergy_settings[key], "user-file"])
    end
end
