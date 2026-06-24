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
function bing_route_distance(
    lon1::Float64,
    lat1::Float64,
    lon2::Float64,
    lat2::Float64,
    unit::AbstractString = "km",
    ak::AbstractString = "",
    dir::AbstractString = "",
    key::AbstractString = "",
)

    # Retrive Bing Map key from system
    if ak == ""
        info = key !== "" ? bing_map_api_key(dir, key) : bing_map_api_key(dir)
        ak = info["AK"]
    end

    # Bing Map route API url
    url = "http://dev.virtualearth.net/REST/V1/Routes?wp.0=$(lat1),$(lon1)&wp.1=$(lat2),$(lon2)&distanceUnit=$(unit)&key=$(ak)"
    response = HTTP.get(url)
    json = JSON.parse(String(response.body))

    if json["statusCode"] != 200
        error("Error: $(json["statusDescription"])")
    end

    return json["resourceSets"][1]["resources"][1]["travelDistance"]
end
