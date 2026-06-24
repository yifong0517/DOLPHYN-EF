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
    fake_bioenergy_sector(
        path::AbstractString,
        zones::Integer,
        time_length::Integer,
        settings::Dict = Dict("GeneratorNumber" => 1, "StorageNumber" => 1, "Trucks" => ["Liquid"]),
    )

This function fakes bioenergy sector data from nowhere.
"""
function fake_bioenergy_sector(
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

    ## bioenergy sector path
    path = joinpath(path, "bioenergy")

    ## Check whether path exists
    if !isdir(path)
        mkdir(path)
    end

    ## Fake bioenergy generators data
    fake_bioenergy_generators(path, zones, generators)

    ## Fake bioenergy generators' variability data
    fake_bioenergy_generators_variability(path, zones, time_length, generators)

    ## Fake bioenergy trucks data
    fake_bioenergy_trucks(path, zones, trucks)

    ## Fake bioenergy routes data
    fake_bioenergy_routes(path, zones)

    ## Fake bioenergy storage data
    fake_bioenergy_warehouse(path, zones, storages)

    ## Fake bioenergy demand data
    fake_bioenergy_demand(path, zones, time_length)

    ## Fake bioenergy NSE data
    fake_bioenergy_nse(path)

    ## Fake bioenergy carbon emission policy data
    fake_bioenergy_carbon_cap(path, zones)

    println("bioenergy sector data mimic finished.")
end
