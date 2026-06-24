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
    fake_ammonia_sector(
        path::AbstractString,
        zones::Integer,
        time_length::Integer,
        settings::Dict = Dict("GeneratorNumber" => 1, "StorageNumber" => 1, "Trucks" => ["Liquid"]),
    )

This function fakes ammonia sector data from nowhere.
"""
function fake_ammonia_sector(
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

    ## Ammonia sector path
    path = joinpath(path, "Ammonia")

    ## Check whether path exists
    if !isdir(path)
        mkdir(path)
    end

    ## Fake ammonia generators data
    fake_ammonia_generators(path, zones, generators)

    ## Fake ammonia generators' variability data
    fake_ammonia_generators_variability(path, zones, time_length, generators)

    ## Fake ammonia pipeline network data
    fake_ammonia_pipelines(path, zones)

    ## Fake ammonia trucks data
    fake_ammonia_trucks(path, zones, trucks)

    ## Fake ammonia routes data
    fake_ammonia_routes(path, zones)

    ## Fake ammonia storage data
    fake_ammonia_storage(path, zones, storages)

    ## Fake ammonia demand data
    fake_ammonia_demand(path, zones, time_length)

    ## Fake ammonia NSE data
    fake_ammonia_nse(path)

    ## Fake ammonia carbon emission policy data
    fake_ammonia_carbon_cap(path, zones)

    println("Ammonia sector data mimic finished.")
end
