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

    print_and_log(settings, "i", "Synfuels Storage Discharge Investment Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Get synfuels sector settings
    synfuels_settings = settings["SynfuelsSettings"]
    IncludeExistingSto = synfuels_settings["IncludeExistingSto"]

    synfuels_inputs = inputs["SynfuelsInputs"]

    ## Number of storage resources
    S = synfuels_inputs["S"]
    dfSto = synfuels_inputs["dfSto"]

    ## Set of storage resources eligible for new capacity and retirements
    NEW_STO_CAP = synfuels_inputs["NEW_STO_CAP"]
    RET_STO_CAP = synfuels_inputs["RET_STO_CAP"]
    ResourceType = synfuels_inputs["StoResourceType"]

    ### Variables ###
    ## New installed capacity of resource "s"
    @variable(MESS, vSNewStoDisCap[s in NEW_STO_CAP] >= 0)
    ## Retired capacity of resource "s" from existing capacity
    @variable(MESS, vSRetStoDisCap[s in RET_STO_CAP] >= 0)

    ### Expressions ###
    ## Existing capacity = existing capacity - retired capacity
    @expression(
        MESS,
        eSExiStoDisCap[s in 1:S],
        if s in RET_STO_CAP
            dfSto[!, :Existing_Dis_Cap_tonne_per_hr][s] - MESS[:vSRetStoDisCap][s]
        else
            dfSto[!, :Existing_Dis_Cap_tonne_per_hr][s]
        end
    )
    ## Total capacity = existing capacity + new capacity
    @expression(
        MESS,
        eSStoDisCap[s in 1:S],
        if s in NEW_STO_CAP
            MESS[:eSExiStoDisCap][s] + MESS[:vSNewStoDisCap][s]
        else
            MESS[:eSExiStoDisCap][s]
        end
    )

    @expression(
        MESS,
        eSStoCapOZRT[z in 1:Z, rt in ResourceType],
        sum(
            MESS[:eSStoDisCap][s] for
            s in dfSto[(dfSto.Zone .== Zones[z]) .& (dfSto.Resource_Type .== rt), :R_ID];
            init = 0.0,
        )
    )

    ## Objective Expressions ##
    ## Fixed costs for resource "s" = annuitized investment cost plus fixed O&M costs
    ## Annuitized investment costs for new built capacity
    @expression(
        MESS,
        eSObjFixInvStoDisOS[s in NEW_STO_CAP],
        (
            dfSto[!, :Inv_Cost_Dis_per_tonne_per_hr][s] * dfSto[!, :AF][s] +
            dfSto[!, :Fixed_OM_Cost_Dis_per_tonne_per_hr][s]
        ) * MESS[:vSNewStoDisCap][s]
    )
    @expression(
        MESS,
        eSObjFixInvStoDis,
        sum(MESS[:eSObjFixInvStoDisOS][s] for s in NEW_STO_CAP; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eSObj], MESS[:eSObjFixInvStoDis])

    ## Annuitized investment costs for existing capacity
    if IncludeExistingSto == 1
        @expression(
            MESS,
            eSObjFixSunkInvStoDisOS[s in 1:S],
            AffExpr(
                dfSto[!, :Inv_Cost_Dis_per_tonne_per_hr][s] *
                dfSto[!, :AF][s] *
                dfSto[!, :Existing_Dis_Cap_tonne_per_hr][s],
            )
        )
        @expression(
            MESS,
            eSObjFixSunkInvStoDis,
            sum(MESS[:eSObjFixSunkInvStoDisOS][s] for s in 1:S; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:eSObj], MESS[:eSObjFixSunkInvStoDis])
    end

    ## Fixed O&M costs
    @expression(
        MESS,
        eSObjFixFomStoDisOS[s in 1:S],
        dfSto[!, :Fixed_OM_Cost_Dis_per_tonne_per_hr][s] * MESS[:eSExiStoDisCap][s]
    )
    @expression(
        MESS,
        eSObjFixFomStoDis,
        sum(MESS[:eSObjFixFomStoDisOS][s] for s in 1:S; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eSObj], MESS[:eSObjFixFomStoDis])
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Constraints on retirements and capacity additions
    ## Cannot retire more capacity than existing capacity
    if !isempty(RET_STO_CAP)
        @constraint(
            MESS,
            cSStoMaxRetDisCap[s in RET_STO_CAP],
            MESS[:vSRetStoDisCap][s] <= dfSto[!, :Existing_Dis_Cap_tonne_per_hr][s]
        )
    end

    ## Constraints on new built capacity
    ## Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    if !isempty(intersect(1:S, dfSto[dfSto.Max_Dis_Cap_tonne_per_hr .> 0, :R_ID]))
        @constraint(
            MESS,
            cSStoMaxDisCap[s in intersect(1:S, dfSto[dfSto.Max_Dis_Cap_tonne_per_hr .> 0, :R_ID])],
            MESS[:eSStoDisCap][s] <= dfSto[!, :Max_Dis_Cap_tonne_per_hr][s]
        )
    end

    ## Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    if !isempty(intersect(1:S, dfSto[dfSto.Min_Dis_Cap_tonne_per_hr .> 0, :R_ID]))
        @constraint(
            MESS,
            cSStoMinDisCap[s in intersect(1:S, dfSto[dfSto.Min_Dis_Cap_tonne_per_hr .> 0, :R_ID])],
            MESS[:eSStoDisCap][s] >= dfSto[!, :Min_Dis_Cap_tonne_per_hr][s]
        )
    end
    ### End Constraints ###

    return MESS
end
