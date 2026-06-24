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
    fake_hydrogen_generators_variability(path::AbstractString, zones::Integer, time_length::Integer, generators::Dict{String,Integer})

This function fakes imaginary generators variability from nowhere.
"""
function fake_hydrogen_generators_variability(
    path::AbstractString,
    zones::Integer,
    time_length::Integer,
    generators::Dict{String, Int64},
)

    ## Generate zone list
    Zones = string.(1:zones)

    ## Construct the column names
    columns =
        collect("$(key)_$(i)_$(z)" for (key, value) in generators for i in 1:value for z in Zones)

    ## Construct dataframe with time index
    df_generators_variability = DataFrame(Time_Index = 1:time_length)

    ## Construct dataframe with initial variabilities of generators
    df_generators_variability =
        hcat(df_generators_variability, DataFrame(ones((time_length, length(columns))), :auto))

    ## Rename dataframe
    auxnames = [Symbol("Time_Index"); [Symbol("$column") for column in columns]]
    rename!(df_generators_variability, auxnames)

    CSV.write(joinpath(path, "Generators_variability.csv"), df_generators_variability)
end
