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
    fake_power_sector(
        path::AbstractString,
        zones::Integer,
        time_length::Integer=8760,
        settings::Dict = Dict("GeneratorNumber" => 1, "StorageNumber" => 1)
    )

This function fakes power sector data from nowhere.
"""
function fake_power_sector(
    path::AbstractString,
    zones::Integer,
    time_length::Integer = 8760,
    settings::Dict = Dict("GeneratorNumber" => 1, "StorageNumber" => 1),
)

    ## Static generators and storages list
    generators = Dict(
        "Coal" => settings["GeneratorNumber"],
        "Coal_CCS" => settings["GeneratorNumber"],
        "CCGT" => settings["GeneratorNumber"],
        "CCGT_CCS" => settings["GeneratorNumber"],
        "Nuclear" => settings["GeneratorNumber"],
        "Wind" => settings["GeneratorNumber"],
        "PV" => settings["GeneratorNumber"],
    )
    storages = Dict("Storage_bat" => settings["StorageNumber"], "PHS" => settings["StorageNumber"])

    ## Power sector data path
    path = joinpath(path, "Power")

    ## Check whether path exists
    if !isdir(path)
        mkdir(path)
    end

    ## Fake power generators' data
    fake_power_generators(path, zones, generators)

    ## Fake power generators' variability data
    fake_power_generators_variability(path, zones, time_length, generators)

    ## Fake power transmission lines' data
    fake_power_network(path, zones)

    ## Fake power storage data
    fake_power_storage(path, zones, storages)

    ## Fake power demand data
    fake_power_demand(path, zones, time_length)

    ## Fake power non-served-demand data
    fake_power_nse(path)

    ## Fake power carbon emission policy data
    fake_power_carbon_cap(path, zones)

    ## Fake power primary reserve policy data
    fake_power_primary_reserve(path, zones)

    ## Fake power energy share policy data
    fake_power_energy_share(path, zones)

    ## Fake power minimum capacity policy data
    fake_power_minimum_capacity(path, zones, generators)

    ## Fake power maximum capacity policy data
    fake_power_maximum_capacity(path, zones, generators)

    println("Power sector data mimic finished.")
end
