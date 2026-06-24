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
    haversine(lon1::Float64, lat1::Float64, lon2::Float64, lat2::Float64, unit::AbstractString = "km")

This code defines haversine function that calculates the distance between two geographical coordinates.
The function uses the Haversine formula, a method for calculating the great-circle distance between two points on a sphere.

The function's parameters include:

lon1 and lat1: The longitude and latitude of the first geographical coordinate.
lon2 and lat2: The longitude and latitude of the second geographical coordinate.
unit: The unit of the calculated result, which can be kilometers ("km") or miles ("mi"). The default is "km".
The function first determines the radius R of the Earth based on the unit parameter.
If unit is neither "km" nor "mi", the function throws an error.
"""
function haversine(
    lon1::Float64,
    lat1::Float64,
    lon2::Float64,
    lat2::Float64,
    unit::AbstractString = "km",
)

    if unit == "km"
        R = 6371.0
    elseif unit == "mi"
        R = 3958.8
    else
        @error("Unit not recognized. Please use 'km' or 'mi'.")
    end

    dlat = deg2rad(lat2 - lat1)
    dlon = deg2rad(lon2 - lon1)

    a =
        sin(dlat / 2) * sin(dlat / 2) +
        cos(deg2rad(lat1)) * cos(deg2rad(lat2)) * sin(dlon / 2) * sin(dlon / 2)
    c = 2 * atan(sqrt(a), sqrt(1 - a))

    return R * c
end
