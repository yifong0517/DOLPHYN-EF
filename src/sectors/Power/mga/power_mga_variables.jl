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
function power_mga_variables(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Sector Modeling to Generate Alternative Variable Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]

    T = inputs["T"]
    Time_Index = inputs["Time_Index"]
    weights = inputs["weights"]

    power_inputs = inputs["PowerInputs"]
    ResourceType = power_inputs["GenResourceType"]
    dfGen = power_inputs["dfGen"]
    RT = length(ResourceType)

    ### Variables ###
    # Variable denoting total generation from eligible technology of a given type
    @variable(MESS, vPMGAGenSum[rt = 1:RT, z = 1:Z] >= 0)

    ### Constraints ###
    ## Constraint to compute total generation in each zone from a given Technology Type
    @constraint(
        MESS,
        cPMGAGeneration[rt in 1:RT, z = 1:Z],
        vPMGAGenSum[rt, z] == sum(
            MESS[:vPGen][g, t] * weights[t] for g in dfGen[
                (dfGen[!, :Resource_Type] .== ResourceType[rt]) .& (dfGen[!, :Zone] .== Zones[z]),
                :R_ID,
            ], t in 1:T
        )
    )

    ### End Constraints ###

    return MESS
end
