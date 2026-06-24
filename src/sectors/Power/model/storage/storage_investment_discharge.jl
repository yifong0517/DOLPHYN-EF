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
    storage_investment_discharge(settings::Dict, inputs::Dict, MESS::Model)

"""
function storage_investment_discharge(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Storage Discharge Investment Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Get power sector settings
    power_settings = settings["PowerSettings"]
    IncludeExistingSto = power_settings["IncludeExistingSto"]

    power_inputs = inputs["PowerInputs"]

    ## Number of storage resources
    S = power_inputs["S"]
    dfSto = power_inputs["dfSto"]

    ## Set of storage resources eligible for new capacity and retirements
    NEW_STO_CAP = power_inputs["NEW_STO_CAP"]
    RET_STO_CAP = power_inputs["RET_STO_CAP"]
    ResourceType = power_inputs["StoResourceType"]

    ### Variables ###
    ## New installed capacity of resource "s"
    @variable(MESS, vPNewStoDisCap[s in NEW_STO_CAP] >= 0)
    ## Retired capacity of resource "s" from existing capacity
    @variable(MESS, vPRetStoDisCap[s in RET_STO_CAP] >= 0)

    ### Expressions ###
    ## Existing capacity = existing capacity - retired capacity
    @expression(
        MESS,
        ePExiStoDisCap[s in 1:S],
        if s in RET_STO_CAP
            dfSto[!, :Existing_Dis_Cap_MW][s] - MESS[:vPRetStoDisCap][s]
        else
            dfSto[!, :Existing_Dis_Cap_MW][s]
        end
    )
    ## Total capacity = existing capacity + new capacity
    @expression(
        MESS,
        ePStoDisCap[s in 1:S],
        if s in NEW_STO_CAP
            MESS[:ePExiStoDisCap][s] + MESS[:vPNewStoDisCap][s]
        else
            MESS[:ePExiStoDisCap][s]
        end
    )

    @expression(
        MESS,
        ePStoDisCapOZRT[z in 1:Z, rt in ResourceType],
        sum(
            MESS[:ePStoDisCap][s] for
            s in dfSto[(dfSto.Zone .== Zones[z]) .& (dfSto.Resource_Type .== rt), :R_ID];
            init = 0.0,
        )
    )

    ## Objective Expressions ##
    ## Fixed costs for resource "s" = annuitized investment cost plus fixed O&M costs
    ## Annuitized investment costs for new built capacity
    @expression(
        MESS,
        ePObjFixInvStoDisOS[s in NEW_STO_CAP],
        (
            dfSto[!, :Inv_Cost_Dis_per_MW][s] * dfSto[!, :AF][s] +
            dfSto[!, :Fixed_OM_Cost_Dis_per_MW][s]
        ) * MESS[:vPNewStoDisCap][s]
    )
    @expression(
        MESS,
        ePObjFixInvStoDis,
        sum(MESS[:ePObjFixInvStoDisOS][s] for s in NEW_STO_CAP; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:ePObj], MESS[:ePObjFixInvStoDis])

    ## Annuitized investment costs for existing capacity
    if IncludeExistingSto > 0
        @expression(
            MESS,
            ePObjFixSunkInvStoDisOS[s in 1:S],
            AffExpr(
                (
                    dfSto[!, :Inv_Cost_Dis_per_MW][s] * dfSto[!, :AF][s] +
                    dfSto[!, :Fixed_OM_Cost_Dis_per_MW][s]
                ) * dfSto[!, :Existing_Dis_Cap_MW][s] / IncludeExistingSto,
            )
        )
        @expression(
            MESS,
            ePObjFixSunkInvStoDis,
            sum(MESS[:ePObjFixSunkInvStoDisOS][s] for s in 1:S; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:ePObj], MESS[:ePObjFixSunkInvStoDis])
    end

    ## Fixed O&M costs
    @expression(
        MESS,
        ePObjFixFomStoDisOS[s in 1:S],
        dfSto[!, :Fixed_OM_Cost_Dis_per_MW][s] * MESS[:ePExiStoDisCap][s] /
        (IncludeExistingSto > 0 ? IncludeExistingSto : 1)
    )
    @expression(
        MESS,
        ePObjFixFomStoDis,
        sum(MESS[:ePObjFixFomStoDisOS][s] for s in 1:S; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:ePObj], MESS[:ePObjFixFomStoDis])
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Constraints on retirements and capacity additions
    ## Cannot retire more capacity than existing capacity
    if !isempty(RET_STO_CAP)
        @constraint(
            MESS,
            cPStoMaxRetDisCap[s in RET_STO_CAP],
            MESS[:vPRetStoDisCap][s] <= dfSto[!, :Existing_Dis_Cap_MW][s]
        )
    end

    ## Constraints on new built capacity
    ## Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    if !isempty(intersect(1:S, dfSto[dfSto.Max_Dis_Cap_MW .> 0, :R_ID]))
        @constraint(
            MESS,
            cPStoMaxDisCap[s in intersect(1:S, dfSto[dfSto.Max_Dis_Cap_MW .> 0, :R_ID])],
            MESS[:ePStoDisCap][s] <= dfSto[!, :Max_Dis_Cap_MW][s]
        )
    end

    ## Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    if !isempty(intersect(1:S, dfSto[dfSto.Min_Dis_Cap_MW .> 0, :R_ID]))
        @constraint(
            MESS,
            cPStoMinDisCap[s in intersect(1:S, dfSto[dfSto.Min_Dis_Cap_MW .> 0, :R_ID])],
            MESS[:ePStoDisCap][s] >= dfSto[!, :Min_Dis_Cap_MW][s]
        )
    end
    ### End Constraints ###

    return MESS
end
