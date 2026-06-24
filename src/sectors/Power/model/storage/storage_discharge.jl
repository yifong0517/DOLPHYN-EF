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

    print_and_log(settings, "i", "Power Storage Discharge Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
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

    ### Variables ###
    ## Energy injected into grid by resource "s" at hour "t" [MWh]
    @variable(MESS, vPStoDis[s in 1:S, t in 1:T] >= 0)
    ## Storage primary reserves during discharge
    if PReserve == 1
        @variable(MESS, vPStoDisPRSV[s in STO_PRSV, t = 1:T] >= 0)
    end

    ### Expressions ###
    ## Zonal discharge for each type of resource
    @expression(
        MESS,
        ePStoDisOZRT[z in 1:Z, rt in ResourceType],
        sum(
            MESS[:vPStoDis][s, t] * weights[t] for
            s in dfSto[(dfSto.Zone .== Zones[z]) .& (dfSto.Resource_Type .== rt), :R_ID], t in 1:T;
            init = 0.0,
        )
    )
    @expression(
        MESS,
        ePStoDisORTT[rt in ResourceType, t in 1:T],
        sum(MESS[:vPStoDis][s, t] for s in dfSto[dfSto.Resource_Type .== rt, :R_ID]; init = 0.0)
    )
    ## Variable costs of "discharging" for technologies "s" during hour "t" in zone "z"
    @expression(
        MESS,
        ePObjVarStoDisOST[s in 1:S, t in 1:T],
        weights[t] * MESS[:vPStoDis][s, t] * dfSto[!, :Var_OM_Cost_Dis_per_MWh][s]
    )
    @expression(
        MESS,
        ePObjVarStoDisOS[s in 1:S],
        sum(MESS[:ePObjVarStoDisOST][s, t] for t in 1:T; init = 0.0)
    )
    @expression(MESS, ePObjVarStoDis, sum(MESS[:ePObjVarStoDisOS][s] for s in 1:S; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:ePObj], MESS[:ePObjVarStoDis])
    ## End Objective Expressions ##

    if PReserve == 1
        ## Reserve costs of "storage" for resource "g" during hour "t"
        @expression(
            MESS,
            ePObjReserveStoDisOST[s in STO_PRSV, t in 1:T],
            weights[t] * dfSto[!, :PRSV_Cost][s] * MESS[:vPStoDisPRSV][s, t]
        )

        ## Add total variable storage reserve discharge cost contribution to objective function
        @expression(
            MESS,
            ePObjReserveStoDisOS[s in STO_PRSV],
            sum(MESS[:ePObjReserveStoDisOST][s, t] for t in 1:T; init = 0.0)
        )
        @expression(
            MESS,
            ePObjReserveStoDis,
            sum(MESS[:ePObjReserveStoDisOS][s] for s in STO_PRSV; init = 0.0)
        )
        add_to_expression!(MESS[:ePObj], MESS[:ePObjReserveStoDis])
    end
    ### End Expressions ###

    ### Constraints ###
    if PReserve == 1 && !isempty(STO_PRSV)
        ## Maximum discharging rate and contribution to reserves up must be less than power rating OR available stored energy in prior period, whichever is less
        ## wrapping from end of sample period to start of sample period for energy capacity constraint
        @constraint(
            MESS,
            cPStoDisMaxPrimaryReserveUp[s in STO_PRSV, t = 1:T],
            MESS[:vPStoDis][s, t] + MESS[:vPStoDisPRSV][s, t] <= MESS[:ePStoDisCap][s]
        )
        ## Maximum discharging rate minus contribution to reserves down must be greater than zero
        ## Note: when discharging, reducing discharge rate is contributing to downwards regulation as it drops net supply
        @constraint(
            MESS,
            cPStoDisMaxPrimaryReserveDn[s in STO_PRSV, t in 1:T],
            MESS[:vPStoDis][s, t] >= MESS[:vPStoDisPRSV][s, t]
        )
    else
        @constraint(
            MESS,
            cPStoMaxDis[s in 1:S, t in 1:T],
            MESS[:vPStoDis][s, t] <= MESS[:ePStoDisCap][s]
        )
    end
    ### End Constraints ###

    return MESS
end
