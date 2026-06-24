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
function modify_power_generator_cap(power_settings::Dict, power_inputs::Dict)

    GenerationExpansion = power_settings["GenerationExpansion"]

    G = power_inputs["G"]
    dfGen = power_inputs["dfGen"]

    ## Set of all resources eligible for new capacity
    if GenerationExpansion == -1
        power_inputs["NEW_GEN_CAP"] = Int64[]
    elseif GenerationExpansion == 0
        power_inputs["NEW_GEN_CAP"] = dfGen[dfGen.New_Build .== 1, :R_ID]
    elseif GenerationExpansion == 1
        power_inputs["NEW_GEN_CAP"] = 1:G
    end
    power_inputs["NEW_GEN_CAP"] = intersect(
        power_inputs["NEW_GEN_CAP"],
        union(
            dfGen[dfGen.Max_Cap_MW .== -1, :R_ID],
            intersect(
                dfGen[dfGen.Max_Cap_MW .!= -1, :R_ID],
                dfGen[dfGen.Max_Cap_MW .- dfGen.Existing_Cap_MW .> 0, :R_ID],
            ),
        ),
    )
    ## Set of all resources eligible for capacity retirements
    power_inputs["RET_GEN_CAP"] =
        intersect(dfGen[dfGen.Retirement .== 1, :R_ID], dfGen[dfGen.Existing_Cap_MW .> 0, :R_ID])

    return power_inputs
end
