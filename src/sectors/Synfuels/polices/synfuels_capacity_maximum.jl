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
function synfuels_capacity_maximum(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Synfuels Sector Maximum Capacity Requirements Policy Module")

    ## Spatial and temporal index
    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Synfuels sector inputs
    synfuels_inputs = inputs["SynfuelsInputs"]
    dfGen = synfuels_inputs["dfGen"]
    dfMaxCap = synfuels_inputs["dfMaxCap"]
    ResourceType = synfuels_inputs["GenResourceType"]

    ## Synfuels sector settings
    synfuels_settings = settings["SynfuelsSettings"]

    MaxCapacity = synfuels_settings["MaxCapacity"]

    if MaxCapacity == 2
        ## Global system minimum capacity requirements policy
        @constraint(
            MESS,
            cSMaximumCapacity[rt in ResourceType],
            sum(MESS[:eSGenCapOZRT][z, rt] for z in 1:Z; init = 0.0) <=
            first(dfMaxCap[dfMaxCap.Zone .== "All", Symbol(rt)])
        )
    elseif MaxCapacity == 1
        ## Zonal minimum capacity requirements policy
        @constraint(
            MESS,
            cSMaximumCapacity[z in 1:Z, rt in ResourceType],
            MESS[:eSGenCapOZRT][z, rt] <= dfMaxCap[!, Symbol(rt)][z]
        )
    end

    return MESS
end
