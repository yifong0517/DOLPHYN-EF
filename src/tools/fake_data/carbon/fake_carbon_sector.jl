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
    fake_carbon_sector(
        path::AbstractString,
        zones::Integer,
        time_length::Integer,
        settings::Dict = Dict(
            "CaptureNumber" => 1,
            "StorageNumber" => 1,
            "Trucks" => ["Gas", "Liquid", "LOHC"],
        ),
    )

This function fakes carbon sector data rom nowhere.
"""
function fake_carbon_sector(
    path::AbstractString,
    zones::Integer,
    time_length::Integer,
    settings::Dict = Dict(
        "CaptureNumber" => 1,
        "StorageNumber" => 1,
        "Trucks" => ["Gas", "Liquid", "LOHC"],
    ),
)

    ## Generators, storages, and truck list
    generators =
        Dict("Solid_DAC" => settings["CaptureNumber"], "Liquid_DAC" => settings["CaptureNumber"])
    storages = Dict(
        "Above_ground_storage" => settings["StorageNumber"],
        "Underground_storage" => settings["StorageNumber"],
    )
    trucks = settings["Trucks"]

    ## Carbon sector path
    path = joinpath(path, "Carbon")

    ## Check whether path exists
    if !isdir(path)
        mkdir(path)
    end

    ## Fake carbon generators data
    fake_carbon_generators(path, zones, generators)

    ## Fake carbon generators' variability data
    fake_carbon_generators_variability(path, zones, time_length, generators)

    ## Fake carbon pipeline network data
    fake_carbon_pipelines(path, zones)

    ## Fake carbon trucks data
    fake_carbon_trucks(path, zones, trucks)

    ## Fake carbon routes data
    fake_carbon_routes(path, zones)

    ## Fake carbon storage data
    fake_carbon_storage(path, zones, storages)

    ## Fake carbon demand data
    fake_carbon_demand(path, zones, time_length)

    ## Fake carbon NSE data
    fake_carbon_nse(path)

    ## Fake carbon carbon emission policy data
    fake_carbon_carbon_cap(path, zones)

    println("Carbon sector data mimic finished.")
end
