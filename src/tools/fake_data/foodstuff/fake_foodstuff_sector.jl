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
function fake_foodstuff_sector(
    path::AbstractString,
    zones::Integer,
    time_length::Integer = 8760,
    settings::Dict = Dict("CropType" => ["SpringWheat", "WinterWheat"], "Trucks" => ["Cart"]),
)

    ## Static crops list
    CropType = settings["CropType"]
    trucks = settings["Trucks"]

    ## Foodstuff sector data path
    path = joinpath(path, "Foodstuff")

    ## Check whether path exists
    if !isdir(path)
        mkdir(path)
    end

    ## Fake foodstuff crop data
    fake_foodstuff_crops(path, zones, CropType)

    ## Fake foodstuff land data
    fake_foodstuff_land_area(path, zones)

    ## Fake foodstuff crop time
    fake_foodstuff_crop_time(path, zones, time_length, CropType)

    ## Fake foodstuff trucks data
    fake_foodstuff_trucks(path, zones, trucks)

    ## Fake foodstuff routes data
    fake_foodstuff_routes(path, zones)

    ## Fake foodstuff warehouse data
    fake_foodstuff_warehouse(path, zones, CropType)

    ## Fake foodstuff demand data
    fake_foodstuff_demand(path, zones, time_length, CropType)

    ## Fake foodstuff NSE data
    fake_foodstuff_nse(path)

    println("Foodstuff sector data mimic finished.")
end
