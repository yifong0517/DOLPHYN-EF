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
    fake_fuels_price(path::AbstractString, fuels::Array, time_length::Integer)

This function fakes imaginary fuel prices from nowhere.
"""
function fake_fuels_price(path::AbstractString, fuels::Array, time_length::Integer)

    ## Create time index
    df_fuels = DataFrame(Time_Index = vcat([0], 1:time_length))

    ## Create fuel types as columns
    df_fuels = hcat(df_fuels, DataFrame([fuel = zeros(time_length + 1) for fuel in fuels], :auto))
    rename!(df_fuels, vcat(["Time_Index"], fuels))

    ## Fake fuels emission factor
    df_fuels[1, 2:end] = rand(length(fuels)) ./ 100

    ## Fake fuels prices
    for fuel in fuels
        df_fuels[2:(time_length + 1), fuel] = rand(time_length)
    end

    CSV.write(joinpath(path, "Fuels_data.csv"), df_fuels)

    return df_fuels
end
