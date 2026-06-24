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
    fake_hydrogen_carbon_cap(path::AbstractString, zones::Integer)

This function fakes imaginary carbon cap for MESS from nowhere.
"""
function fake_hydrogen_carbon_cap(path::AbstractString, zones::Integer)

    ## Construct carbon emission cap
    df_co2_cap = DataFrame(
        Zone = string.(1:zones),
        Emission_Max_Mtons = rand(zones),
        Emission_Max_Tons_tonne = rand(zones),
        Emission_Price_tonne = rand(zones) .* 1000,
    )

    ## Write carbon cap dataframe into csv file
    CSV.write(joinpath(path, "Policy_emission.csv"), df_co2_cap)
end
