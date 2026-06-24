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
    fake_power_minimum_capacity(path::AbstractString, zones::Integer, generators::Dict{String, Int64})

This function fakes imaginary minimum capacity policy for MESS power sector from nowhere.
"""
function fake_power_minimum_capacity(
    path::AbstractString,
    zones::Integer,
    generators::Dict{String, Int64},
)

    resource_type = keys(generators)

    ## Construct minimum capacity policy dataframe
    df_minimum_capacity = DataFrame(Zone = string.(1:zones))

    ## Add resource columns
    for resource in resource_type
        df_minimum_capacity[!, resource] = zeros(zones)
    end

    ## Add total capacity policy row
    push!(df_minimum_capacity, vcat(["Total"], zeros(length(resource_type))))

    ## Write minimum capacity dataframe into csv file
    CSV.write(joinpath(path, "Policy_capacity_minimum.csv"), df_minimum_capacity)
end
