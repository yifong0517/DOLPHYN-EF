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
function storage_charge(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Synfuels Storage Charge Module")

    Z = inputs["Z"]
    T = inputs["T"]
    weights = inputs["weights"]

    synfuels_inputs = inputs["SynfuelsInputs"]
    dfSto = synfuels_inputs["dfSto"]

    S = synfuels_inputs["S"]
    ResourceType = synfuels_inputs["StoResourceType"]

    ### Variables ###
    ## Energy withdrawn from grid by resource "s" at hour "t" [MWh]
    @variable(MESS, vSStoCha[s in 1:S, t in 1:T] >= 0)

    ### Expressions ###
    @expression(
        MESS,
        eSStoChaORTT[rt in ResourceType, t in 1:T],
        sum(MESS[:vSStoCha][s, t] for s in dfSto[dfSto.Resource_Type .== rt, :R_ID]; init = 0.0)
    )
    ## Variable costs of "charging" for technologies "s" during hour "t" in zone "z"
    @expression(
        MESS,
        eSObjVarStoChaOST[s in 1:S, t in 1:T],
        weights[t] * MESS[:vSStoCha][s, t] * dfSto[!, :Var_OM_Cost_Cha_per_tonne][s]
    )
    @expression(MESS, eSObjVarStoChaOS[s in 1:S], sum(MESS[:eSObjVarStoChaOST][s, t] for t in 1:T))
    @expression(MESS, eSObjVarStoCha, sum(MESS[:eSObjVarStoChaOS][s] for s in 1:S))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eSObj], MESS[:eSObjVarStoCha])
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Maximum charging rate must be less than charge synfuels rating
    @constraint(
        MESS,
        cSStoMaxCha[s in 1:S, t in 1:T],
        MESS[:vSStoCha][s, t] <= MESS[:eSStoChaCap][s]
    )
    ### End Constraints ###

    return MESS
end
