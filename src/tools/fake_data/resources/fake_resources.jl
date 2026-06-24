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
    fake_resources(path::AbstractString, feedstocks::AbstractArray{String}, time_length::Integer, availablity=false)

This function fakes imaginary resources of given feedstocks from nowhere.
"""
function fake_resources(
    path::AbstractString,
    feedstocks::AbstractArray{String},
    time_length::Integer;
    availablity::Bool = false,
)

    ## Price path
    path = joinpath(path, "Outer")

    ## Check whether path exists
    if !isdir(path)
        mkdir(path)
    end

    ## Dictionary of modeled resources
    resources = Dict()

    ## Add more resources to fake resources data if needed
    for s in feedstocks
        if s == "P"
            ## Power sector - electricity
            electricitys = ["Electricity"]
            fake_electricitys_price(path, electricitys, time_length)
            resources["ElectricityPrice"] = "Electricity_data.csv"
        end
        if s == "H"
            ## Hydrogen sector - hydrogen for power or industry
            hydrogens = ["Hydrogen"]
            fake_hydrogens_price(path, hydrogens, time_length)
            resources["HydrogenPrice"] = "Hydrogen_data.csv"
        end
        if s == "C"
            ## Carbon sector - carbon for industry
            carbons = ["Carbon"]
            fake_carbons_price(path, carbons, time_length)
            resources["CarbonPrice"] = "Carbon_data.csv"
        end
        if s == "B"
            ## Bioenergy sector - bioenergy for power or industry
            bioenergys = ["Bioenergy"]
            fake_bioenergys_price(path, bioenergys, time_length)
            resources["BioenergyPrice"] = "Bioenergy_data.csv"
        end
    end

    ## Fake fuels prices
    fuels = ["Coal", "Natural Gas", "Oil", "Uranium"]
    fake_fuels_price(path, fuels, time_length)
    resources["FuelsPrice"] = "Fuel_data.csv"

    ## Resource availability
    if availablity == true
        for s in feedstocks
            if s == "P"
                ## Power sector - electricity
                electricitys = ["Electricity"]
                fake_electricitys_availability(path, electricitys, time_length)
                resources["ElectricityAvailability"] = "Electricity_availability.csv"
            end
            if s == "H"
                ## Hydrogen sector - hydrogen for power or industry
                hydrogens = ["Hydrogen"]
                fake_hydrogens_availability(path, hydrogens, time_length)
                resources["HydrogenAvailability"] = "Hydrogen_availability.csv"
            end
            if s == "C"
                ## Carbon sector - carbon for industry
                carbons = ["Carbon"]
                fake_carbons_availability(path, carbons, time_length)
                resources["CarbonAvailability"] = "Carbon_availability.csv"
            end
            if s == "B"
                ## Bioenergy sector - bioenergy for power or industry
                bioenergys = ["Bioenergy"]
                fake_bioenergys_availability(path, bioenergys, time_length)
                resources["BioenergyAvailability"] = "Bioenergy_availability.csv"
            end
        end

        ## Fake fuels' availability
        fuels = ["Coal", "Natural Gas", "Oil", "Uranium"]
        fake_fuels_availability(path, fuels, time_length)
        resources["FuelsAvailability"] = "Fuel_availability.csv"
    end

    YAML.write_file(joinpath(path, "resources.yml"), resources)
end
