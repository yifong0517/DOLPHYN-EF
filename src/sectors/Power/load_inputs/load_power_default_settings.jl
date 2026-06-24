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
function load_power_default_settings(power_settings::Dict)

    ## Power sector settings origination dataframe
    dfPowerSettings = DataFrame(Scope = String[], Key = String[], Value = Any[], Origin = String[])
    power_settings["dfPowerSettings"] = dfPowerSettings

    # Power Model Options
    ## Generation capacity expansion; -1 = all generators should not expand; 0 = not active, stick to original inputs; 1 = all generators could expand
    set_default_value!(power_settings, "GenerationExpansion", 1)
    ## Whether to include sunk costs of existing generators in objective; 0 = not active; >0 = active and denotes the costs recovery ratio
    set_default_value!(power_settings, "IncludeExistingGen", 0)
    ## Unit committment of thermal power plants; 0 = not active; 1 = active using integer clustering; 2 = active using linearized clustering
    set_default_value!(power_settings, "UCommit", 0)

    ## Transmission network modeling; 0 = not active; 1 = DC power flow; 2 = AC power flow
    set_default_value!(power_settings, "ModelTransmission", 1)
    ## Transmission network capacity expansion; -1 = all lines should not expand; 0 = not active, stick to original inputs; 1 = all lines could expand
    set_default_value!(power_settings, "NetworkExpansion", 1)
    ## Whether to include sunk costs of existing transmission lines in objective; 0 = not active; >0 = active and denotes the costs recovery ratio
    set_default_value!(power_settings, "IncludeExistingNetwork", 0)
    ## Number of segments used in piecewise linear approximation of transmission losses; 1 = linear, >2 = piecewise quadratic
    set_default_value!(power_settings, "LineLossSegments", 0)
    ## DC power flow modeling; 0 = not active; 1 = active
    set_default_value!(power_settings, "DCPowerFlow", 0)

    ## Storage modeling; 0 = not active; 1 = active
    set_default_value!(power_settings, "ModelStorage", 1)
    ## Storage capacity expansion; 0 = not active; -1 = all storage should not expand; 0 = not active, stick to original inputs; 1 = all storage could expand
    set_default_value!(power_settings, "StorageExpansion", 1)
    ## Whether to include sunk costs of existing storage in objective; 0 = not active; >0 = active and denotes the costs recovery ratio
    set_default_value!(power_settings, "IncludeExistingSto", 0)
    ## Battery aging modeling; 0 = not active; 1 = active
    set_default_value!(power_settings, "BatteryAging", 0)

    ## Whether to allow non-served energy; 0 = not active; 1 = active
    set_default_value!(power_settings, "AllowNse", 1)

    ## Whether to model learning-by-doing effect; 0 = not active; 1 = active
    set_default_value!(power_settings, "ScaleEffect", 0)

    ## Whether to model carbon capture and storage (CCS); 0 = not active; 1 = active
    set_default_value!(power_settings, "CO2Policy", [4])

    ## Power system capacity reserve modeling; 0 = not active; 1 = active
    set_default_value!(power_settings, "CapReserve", 0)

    ## Power system primary reserve modeling; 0 = not active; 1 = active
    set_default_value!(power_settings, "PReserve", 0)
    ## Power system secondary reserve modeling; 0 = not active; 1 = active
    set_default_value!(power_settings, "SReserve", 0)

    ## Power system min technology capacity requirements; 0 = not active; 1 = active; 2 = globally active
    set_default_value!(power_settings, "MinCapacity", 0)
    ## Power system max technology capacity requirements; 0 = not active; 1 = active; 2 = globally active
    set_default_value!(power_settings, "MaxCapacity", 0)

    ## Power system energy share standard modeling; 0 = not active; 1 = renewable portfolio standard (RPS); 2 = clean electricity standard (CES); 3 = combined RPS and CES policies
    set_default_value!(power_settings, "EnergyShareStandard", 0)

    ## Power system CO2 disposal modeling; 0 = not active; 1 = active
    set_default_value!(power_settings, "CO2Disposal", 0)

    # Data file name
    ## File name which stores data of generators
    set_default_value!(power_settings, "GeneratorPath", "Generators.csv")
    ## File name which stores data of generators' variability
    set_default_value!(power_settings, "VariabilityPath", "Generators_variability.csv")
    ## File name which stores data of network
    set_default_value!(power_settings, "NetworkPath", "Network.csv")
    ## File name which stores data of storage
    set_default_value!(power_settings, "StoragePath", "Storage.csv")
    ## File name which stores data of demand
    set_default_value!(power_settings, "DemandPath", "Demand.csv")
    ## File name which stores data of non served energy
    set_default_value!(power_settings, "NsePath", "Nse.csv")
    ## File name which stores data of emission policy
    set_default_value!(power_settings, "EmissionPath", "Policy_emission.csv")
    ## File name which stores data of reserve policy
    set_default_value!(power_settings, "ReservePath", "Policy_reserve.csv")
    ## File name which stores data of min capacity requirements policy
    set_default_value!(power_settings, "MinCapacityPath", "Policy_capacity_minimum.csv")
    ## File name which stores data of max capacity requirements policy
    set_default_value!(power_settings, "MaxCapacityPath", "Policy_capacity_maximum.csv")
    ## File name which stores data of energy share policy
    set_default_value!(power_settings, "EnergySharePath", "Policy_share.csv")
    ## File name which stores data of CO2 disposal policy
    set_default_value!(power_settings, "DisposalPath", "Policy_carbon_disposal.csv")

    # Filter generator, network and storage using zones
    ## Power Zone list for modeling - 'All' denotes zone list in global settings
    set_default_value!(power_settings, "Zones", ["All"])

    # Sub zone topology modeling
    ## Whether to model power sector sub-zones; 0 = not active; 1 = active
    set_default_value!(power_settings, "SubZone", 0)
    ## Column name in generator data file which stores sub zone criteria
    set_default_value!(power_settings, "SubZoneKey", "")

    # Filter generator using type
    ## Modeled generator candidate type set - 'All' stands for all generator types
    set_default_value!(power_settings, "GeneratorSet", ["All"])
    ## Modeled generator candidate index set - 'All' stands for all generators
    set_default_value!(power_settings, "GeneratorIndex", ["All"])

    # Filter network using type
    ## Modeled transmission line candidate type set - 'All' stands for all transmission line types
    set_default_value!(power_settings, "NetworkSet", ["All"])

    # Filter storage using type
    ## Modeled storage candidate type set - 'All' stands for all storage types
    set_default_value!(power_settings, "StorageSet", ["All"])
    ## Modeled storage index set - 'All' stands for all storage
    set_default_value!(power_settings, "StorageIndex", ["All"])

    return power_settings
end

@doc raw"""

"""
function set_default_value!(power_settings::Dict, key::String, default_value::Any)

    dfPowerSettings = power_settings["dfPowerSettings"]
    if !haskey(power_settings, key)
        power_settings[key] = default_value
    else
        push!(dfPowerSettings, ["Power", key, power_settings[key], "user-file"])
    end
end
