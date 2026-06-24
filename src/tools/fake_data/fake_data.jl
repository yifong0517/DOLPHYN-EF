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
function fake_data(
    path::AbstractString,
    Scenario::Dict{Any, Any} = Dict(
        "sectors" => ["P", "H", "C", "S", "A", "F", "B"],
        "zones" => 3,
        "time_length" => 8760,
        "Power" => Dict(),
        "Hydrogen" => Dict(),
        "Carbon" => Dict(),
        "Synfuels" => Dict(),
        "Ammonia" => Dict(),
        "Foodstuff" => Dict(),
        "Bioenergy" => Dict(),
    ),
)
    ## Get parameters from YAML file
    sectors = Scenario["sectors"]
    zones = Scenario["zones"]
    time_length = Scenario["time_length"]

    ## Fake outer resources data in given time length
    resources = ["P", "H", "C", "B"]
    fake_resources(path, resources, time_length, availablity = false)

    ## Fake energy sector data in given time length over given zones
    ## TODO: Add more sectors to fake data if needed
    for s in sectors
        if s == "P"
            if !haskey(Scenario, "Power")
                Scenario["Power"] = Dict()
            end
            ## Power sector - electricity
            if haskey(Scenario["Power"], "GeneratorNumber") &&
               haskey(Scenario["Power"], "StorageNumber")
                fake_power_sector(path, zones, time_length, Scenario["Power"])
            else
                fake_power_sector(path, zones, time_length)
            end
        end
        if s == "H"
            if !haskey(Scenario, "Hydrogen")
                Scenario["Hydrogen"] = Dict()
            end
            ## Hydrogen sector - hydrogen for power or industry
            if haskey(Scenario["Hydrogen"], "GeneratorNumber") &&
               haskey(Scenario["Hydrogen"], "StorageNumber") &&
               haskey(Scenario["Hydrogen"], "Trucks")
                fake_hydrogen_sector(path, zones, time_length, Scenario["Hydrogen"])
            else
                fake_hydrogen_sector(path, zones, time_length)
            end
        end
        if s == "C"
            if !haskey(Scenario, "Carbon")
                Scenario["Carbon"] = Dict()
            end
            ## Carbon sector - carbon for industry
            if haskey(Scenario["Carbon"], "GeneratorNumber") &&
               haskey(Scenario["Carbon"], "StorageNumber") &&
               haskey(Scenario["Carbon"], "Trucks")
                fake_carbon_sector(path, zones, time_length, Scenario["Carbon"])
            else
                fake_carbon_sector(path, zones, time_length)
            end
        end
        if s == "S"
            if !haskey(Scenario, "Synfuels")
                Scenario["Synfuels"] = Dict()
            end
            ## Synfuels sector - synfuels for power or industry
            if haskey(Scenario["Synfuels"], "GeneratorNumber") &&
               haskey(Scenario["Synfuels"], "StorageNumber") &&
               haskey(Scenario["Synfuels"], "Trucks")
                fake_synfuels_sector(path, zones, time_length, Scenario["Synfuels"])
            else
                fake_synfuels_sector(path, zones, time_length)
            end
        end
        if s == "A"
            if !haskey(Scenario, "Ammonia")
                Scenario["Ammonia"] = Dict()
            end
            ## Ammonia sector - ammonia for power or industry
            if haskey(Scenario["Ammonia"], "GeneratorNumber") &&
               haskey(Scenario["Ammonia"], "StorageNumber") &&
               haskey(Scenario["Ammonia"], "Trucks")
                fake_ammonia_sector(path, zones, time_length, Scenario["Ammonia"])
            else
                fake_ammonia_sector(path, zones, time_length)
            end
        end
        if s == "F"
            if !haskey(Scenario, "Foodstuff")
                Scenario["Foodstuff"] = Dict()
            end
            ## Foodstuff sector - foodstuff for agriculture
            if haskey(Scenario["Foodstuff"], "CropType") && haskey(Scenario["Foodstuff"], "Trucks")
                fake_foodstuff_sector(path, zones, time_length, Scenario["Foodstuff"])
            else
                fake_foodstuff_sector(path, zones, time_length)
            end
        end
        if s == "B"
            if !haskey(Scenario, "Bioenergy")
                Scenario["Bioenergy"] = Dict()
            end
            ## Bioenergy sector - bioenergy for power
            if haskey(Scenario["Bioenergy"], "GeneratorNumber") &&
               haskey(Scenario["Bioenergy"], "StorageNumber") &&
               haskey(Scenario["Bioenergy"], "Trucks")
                fake_bioenergy_sector(path, zones, time_length, Scenario["Bioenergy"])
            else
                fake_bioenergy_sector(path, zones, time_length)
            end
        end
    end

    println("All Sectors Data Faked!")
end
