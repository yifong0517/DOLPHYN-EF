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
function power_mga_objective(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Sector Modeling to Generate Alternative Objective Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]

    T = inputs["T"]
    Time_Index = inputs["Time_Index"]
    weights = inputs["weights"]

    power_inputs = inputs["PowerInputs"]
    ResourceType = power_inputs["GenResourceType"]
    dfGen = power_inputs["dfGen"]
    RT = length(ResourceType)

    ## Remove power sector MGA from previous model
    if haskey(MESS, :ePMGAObjective)
        unregister(MESS, :ePMGAObjective)
    end

    ### Expressions ###
    ## Create random coefficients for the generators that we want to include in the MGA run for the given budget
    coefficients = rand(RT, Z)
    @expression(
        MESS,
        ePMGAObjective,
        sum(coefficients[rt, z] * MESS[:vPMGAGenSum][rt, z] for rt in 1:RT, z in 1:Z)
    )
    ### End Expressions ###

    add_to_expression!(MESS[:eMGAObjective], MESS[:ePMGAObjective])

    return MESS
end
