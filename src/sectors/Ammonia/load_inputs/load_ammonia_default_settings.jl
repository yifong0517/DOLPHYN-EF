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
function load_ammonia_default_settings(ammonia_settings::Dict)

    ## Ammonia sector settings origination dataframe
    dfAmmoniaSettings =
        DataFrame(Scope = String[], Key = String[], Value = Any[], Origin = String[])
    ammonia_settings["dfAmmoniaSettings"] = dfAmmoniaSettings

    # Ammonia Model Options
    ## Generation capacity expansion; -1 = all generators should not expand; 0 = not active, stick to original inputs; 1 = all generators could expand
    set_default_value!(ammonia_settings, "GenerationExpansion", 1)
    ## Whether to include sunk costs of existing generators in objective; 0 = not active; >0 = active and denotes the costs recovery ratio
    set_default_value!(ammonia_settings, "IncludeExistingGen", 0)
    ## Unit committment of thermal power plants; 0 = not active; 1 = active using integer clustering; 2 = active using linearized clustering
    set_default_value!(ammonia_settings, "GenCommit", 0)
    ## Whether to model full load hours (FLH) in ammonia generation; 0 = not active; 1 = active
    set_default_value!(ammonia_settings, "ModelFLH", 0)

    ## Ammonia transport mode; 0 = not active; 1 = simple; 2 = pipeline; 3 = truck; 4 = both pipeline and truck
    set_default_value!(ammonia_settings, "TransportMode", 4)
    ## Whether to model simple ammonia transport; 0 = not active; 1 = active
    set_default_value!(ammonia_settings, "SimpleTransport", 0)

    ## Transmission network expansional; 0 = not active; 1 = active systemwide
    set_default_value!(ammonia_settings, "NetworkExpansion", 1)
    ## Whether to model pipeline capacity as discrete or integer - 0 - continuous capacity, 1- discrete capacity
    set_default_value!(ammonia_settings, "PipeInteger", 0)

    ## Whether to model truck in ammonia supply chain - 0 - not included, 1 - included
    set_default_value!(ammonia_settings, "ModelTrucks", 1)
    ## Whether to model truck capacity as discrete or integer - 0 - continuous capacity, 1- discrete capacity
    set_default_value!(ammonia_settings, "TruckInteger", 0)

    ## Whether to model storage in ammonia supply chain - 0 - not included, 1 - included
    set_default_value!(ammonia_settings, "ModelStorage", 1)
    ## Storage capacity expansion; 0 = not active; -1 = all storage should not expand; 0 = not active, stick to original inputs; 1 = all storage could expand
    set_default_value!(ammonia_settings, "StorageExpansion", 1)
    ## Whether to include sunk costs of existing storage in objective; 0 = not active; >0 = active and denotes the costs recovery ratio
    set_default_value!(ammonia_settings, "IncludeExistingSto", 0)

    ## Whether to allow non-served energy; 0 = not active; 1 = active
    set_default_value!(ammonia_settings, "AllowNse", 1)

    ## Whether to model learning-by-doing effect; 0 = not active; 1 = active
    set_default_value!(ammonia_settings, "ScaleEffect", 0)

    ## CO2 emissions cap for HSC only; 0 = not active (no CO2 emission limit); 1 = mass-based emission limit constraint; 2 = load + rate-based emission limit constraint; 3 = generation + rate-based emission limit constraint; 4 = emissions penalized via a carbon price
    set_default_value!(ammonia_settings, "CO2Policy", [4])

    ## Ammonia system min technology capacity requirements; 0 = not active; 1 = active; 2 = globally active
    set_default_value!(ammonia_settings, "MinCapacity", 0)
    ## Ammonia system max technology capacity requirements; 0 = not active; 1 = active; 2 = globally active
    set_default_value!(ammonia_settings, "MaxCapacity", 0)

    ## CO2 disposal; 0 = not active; 1 = active
    set_default_value!(ammonia_settings, "CO2Disposal", 0)

    # Data file name
    ## File name which stores data of generators
    set_default_value!(ammonia_settings, "GeneratorPath", "Generators.csv")
    ## File name which stores data of generators' variability
    set_default_value!(ammonia_settings, "VariabilityPath", "Generators_variability.csv")
    ## File name which stores data of trucks
    set_default_value!(ammonia_settings, "TrucksPath", "Trucks.csv")
    ## File name which stores data of routes
    set_default_value!(ammonia_settings, "RoutesPath", "Routes.csv")
    ## File name which stores data of storage
    set_default_value!(ammonia_settings, "StoragePath", "Storage.csv")
    ## File name which stores data of demand
    set_default_value!(ammonia_settings, "DemandPath", "Demand.csv")
    ## File name which stores data of non served energy
    set_default_value!(ammonia_settings, "NsePath", "Nse.csv")
    ## File name which stores data of emission policy
    set_default_value!(ammonia_settings, "EmissionPath", "Policy_emission.csv")
    ## File name which stores data of min capacity requirements policy
    set_default_value!(ammonia_settings, "MinCapacityPath", "Policy_capacity_minimum.csv")
    ## File name which stores data of max capacity requirements policy
    set_default_value!(ammonia_settings, "MaxCapacityPath", "Policy_capacity_maximum.csv")

    ## File name which stores data of CO2 disposal policy
    set_default_value!(ammonia_settings, "DisposalPath", "Policy_carbon_disposal.csv")

    # Filter generator, network and storage using zones
    ## Ammonia Zone list for modeling - 'All' denotes zone list in global settings
    set_default_value!(ammonia_settings, "Zones", ["All"])

    # Sub zone topology modeling
    ## Whether to model ammonia sector sub-zones; 0 = not active; 1 = active
    set_default_value!(ammonia_settings, "SubZone", 0)
    ## Column name in generator data file which stores sub zone criteria
    set_default_value!(ammonia_settings, "SubZoneKey", "")

    # Filter generator using types
    ## Modeled generator candidate type set - 'All' stands for all generator types
    set_default_value!(ammonia_settings, "GeneratorSet", ["All"])
    ## Modeled generator candidate index set - 'All' stands for all generator indices
    set_default_value!(ammonia_settings, "GeneratorIndex", ["All"])

    # Filter network using types
    ## Modeled truck candidate type set - 'All' stands for all truck types
    set_default_value!(ammonia_settings, "TruckSet", ["All"])

    # Filter storage using types
    ## Modeled storage candidate type set - 'All' stands for all storage types
    set_default_value!(ammonia_settings, "StorageSet", ["All"])
    ## Modeled storage candidate type set - 'All' stands for all storage
    set_default_value!(ammonia_settings, "StorageIndex", ["All"])

    return ammonia_settings
end

@doc raw"""

"""
function set_default_value!(ammonia_settings::Dict, key::String, default_value::Any)

    dfAmmoniaSettings = ammonia_settings["dfAmmoniaSettings"]
    if !haskey(ammonia_settings, key)
        ammonia_settings[key] = default_value
    else
        push!(dfAmmoniaSettings, ["Ammonia", key, ammonia_settings[key], "user-file"])
    end
end
