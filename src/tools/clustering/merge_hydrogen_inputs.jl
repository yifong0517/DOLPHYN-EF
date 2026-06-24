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

"""
function merge_hydrogen_inputs(features::DataFrame, inputs::Dict, Zones::Vector)

    ## Construct the features dataframe from maximum capacity by block
    P_Max = DataFrame(transpose(inputs["P_Max"]), "Hydrogen " .* inputs["RESOURCES"])

    ## Concat maximum capacity onto features dataframe
    features = hcat(features, P_Max)

    ## Construct the features dataframe from demand by block
    Demand = DataFrame(transpose(inputs["D"]), Zones .* "_" .* " Hydrogen Demand")

    ## Concat demand onto features dataframe
    features = hcat(features, Demand)

    return features
end
