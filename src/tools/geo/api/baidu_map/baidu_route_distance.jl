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
function baidu_route_distance(
    lon1::Float64,
    lat1::Float64,
    lon2::Float64,
    lat2::Float64,
    unit::AbstractString = "km",
    ak::AbstractString = "",
    dir::AbstractString = "",
    key::AbstractString = "",
)

    # Retrive BaiduAPI key from system
    if ak == ""
        info = key !== "" ? baidu_map_api_key(dir, key) : baidu_map_api_key(dir)
        ak = info["AK"]
    end

    # Round coordinates to digits of 6
    lon1, lat1, lon2, lat2 = round.((lon1, lat1, lon2, lat2); digits = 6)

    # Baidu route API url
    url = "http://api.map.baidu.com/directionlite/v1/driving?origin=$(lat1),$(lon1)&destination=$(lat2),$(lon2)&ak=$(ak)"
    response = HTTP.get(url)
    json = JSON.Parser.parse(String(response.body))

    if json["status"] != 200
        error("Error: $(json["message"])")
    end

    if unit == "km"
        return json["result"]["routes"][1]["distance"] / 1000
    elseif unit == "mi"
        return json["result"]["routes"][1]["distance"] / 1609
    end
end
