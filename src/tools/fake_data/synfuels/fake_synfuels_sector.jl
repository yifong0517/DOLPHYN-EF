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
    fake_synfuels_sector(
        path::AbstractString,
        zones::Integer,
        time_length::Integer,
        settings::Dict = Dict("GeneratorNumber" => 1, "StorageNumber" => 1, "Trucks" => ["Liquid"]),
    )

This function fakes synfuels sector data from nowhere.
"""
function fake_synfuels_sector(
    path::AbstractString,
    zones::Integer,
    time_length::Integer,
    settings::Dict = Dict("GeneratorNumber" => 1, "StorageNumber" => 1, "Trucks" => ["Liquid"]),
)

    ## Static generators, storages and trucks list
    generators = Dict(
        "Small_SMR" => settings["GeneratorNumber"],
        "Large_SMR" => settings["GeneratorNumber"],
        "Large_SMR_CCS" => settings["GeneratorNumber"],
        "Small_Electrolyzer" => settings["GeneratorNumber"],
        "Large_Electrolyzer" => settings["GeneratorNumber"],
    )
    storages = Dict("Above_ground_storage" => settings["StorageNumber"])
    trucks = settings["Trucks"]

    ## Synfuels sector path
    path = joinpath(path, "Synfuels")

    ## Check whether path exists
    if !isdir(path)
        mkdir(path)
    end

    ## Fake synfuels generators data
    fake_synfuels_generators(path, zones, generators)

    ## Fake synfuels generators' variability data
    fake_synfuels_generators_variability(path, zones, time_length, generators)

    ## Fake synfuels pipeline network data
    fake_synfuels_pipelines(path, zones)

    ## Fake synfuels trucks data
    fake_synfuels_trucks(path, zones, trucks)

    ## Fake synfuels routes data
    fake_synfuels_routes(path, zones)

    ## Fake synfuels storage data
    fake_synfuels_storage(path, zones, storages)

    ## Fake synfuels demand data
    fake_synfuels_demand(path, zones, time_length)

    ## Fake synfuels NSE data
    fake_synfuels_nse(path)

    ## Fake synfuels carbon emission policy data
    fake_synfuels_carbon_cap(path, zones)

    println("Synfuels sector data mimic finished.")
end
