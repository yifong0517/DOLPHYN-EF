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
    fake_hydrogen_demand(path::AbstractString, zones::Integer, time_length::Integer)

This function fakes demand data of each zone from nowhere.
"""
function fake_hydrogen_demand(path::AbstractString, zones::Integer, time_length::Integer)

    ## Construct dynamic demand curve
    ## Create time index
    df_load = DataFrame(Time_Index = 1:time_length)

    ## Create zonal load identifier as columns
    df_load =
        hcat(df_load, DataFrame([zone = rand(time_length) .* 10000 for zone in 1:zones], :auto))
    rename!(df_load, vcat(["Time_Index"], ["Load_tonne_$zone" for zone in 1:zones]))

    ## Write load segment and time-varying load into csv files
    CSV.write(joinpath(path, "Demand.csv"), df_load)
end
