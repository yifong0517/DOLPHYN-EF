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
function fake_foodstuff_land_area(path::AbstractString, zones::Integer)

    ## Generate zone list
    Zones = string.(1:zones)

    ## Land dataframe
    dfLand = DataFrame(
        Zone = Zones,
        x1 = rand(zones) .* 1000000 .+ 5000,
        x2 = rand(zones) .* 1000000 .+ 6000,
        x3 = rand(zones) .* 1000000 .+ 7000,
        x4 = rand(zones) .* 1000000 .+ 8000,
        x5 = rand(zones) .* 1000000 .+ 9000,
        x6 = rand(zones) .* 1000000 .+ 10000,
        x7 = rand(zones) .* 1000000 .+ 11000,
        x8 = rand(zones) .* 1000000 .+ 12000,
        x9 = rand(zones) .* 1000000 .+ 13000,
        x10 = rand(zones) .* 1000000 .+ 14000,
        x11 = rand(zones) .* 1000000 .+ 15000,
    )
    rename!(
        dfLand,
        [
            "Zone",
            "2013",
            "2014",
            "2015",
            "2016",
            "2017",
            "2018",
            "2019",
            "2020",
            "2021",
            "2022",
            "2023",
        ],
    )

    CSV.write(joinpath(path, "Land.csv"), dfLand)
end
