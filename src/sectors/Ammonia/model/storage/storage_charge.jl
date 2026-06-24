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

    print_and_log(settings, "i", "Ammonia Storage Charge Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
    end

    ammonia_inputs = inputs["AmmoniaInputs"]
    dfSto = ammonia_inputs["dfSto"]

    S = ammonia_inputs["S"]
    ResourceType = ammonia_inputs["StoResourceType"]

    ### Variables ###
    ## Energy withdrawn from grid by resource "s" at hour "t" [MWh]
    @variable(MESS, vAStoCha[s in 1:S, t in 1:T] >= 0)

    ### Expressions ###
    @expression(
        MESS,
        eAStoChaORTT[rt in ResourceType, t in 1:T],
        sum(MESS[:vAStoCha][s, t] for s in dfSto[dfSto.Resource_Type .== rt, :R_ID]; init = 0.0)
    )
    ## Objective Expressions ##
    ## Variable costs of "charging" for technologies "s" during hour "t" in zone "z"
    @expression(
        MESS,
        eAObjVarStoChaOST[s in 1:S, t in 1:T],
        weights[t] * MESS[:vAStoCha][s, t] * dfSto[!, :Var_OM_Cost_Cha_per_tonne][s]
    )
    @expression(MESS, eAObjVarStoChaOS[s in 1:S], sum(MESS[:eAObjVarStoChaOST][s, t] for t in 1:T))
    @expression(MESS, eAObjVarStoCha, sum(MESS[:eAObjVarStoChaOS][s] for s in 1:S))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eAObj], MESS[:eAObjVarStoCha])
    ### End Expressions ###

    ## Electricity consumption from state change of ammonia
    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceAStoChaCondition[z = 1:Z, t = 1:T],
            sum(
                dfSto[!, :Stor_Charge_MWh_per_tonne][s] * MESS[:vAStoCha][s, t] for
                s in dfSto[dfSto.Zone .== Zones[z], :R_ID];
                init = 0.0,
            )
        )

        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceAStoChaCondition])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceAStoChaCondition])
    else
        @expression(
            MESS,
            eAElectricityConsumptionStoChaCondition[
                f in eachindex(Electricity_Index),
                z = 1:Z,
                t = 1:T,
            ],
            sum(
                dfSto[:, :Stor_Charge_MWh_per_tonne][s] * MESS[:vAStoCha][s, t] for s in intersect(
                    dfSto[dfSto.Zone .== Zones[z], :R_ID],
                    dfSto[dfSto.Electricity .== Electricity_Index[f], :R_ID],
                );
                init = 0.0,
            )
        )
        add_to_expression!.(
            MESS[:eAElectricityConsumption],
            MESS[:eAElectricityConsumptionStoChaCondition],
        )
    end
    ### End Expressions ###

    ### Constraints ###
    ## Maximum charging rate must be less than charge ammonia rating
    @constraint(
        MESS,
        cAStoMaxCha[s in 1:S, t in 1:T],
        MESS[:vAStoCha][s, t] <= MESS[:eAStoChaCap][s]
    )
    ### End Constraints ###

    return MESS
end
