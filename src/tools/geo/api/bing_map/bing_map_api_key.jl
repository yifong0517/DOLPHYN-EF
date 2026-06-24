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
function bing_map_api_key(dir::AbstractString = "", key::AbstractString = "MESS-route-key")

    if dir == ""
        # Store BingMapAPI information in ~/.bingapirc by default
        file = joinpath(homedir(), ".bingapirc")
    else
        # Store BingMapAPI information in dir/.bingapirc file
        if isdir(dir) && isfile(joinpath(dir, ".bingapirc"))
            file = joinpath(dir, ".bingapirc")
        else
            @error("Bing Map API directory $dir does not exist")
        end
    end
    lines = readlines(file)

    # Dict object that stores baidu api information
    info = Dict()

    # Extract AK from .bingapirc with key
    for line in lines
        line = strip(line)
        if startswith(line, key)
            info["AK"] = split(line, " ")[2]
        end
    end

    if isempty(info)
        @error("Invalid Key for Retrieving Bing Map API")
    end

    return info
end
