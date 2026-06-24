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
function carbon_capacity_minimum(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Carbon Sector Minimum Capacity Requirements Policy Module")

    ## Spatial and temporal index
    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Carbon sector inputs
    carbon_inputs = inputs["CarbonInputs"]
    dfGen = carbon_inputs["dfGen"]
    dfMinCap = carbon_inputs["dfMinCap"]
    ResourceType = carbon_inputs["GenResourceType"]

    ## Carbon sector settings
    carbon_settings = settings["CarbonSettings"]

    MinCapacity = carbon_settings["MinCapacity"]

    if MinCapacity == 2
        ## Global system minimum capacity requirements policy
        @constraint(
            MESS,
            cCMinimumCapacity[rt in ResourceType],
            sum(MESS[:eCCaptureCapOZRT][z, rt] for z in 1:Z; init = 0.0) >=
            first(dfMinCap[dfMinCap.Zone .== "All", Symbol(rt)])
        )
    elseif MinCapacity == 1
        ## Zonal minimum capacity requirements policy
        @constraint(
            MESS,
            cCMinimumCapacity[z in 1:Z, rt in ResourceType],
            MESS[:eCCaptureCapOZRT][z, rt] >= dfMinCap[!, Symbol(rt)][z]
        )
    end

    return MESS
end
