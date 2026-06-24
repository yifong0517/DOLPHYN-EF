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
    generation_investment(settings::Dict, inputs::Dict, MESS::Model)

"""
function generation_investment(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Ammonia Generation Investment Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Get ammonia sector settings
    ammonia_settings = settings["AmmoniaSettings"]
    IncludeExistingGen = ammonia_settings["IncludeExistingGen"]
    ScaleEffect = ammonia_settings["ScaleEffect"]

    ammonia_inputs = inputs["AmmoniaInputs"]
    dfGen = ammonia_inputs["dfGen"]

    ## Number of generators resources
    G = ammonia_inputs["G"]

    ## Set of all resources eligible for new capacity and retirements
    NEW_GEN_CAP = ammonia_inputs["NEW_GEN_CAP"]
    RET_GEN_CAP = ammonia_inputs["RET_GEN_CAP"]

    ## Set of all resources eligible for unit commitment
    COMMIT = ammonia_inputs["COMMIT"]
    NO_COMMIT = ammonia_inputs["NO_COMMIT"]
    ResourceType = ammonia_inputs["GenResourceType"]

    ### Variables ###
    ## New installed capacity of resource "g"
    @variable(MESS, vANewGenCap[g in NEW_GEN_CAP] >= 0)
    ## Retired capacity of resource "g" from existing capacity
    @variable(MESS, vARetGenCap[g in RET_GEN_CAP] >= 0)

    ### Expressions ###
    ## Cap_Size_tonne_per_hr is set to 1 for all variables when GenCommit == 0
    ## When GenCommit > 0, Cap_Size_tonne_per_hr is set to 1 for all variables except those where THERM == 1
    ## Existing capacity = existing capacity - retired capacity
    @expression(
        MESS,
        eAExiGenCap[g in 1:G],
        if g in RET_GEN_CAP
            if g in COMMIT
                dfGen[!, :Existing_Cap_tonne_per_hr][g] -
                dfGen[!, :Cap_Size_tonne_per_hr][g] * MESS[:vARetGenCap][g]
            else
                dfGen[!, :Existing_Cap_tonne_per_hr][g] - MESS[:vARetGenCap][g]
            end
        else
            dfGen[!, :Existing_Cap_tonne_per_hr][g]
        end
    )
    ## Total capacity = existing capacity + new capacity
    @expression(
        MESS,
        eAGenCap[g in 1:G],
        if g in NEW_GEN_CAP
            if g in COMMIT
                MESS[:eAExiGenCap][g] + dfGen[!, :Cap_Size_tonne_per_hr][g] * MESS[:vANewGenCap][g]
            else
                MESS[:eAExiGenCap][g] + MESS[:vANewGenCap][g]
            end
        else
            MESS[:eAExiGenCap][g]
        end
    )

    @expression(
        MESS,
        eAGenCapOZRT[z in 1:Z, rt in ResourceType],
        sum(
            MESS[:eAGenCap][g] for
            g in dfGen[(dfGen.Zone .== Zones[z]) .& (dfGen.Resource_Type .== rt), :R_ID];
            init = 0.0,
        )
    )

    ## Objective Expressions ##
    ## Fixed costs for resource "g" = annuitized investment cost plus fixed O&M costs
    ## Annuitized investment costs for new built capacity
    if ScaleEffect == 0
        @expression(
            MESS,
            eAObjFixInvGenOG[g in NEW_GEN_CAP],
            if g in COMMIT
                (
                    dfGen[!, :Inv_Cost_per_tonne_per_hr][g] * dfGen[!, :AF][g] +
                    dfGen[!, :Fixed_OM_Cost_per_tonne_per_hr][g]
                ) *
                dfGen[!, :Cap_Size_tonne_per_hr][g] *
                MESS[:vANewGenCap][g]
            else
                (
                    dfGen[!, :Inv_Cost_per_tonne_per_hr][g] * dfGen[!, :AF][g] +
                    dfGen[!, :Fixed_OM_Cost_per_tonne_per_hr][g]
                ) * MESS[:vANewGenCap][g]
            end
        )
        @expression(
            MESS,
            eAObjFixInvGen,
            sum(MESS[:eAObjFixInvGenOG][g] for g in NEW_GEN_CAP; init = 0.0)
        )
    else
        @expression(
            MESS,
            eACumGenCap[g in NEW_GEN_CAP],
            sum(
                MESS[:eAGenCap][g] for
                g in dfGen[dfGen.Resource_Type .== dfGen[!, :Resource_Type][g], :R_ID]
            )
        )
        @NLexpression(
            MESS,
            eAObjFixInvGenOGCOMMIT[g in intersect(COMMIT, NEW_GEN_CAP)],
            dfGen[!, :Inv_Cost_per_tonne_per_hr][g] *
            MESS[:eACumGenCap][g]^dfGen[!, :Scale_Effect][g] *
            dfGen[!, :AF][g] *
            dfGen[!, :Cap_Size_tonne_per_hr][g] *
            MESS[:vANewGenCap][g]
        )
        @NLexpression(
            MESS,
            eAObjFixInvGenOGREMAIN[g in intersect(setdiff(1:G, COMMIT), NEW_GEN_CAP)],
            dfGen[!, :Inv_Cost_per_MW][g] *
            MESS[:eACumGenCap][g]^dfGen[!, :Scale_Effect][g] *
            dfGen[!, :AF][g] *
            MESS[:vANewGenCap][g]
        )
        @expression(
            MESS,
            eAObjFixInvGen,
            sum(
                MESS[:eAObjFixInvGenOGCOMMIT][g] for g in intersect(COMMIT, NEW_GEN_CAP);
                init = 0.0,
            ) + sum(
                MESS[:eAObjFixInvGenOGREMAIN][g] for
                g in intersect(setdiff(1:G, COMMIT), NEW_GEN_CAP);
                init = 0.0,
            )
        )
    end
    ## Add term to objective function expression
    add_to_expression!(MESS[:eAObj], MESS[:eAObjFixInvGen])

    ## Annuitized investment costs for existing capacity
    if IncludeExistingGen > 0
        @expression(
            MESS,
            eAObjFixSunkInvGenOG[g in 1:G],
            AffExpr(
                dfGen[!, :Inv_Cost_per_tonne_per_hr][g] *
                dfGen[!, :AF][g] *
                dfGen[!, :Existing_Cap_tonne_per_hr][g] / IncludeExistingGen,
            )
        )
        @expression(
            MESS,
            eAObjFixSunkInvGen,
            sum(MESS[:eAObjFixSunkInvGenOG][g] for g in 1:G; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:eAObj], MESS[:eAObjFixSunkInvGen])
    end

    ## Fixed O&M costs
    @expression(
        MESS,
        eAObjFixFomGenOG[g in 1:G],
        dfGen[!, :Fixed_OM_Cost_per_tonne_per_hr][g] * MESS[:eAExiGenCap][g]
    )
    @expression(MESS, eAObjFixFomGen, sum(MESS[:eAObjFixFomGenOG][g] for g in 1:G; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eAObj], MESS[:eAObjFixFomGen])
    ### End Expressions ###

    ### Constraints ###
    ## Constraints on retirements and capacity additions
    ## Cannot retire more capacity than existing capacity
    if !isempty(intersect(RET_GEN_CAP, NO_COMMIT))
        @constraint(
            MESS,
            cAGenMaxRetireNoCommit[g in intersect(RET_GEN_CAP, NO_COMMIT)],
            MESS[:vARetGenCap][g] <= dfGen[!, :Existing_Cap_tonne_per_hr][g]
        )
    end

    if !isempty(intersect(RET_GEN_CAP, COMMIT))
        @constraint(
            MESS,
            cAGenMaxRetireCommit[g in intersect(RET_GEN_CAP, COMMIT)],
            dfGen[!, :Cap_Size_tonne_per_hr][g] * MESS[:vARetGenCap][g] <=
            dfGen[!, :Existing_Cap_tonne_per_hr][g]
        )
    end

    ## Constraints on new built capacity
    ## Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    if !isempty(intersect(1:G, dfGen[dfGen.Max_Cap_tonne_per_hr .> 0, :R_ID]))
        @constraint(
            MESS,
            cAGenMaxCap[g in intersect(1:G, dfGen[dfGen.Max_Cap_tonne_per_hr .> 0, :R_ID])],
            MESS[:eAGenCap][g] <= dfGen[!, :Max_Cap_tonne_per_hr][g]
        )
    end

    ## Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    if !isempty(intersect(1:G, dfGen[dfGen.Min_Cap_tonne_per_hr .> 0, :R_ID]))
        @constraint(
            MESS,
            cAGenMinCap[g in intersect(1:G, dfGen[dfGen.Min_Cap_tonne_per_hr .> 0, :R_ID])],
            MESS[:eAGenCap][g] >= dfGen[!, :Min_Cap_tonne_per_hr][g]
        )
    end
    ### End Constraints ###

    return MESS
end
