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
    fake_hydrogens_price(path::AbstractString, hydrogens::Array, time_length::Integer)

This function fakes imaginary hydrogen prices from nowhere.
"""
function fake_hydrogens_price(path::AbstractString, hydrogens::Array, time_length::Integer)

    ## Create time index
    df_hydrogens = DataFrame(Time_Index = vcat([0], 1:time_length))

    ## Create hydrogen types as columns
    df_hydrogens = hcat(
        df_hydrogens,
        DataFrame([hydrogen = zeros(time_length + 1) for hydrogen in hydrogens], :auto),
    )
    rename!(df_hydrogens, vcat(["Time_Index"], hydrogens))

    ## Fake hydrogens emission factor
    df_hydrogens[1, 2:end] = rand(length(hydrogens)) ./ 100

    ## Fake hydrogens prices
    for hydrogen in hydrogens
        df_hydrogens[2:(time_length + 1), hydrogen] = rand(time_length)
    end

    CSV.write(joinpath(path, "Hydrogen_data.csv"), df_hydrogens)

    return df_hydrogens
end
