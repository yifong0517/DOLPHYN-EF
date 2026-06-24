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
    fake_power_primary_reserve(path::AbstractString, zones::Integer)

This function fakes imaginary primary reserve policy for MESS power sector from nowhere.
"""
function fake_power_primary_reserve(path::AbstractString, zones::Integer)

    ## Construct primary reserve policy dataframe
    df_preserve = DataFrame(
        Zone = string.(1:zones),
        PRSV_Percent_Load = rand(zones) ./ 100,
        PRSV_Percent_VRE = rand(zones) ./ 100,
    )

    ## Write primary reserve dataframe into csv file
    CSV.write(joinpath(path, "Policy_reserve.csv"), df_preserve)
end
