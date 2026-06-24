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
function storage_discharge(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Synfuels Storage Discharge Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    synfuels_inputs = inputs["SynfuelsInputs"]
    dfSto = synfuels_inputs["dfSto"]

    S = synfuels_inputs["S"]
    ResourceType = synfuels_inputs["StoResourceType"]

    ### Variables ###
    @variable(MESS, vSStoDis[s in 1:S, t in 1:T] >= 0)

    ### Expressions ###
    ## Zonal discharge for each type of resource
    @expression(
        MESS,
        eSStoDisOZRT[z in 1:Z, rt in ResourceType],
        sum(
            MESS[:vSStoDis][s, t] * weights[t] for
            s in dfSto[(dfSto.Zone .== Zones[z]) .& (dfSto.Resource_Type .== rt), :R_ID], t in 1:T;
            init = 0.0,
        )
    )
    @expression(
        MESS,
        eSStoResourceDis[rt in ResourceType, t in 1:T],
        sum(MESS[:vSStoDis][s, t] for s in dfSto[dfSto.Resource_Type .== rt, :R_ID]; init = 0.0)
    )
    ## Objective Expressions ##
    ## Variable costs of "discharging" for technologies "s" during hour "t" in zone "z"
    @expression(
        MESS,
        eSObjVarStoDisOST[s in 1:S, t in 1:T],
        weights[t] * MESS[:vSStoDis][s, t] * dfSto[!, :Var_OM_Cost_Dis_per_tonne][s]
    )
    @expression(MESS, eSObjVarStoDisOS[s in 1:S], sum(MESS[:eSObjVarStoDisOST][s, t] for t in 1:T))
    @expression(MESS, eSObjVarStoDis, sum(MESS[:eSObjVarStoDisOS][s] for s in 1:S))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eSObj], MESS[:eSObjVarStoDis])
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constraints ###
    @constraint(
        MESS,
        cSStoMaxDis[s in 1:S, t in 1:T],
        MESS[:vSStoDis][s, t] <= MESS[:eSStoDisCap][s]
    )
    ### End Constraints ###

    return MESS
end
