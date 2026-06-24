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

    print_and_log(settings, "i", "Power Storage Charge Module")

    Z = inputs["Z"]
    T = inputs["T"]
    weights = inputs["weights"]

    ## Get power sector settings
    power_settings = settings["PowerSettings"]
    PReserve = power_settings["PReserve"]

    power_inputs = inputs["PowerInputs"]
    dfSto = power_inputs["dfSto"]

    S = power_inputs["S"]
    if PReserve == 1
        STO_PRSV = power_inputs["STO_PRSV"]
    end
    ResourceType = power_inputs["StoResourceType"]

    STO_SYMMETRIC = power_inputs["STO_SYMMETRIC"]
    STO_ASYMMETRIC = power_inputs["STO_ASYMMETRIC"]

    ### Variables ###
    ## Energy withdrawn from grid by resource "s" at hour "t" [MWh]
    @variable(MESS, vPStoCha[s in 1:S, t in 1:T] >= 0)
    ## Storage primary reserves during charge
    if PReserve == 1
        @variable(MESS, vPStoChaPRSV[s in STO_PRSV, t = 1:T] >= 0)
    end

    ### Expressions ###
    @expression(
        MESS,
        ePStoChaORTT[rt in ResourceType, t in 1:T],
        sum(MESS[:vPStoCha][s, t] for s in dfSto[dfSto.Resource_Type .== rt, :R_ID]; init = 0.0)
    )
    ## Objective Expressions ##
    ## Variable costs of "charging" for technologies "s" during hour "t" in zone "z"
    @expression(
        MESS,
        ePObjVarStoChaOST[s in 1:S, t in 1:T],
        weights[t] * MESS[:vPStoCha][s, t] * dfSto[!, :Var_OM_Cost_Cha_per_MWh][s]
    )
    @expression(
        MESS,
        ePObjVarStoChaOS[s in 1:S],
        sum(MESS[:ePObjVarStoChaOST][s, t] for t in 1:T; init = 0.0)
    )
    @expression(MESS, ePObjVarStoCha, sum(MESS[:ePObjVarStoChaOS][s] for s in 1:S; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:ePObj], MESS[:ePObjVarStoCha])
    ## End Objective Expressions ##

    if PReserve == 1
        ## Reserve costs of "storage" for resource "g" during hour "t"
        @expression(
            MESS,
            ePObjReserveStoChaOST[s in STO_PRSV, t in 1:T],
            weights[t] * dfSto[!, :PRSV_Cost][s] * MESS[:vPStoChaPRSV][s, t]
        )

        ## Add total variable storage reserve charge cost contribution to objective function
        @expression(
            MESS,
            ePObjReserveStoChaOS[s in STO_PRSV],
            sum(MESS[:ePObjReserveStoChaOST][s, t] for t in 1:T; init = 0.0)
        )
        @expression(
            MESS,
            ePObjReserveStoCha,
            sum(MESS[:ePObjReserveStoChaOS][s] for s in STO_PRSV; init = 0.0)
        )
        add_to_expression!(MESS[:ePObj], MESS[:ePObjReserveStoCha])
    end
    ### End Expressions ###

    ### Constraints ###
    if PReserve == 1
        ## Maximum charging rate must be less than charge power rating
        if !isempty(intersect(STO_PRSV, STO_ASYMMETRIC))
            @constraint(
                MESS,
                cPASYStoChaMaxPrimaryReserve[s in intersect(STO_PRSV, STO_ASYMMETRIC), t in 1:T],
                MESS[:vPStoCha][s, t] + MESS[:vPStoChaPRSV][s, t] <= MESS[:ePStoChaCap][s]
            )
            @constraint(
                MESS,
                cPSYSStoChaMaxPrimaryReserve[s in intersect(STO_PRSV, STO_SYMMETRIC), t in 1:T],
                MESS[:vPStoCha][s, t] + MESS[:vPStoChaPRSV][s, t] <= MESS[:ePStoDisCap][s]
            )
        end
        ## Maximum storage contribution to reserves is a specified fraction of installed capacity
        if !isempty(STO_PRSV)
            @constraint(
                MESS,
                cPSYSStoMaxDisChaPrimaryReserve[s in STO_PRSV, t in 1:T],
                MESS[:vPStoDisPRSV][s, t] + MESS[:vPStoChaPRSV][s, t] <=
                dfSto[!, :PRSV_Max][s] * MESS[:ePStoDisCap][s]
            )
        end
    else
        ## Maximum charging rate must be less than charge power rating
        if !isempty(STO_ASYMMETRIC)
            @constraint(
                MESS,
                cPASYStoMaxCha[s in STO_ASYMMETRIC, t in 1:T],
                MESS[:vPStoCha][s, t] <= MESS[:ePStoChaCap][s]
            )
        end
        if !isempty(STO_SYMMETRIC)
            ## Maximum charging rate must be less than symmetric power rating
            @constraint(
                MESS,
                cPSYSStoMaxCha[s in STO_SYMMETRIC, t in 1:T],
                MESS[:vPStoCha][s, t] <= MESS[:ePStoDisCap][s]
            )
            ## Max simultaneous charge and discharge cannot be greater than capacity
            @constraint(
                MESS,
                cPSYStoMaxDisCha[s in STO_SYMMETRIC, t in 1:T],
                MESS[:vPStoDis][s, t] + MESS[:vPStoCha][s, t] <= MESS[:ePStoDisCap][s]
            )
        end
    end
    ### End Constraints ###

    return MESS
end
