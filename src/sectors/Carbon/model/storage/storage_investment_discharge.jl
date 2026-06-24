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

    print_and_log(settings, "i", "Carbon Storage Discharge Investment Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Get carbon sector settings
    carbon_settings = settings["CarbonSettings"]
    IncludeExistingSto = carbon_settings["IncludeExistingSto"]

    carbon_inputs = inputs["CarbonInputs"]

    ## Number of storage resources
    S = carbon_inputs["S"]
    dfSto = carbon_inputs["dfSto"]

    ## Set of storage resources eligible for new capacity and retirements
    NEW_STO_CAP = carbon_inputs["NEW_STO_CAP"]
    RET_STO_CAP = carbon_inputs["RET_STO_CAP"]
    ResourceType = carbon_inputs["StoResourceType"]

    ### Variables ###
    ## New installed capacity of resource "s"
    @variable(MESS, vCNewStoDisCap[s in NEW_STO_CAP] >= 0)
    ## Retired capacity of resource "s" from existing capacity
    @variable(MESS, vCRetStoDisCap[s in RET_STO_CAP] >= 0)

    ### Expressions ###
    @expression(
        MESS,
        eCStoDisCap[s in 1:S],
        ## Storage resources eligible for new capacity and retirements
        if s in intersect(NEW_STO_CAP, RET_STO_CAP)
            dfSto[!, :Existing_Dis_Cap_tonne_per_hr][s] + MESS[:vCNewStoDisCap][s] -
            MESS[:vCRetStoDisCap][s]
            ## Storage resources eligible for only new capacity
        elseif s in setdiff(NEW_STO_CAP, RET_STO_CAP)
            dfSto[!, :Existing_Dis_Cap_tonne_per_hr][s] + MESS[:vCNewStoDisCap][s]
            ## Storage resources eligible for only capacity retirements
        elseif s in setdiff(RET_STO_CAP, NEW_STO_CAP)
            dfSto[!, :Existing_Dis_Cap_tonne_per_hr][s] - MESS[:vCRetStoDisCap][s]
            ## Storage resources not eligible for new capacity or retirements
        else
            dfSto[!, :Existing_Dis_Cap_tonne_per_hr][s]
        end
    )

    @expression(
        MESS,
        eCStoCapOZRT[z in 1:Z, rt in ResourceType],
        sum(
            MESS[:eCStoDisCap][s] for
            s in dfSto[(dfSto.Zone .== Zones[z]) .& (dfSto.Resource_Type .== rt), :R_ID];
            init = 0.0,
        )
    )

    ## Objective Expressions ##
    ## Fixed costs for resource "s" = annuitized investment cost plus fixed O&M costs
    ## Annuitized investment costs for new built capacity
    @expression(
        MESS,
        eCObjFixInvStoDisOS[s in NEW_STO_CAP],
        dfSto[!, :Inv_Cost_Dis_per_tonne_per_hr][s] * dfSto[!, :AF][s] * MESS[:vCNewStoDisCap][s]
    )
    @expression(
        MESS,
        eCObjFixInvStoDis,
        sum(MESS[:eCObjFixInvStoDisOS][s] for s in NEW_STO_CAP; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eCObj], MESS[:eCObjFixInvStoDis])

    ## Annuitized investment costs for existing capacity
    if IncludeExistingSto == 1
        @expression(
            MESS,
            eCObjFixSunkInvStoDisOS[s in 1:S],
            AffExpr(
                dfSto[!, :Inv_Cost_Dis_per_tonne_per_hr][s] *
                dfSto[!, :AF][s] *
                dfSto[!, :Existing_Dis_Cap_tonne_per_hr][s],
            )
        )
        @expression(
            MESS,
            eCObjFixSunkInvStoDis,
            sum(MESS[:eCObjFixSunkInvStoDisOS][s] for s in 1:S; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:eCObj], MESS[:eCObjFixSunkInvStoDis])
    end

    ## Fixed O&M costs
    @expression(
        MESS,
        eCObjFixFomStoDisOS[s in 1:S],
        dfSto[!, :Fixed_OM_Cost_Dis_per_tonne_per_hr][s] * MESS[:eCStoDisCap][s]
    )
    @expression(
        MESS,
        eCObjFixFomStoDis,
        sum(MESS[:eCObjFixFomStoDisOS][s] for s in 1:S; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eCObj], MESS[:eCObjFixFomStoDis])
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Constraints on retirements and capacity additions
    ## Cannot retire more capacity than existing capacity
    if !isempty(RET_STO_CAP)
        @constraint(
            MESS,
            cCStoMaxRetDisCap[s in RET_STO_CAP],
            MESS[:vCRetStoDisCap][s] <= dfSto[!, :Existing_Dis_Cap_tonne_per_hr][s]
        )
    end

    ## Constraints on new built capacity
    ## Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    if !isempty(intersect(1:S, dfSto[dfSto.Max_Dis_Cap_tonne_per_hr .>= 0, :R_ID]))
        @constraint(
            MESS,
            cCStoMaxDisCap[s in intersect(1:S, dfSto[dfSto.Max_Dis_Cap_tonne_per_hr .>= 0, :R_ID])],
            MESS[:eCStoDisCap][s] <= dfSto[!, :Max_Dis_Cap_tonne_per_hr][s]
        )
    end

    ## Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    if !isempty(intersect(1:S, dfSto[dfSto.Min_Dis_Cap_tonne_per_hr .>= 0, :R_ID]))
        @constraint(
            MESS,
            cCStoMinDisCap[s in intersect(1:S, dfSto[dfSto.Min_Dis_Cap_tonne_per_hr .>= 0, :R_ID])],
            MESS[:eCStoDisCap][s] >= dfSto[!, :Min_Dis_Cap_tonne_per_hr][s]
        )
    end
    ### End Constraints ###

    return MESS
end
