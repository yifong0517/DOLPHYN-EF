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
    subzone(df::DataFrame, key::Union{Symbol, Vector{Symbol}}, subzone::Symbol)

This function generates subzones for the dataframe based on the key column. The subzone column is added to the dataframe
in the form of "Zone_Subzone". The function returns the modified dataframe with subzones information.
"""
function subzone(df::DataFrame, key::Union{Symbol, Vector{Symbol}}, subzone::Symbol = :SubZone)

    ## Group the dataframe by zone
    gdf = groupby(df, :Zone)
    SubZoneMapping = Dict()
    SubZones = []

    ## Generate the subzone mapping
    for z in keys(gdf)
        SubZoneMapping[z[1]] = Dict()
        SubZone = unique(gdf[z][!, key])
        if typeof(key) == Symbol
            for i in eachindex(SubZone)
                SubZoneMapping[z[1]][SubZone[i]] = z[1] * "_" * string(i)
                push!(SubZones, z[1] * "_" * string(i))
            end
        elseif typeof(key) == Vector{Symbol}
            j = 0
            for i in Tuple.(eachrow(SubZone))
                j += 1
                SubZoneMapping[z[1]][i] = z[1] * "_" * string(j)
                push!(SubZones, z[1] * "_" * string(j))
            end
        end
    end

    ## Add the subzone column to the dataframe
    if typeof(key) == Symbol
        transform!(df, [:Zone, key] => ByRow((z, k) -> SubZoneMapping[z][k]) => subzone)
    elseif typeof(key) == Vector{Symbol}
        transform!(df, [:Zone; key] => ByRow((z, k...) -> SubZoneMapping[z][Tuple(k)]) => subzone)
    end

    return df, SubZones
end
