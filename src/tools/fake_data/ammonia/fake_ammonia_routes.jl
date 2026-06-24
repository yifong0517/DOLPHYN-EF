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
    fake_ammonia_routes(path::AbstractString, zones::Integer)

This function fakes ammonia truck routes data from nowhere.
"""
function fake_ammonia_routes(path::AbstractString, zones::Integer)

    ## Compute factorial number
    routes = binomial(zones, 2)

    ## Generate zone list
    Zones = string.(1:zones)

    df_routes = DataFrame(Route_Name = 1:routes, Distance = rand(routes) .* 240)

    ## Lines map
    df_routes_map = DataFrame(Start_Zone = String[], End_Zone = String[])
    routes_map = collect(Combinatorics.combinations(Zones, 2))
    for r in 1:routes
        push!(df_routes_map, routes_map[r])
    end

    ## Merge routes map into routes dataframe
    df_routes = hcat(df_routes, df_routes_map)

    CSV.write(joinpath(path, "routes.csv"), df_routes)
end
