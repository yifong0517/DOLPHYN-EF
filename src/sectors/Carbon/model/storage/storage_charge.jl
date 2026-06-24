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

    print_and_log(settings, "i", "Carbon Storage Charge Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
    end

    carbon_inputs = inputs["CarbonInputs"]
    dfSto = carbon_inputs["dfSto"]

    S = carbon_inputs["S"]
    ResourceType = carbon_inputs["StoResourceType"]

    ### Variables ###
    ## Carbon withdrawn from grid by resource "s" at hour "t" [tonne]
    @variable(MESS, vCStoCha[s in 1:S, t in 1:T] >= 0)

    ### Expressions ###
    @expression(
        MESS,
        eCStoChaORTT[rt in ResourceType, t in 1:T],
        sum(MESS[:vCStoCha][s, t] for s in dfSto[dfSto.Resource_Type .== rt, :R_ID]; init = 0.0)
    )
    ## Objective Expressions ##
    ## Variable costs of "charging" for technologies "s" during hour "t" in zone "z"
    @expression(
        MESS,
        eCObjVarStoChaOST[s in 1:S, t in 1:T],
        weights[t] * MESS[:vCStoCha][s, t] * dfSto[!, :Var_OM_Cost_Cha_per_tonne][s]
    )
    @expression(
        MESS,
        eCObjVarStoChaOS[s in 1:S],
        sum(MESS[:eCObjVarStoChaOST][s, t] for t in 1:T; init = 0.0)
    )
    @expression(MESS, eCObjVarStoCha, sum(MESS[:eCObjVarStoChaOS][s] for s in 1:S))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eCObj], MESS[:eCObjVarStoCha])
    ## End Objective Expressions ##

    ## Electricity consumption from state change of carbon
    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceCStoChaCondition[z = 1:Z, t = 1:T],
            sum(
                dfSto[!, :Stor_Charge_MWh_per_tonne][s] * MESS[:vCStoCha][s, t] for
                s in dfSto[dfSto.Zone .== Zones[z], :R_ID];
                init = 0.0,
            )
        )

        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceCStoChaCondition])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceCStoChaCondition])
    else
        @expression(
            MESS,
            eCElectricityConsumptionStoChaCondition[
                f in eachindex(Electricity_Index),
                z = 1:Z,
                t = 1:T,
            ],
            sum(
                dfSto[:, :Stor_Charge_MWh_per_tonne][s] * MESS[:vCStoCha][s, t] for s in intersect(
                    dfSto[dfSto.Zone .== Zones[z], :R_ID],
                    dfSto[dfSto.Electricity .== Electricity_Index[f], :R_ID],
                );
                init = 0.0,
            )
        )
        add_to_expression!.(
            MESS[:eCElectricityConsumption],
            MESS[:eCElectricityConsumptionStoChaCondition],
        )
    end
    ### End Expressions ###

    ### Constraints ###
    ## Maximum charging rate must be less than charge power rating
    @constraint(
        MESS,
        cCStoMaxCha[s in 1:S, t in 1:T],
        MESS[:vCStoCha][s, t] <= MESS[:eCStoChaCap][s]
    )
    ### End Constraints ###

    return MESS
end
