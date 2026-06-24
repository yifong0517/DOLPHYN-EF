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
    fake_hydrogen_sector(
        path::AbstractString,
        zones::Integer,
        time_length::Integer,
        settings::Dict = Dict(
            "GeneratorNumber" => 1,
            "StorageNumber" => 1,
            "Trucks" => ["Gas", "Liquid", "LOHC"],
        ),
    )

This function fakes hydrogen sector data from nowhere.
"""
function fake_hydrogen_sector(
    path::AbstractString,
    zones::Integer,
    time_length::Integer,
    settings::Dict = Dict(
        "GeneratorNumber" => 1,
        "StorageNumber" => 1,
        "Trucks" => ["Gas", "Liquid", "LOHC"],
    ),
)

    ## Static generators, storages and trucks list
    generators = Dict(
        "Small_SMR" => settings["GeneratorNumber"],
        "Large_SMR" => settings["GeneratorNumber"],
        "Large_SMR_CCS" => settings["GeneratorNumber"],
        "Small_Electrolyzer" => settings["GeneratorNumber"],
        "Large_Electrolyzer" => settings["GeneratorNumber"],
    )
    storages = Dict(
        "Above_ground_storage" => settings["StorageNumber"],
        "Underground_storage" => settings["StorageNumber"],
    )
    trucks = settings["Trucks"]

    ## Hydrogen sector data path
    path = joinpath(path, "Hydrogen")

    ## Check whether path exists
    if !isdir(path)
        mkdir(path)
    end

    ## Fake hydrogen generators data
    fake_hydrogen_generators(path, zones, generators)

    ## Fake hydrogen generators' variability data
    fake_hydrogen_generators_variability(path, zones, time_length, generators)

    ## Fake hydrogen pipeline network data
    fake_hydrogen_pipelines(path, zones)

    ## Fake hydrogen trucks data
    fake_hydrogen_trucks(path, zones, trucks)

    ## Fake hydrogen routes data
    fake_hydrogen_routes(path, zones)

    ## Fake hydrogen storage data
    fake_hydrogen_storage(path, zones, storages)

    ## Fake hydrogen demand data
    fake_hydrogen_demand(path, zones, time_length)

    ## Fake hydrogen NSE data
    fake_hydrogen_nse(path)

    ## Fake hydrogen carbon emission policy data
    fake_hydrogen_carbon_cap(path, zones)

    ## Fake hydrogen minimum capacity policy data
    fake_hydrogen_minimum_capacity(path, zones, generators)

    ## Fake hydrogen maximum capacity policy data
    fake_hydrogen_maximum_capacity(path, zones, generators)

    println("Hydrogen sector data mimic finished.")
end
