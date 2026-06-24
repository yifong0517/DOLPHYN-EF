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
    fake_power_generators_variability(path::AbstractString, zones::Integer, time_length::Integer, generators::Dict{String,Integer})

This function fakes imaginary generators variability from nowhere.
"""
function fake_power_generators_variability(
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

    ## Candidate generator list
    THERM_set = ["Nuclear", "CCGT", "CCGT_CCS", "OCGT_F"]
    VRE_set = ["PV", "Wind"]
    CCS_set = ["CCGT_CCS"]
    candidates = union(THERM_set, VRE_set, CCS_set)

    for column in columns
        resource_type = split(column, "_")[1]
        if resource_type in candidates
            if resource_type in VRE_set
                if resource_type == "Wind"
                    df_generators_variability[:, Cols(startswith("Wind"))] .=
                        rand(Float64, (time_length, generators["Wind"] * zones))
                elseif resource_type == "PV"
                    df_generators_variability[
                        (0 .<= df_generators_variability.Time_Index .% 24 .<= 7) .|| (18 .<= df_generators_variability.Time_Index .% 24 .<= 23),
                        Cols(startswith("PV")),
                    ] .= 0
                    df_generators_variability[
                        (8 .<= df_generators_variability.Time_Index .% 24 .<= 17),
                        Cols(startswith("PV")),
                    ] .= rand(Float64, (Int(time_length * 10 / 24), generators["PV"] * zones))
                end
            end
        end
    end

    CSV.write(joinpath(path, "Generators_variability.csv"), df_generators_variability)
end
