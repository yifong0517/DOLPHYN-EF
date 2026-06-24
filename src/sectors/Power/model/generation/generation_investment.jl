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

    print_and_log(settings, "i", "Power Generation Investment Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Get power sector settings
    power_settings = settings["PowerSettings"]
    IncludeExistingGen = power_settings["IncludeExistingGen"]
    ScaleEffect = power_settings["ScaleEffect"]

    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]

    ## Number of generators resources
    G = power_inputs["G"]

    ## Set of all resources eligible for new capacity and retirements
    NEW_GEN_CAP = power_inputs["NEW_GEN_CAP"]
    RET_GEN_CAP = power_inputs["RET_GEN_CAP"]

    ## Set of all resources eligible for unit commitment
    COMMIT = power_inputs["THERM_COMMIT"]
    NO_COMMIT = power_inputs["NO_COMMIT"]
    ResourceType = power_inputs["GenResourceType"]

    ### Variables ###
    ## New installed capacity of resource "g"
    @variable(MESS, vPNewGenCap[g in NEW_GEN_CAP] >= 0)
    ## Retired capacity of resource "g" from existing capacity
    @variable(MESS, vPRetGenCap[g in RET_GEN_CAP] >= 0)

    ### Expressions ###
    ## Cap_Size_MW is set to 1 for all variables when unit UCommit == 0
    ## When UCommit > 0, Cap_Size_MW is set to 1 for all variables except those where THERM == 1
    ## Existing capacity = existing capacity - retired capacity
    @expression(
        MESS,
        ePExiGenCap[g in 1:G],
        if g in RET_GEN_CAP
            if g in COMMIT
                dfGen[!, :Existing_Cap_MW][g] - dfGen[!, :Cap_Size_MW][g] * MESS[:vPRetGenCap][g]
            else
                dfGen[!, :Existing_Cap_MW][g] - MESS[:vPRetGenCap][g]
            end
        else
            dfGen[!, :Existing_Cap_MW][g]
        end
    )
    ## Total capacity = existing capacity + new capacity
    @expression(
        MESS,
        ePGenCap[g in 1:G],
        if g in NEW_GEN_CAP
            if g in COMMIT
                MESS[:ePExiGenCap][g] + dfGen[!, :Cap_Size_MW][g] * MESS[:vPNewGenCap][g]
            else
                MESS[:ePExiGenCap][g] + MESS[:vPNewGenCap][g]
            end
        else
            MESS[:ePExiGenCap][g]
        end
    )

    @expression(
        MESS,
        ePGenCapOZRT[z in 1:Z, rt in ResourceType],
        sum(
            MESS[:ePGenCap][g] for
            g in dfGen[(dfGen.Zone .== Zones[z]) .& (dfGen.Resource_Type .== rt), :R_ID];
            init = 0.0,
        )
    )

    ## Sub zonal generation expressions
    if power_settings["SubZone"] == 1
        SubZones = power_inputs["SubZones"]
        ## Power sector sub zonal capacity expression
        @expression(
            MESS,
            ePGenCapOSZ[z in SubZones],
            sum(MESS[:ePGenCap][g] for g in intersect(1:G, dfGen[dfGen.SubZone .== z, :R_ID]))
        )
    end

    ## Objective Expressions ##
    ## Fixed costs for resource "g" = annuitized investment cost plus fixed O&M costs
    ## Annuitized investment costs for new built capacity
    if ScaleEffect == 0
        @expression(
            MESS,
            ePObjFixInvGenOG[g in NEW_GEN_CAP],
            if g in COMMIT
                (
                    dfGen[!, :Inv_Cost_per_MW][g] * dfGen[!, :AF][g] +
                    dfGen[!, :Fixed_OM_Cost_per_MW][g]
                ) *
                dfGen[!, :Cap_Size_MW][g] *
                MESS[:vPNewGenCap][g]
            else
                (
                    dfGen[!, :Inv_Cost_per_MW][g] * dfGen[!, :AF][g] +
                    dfGen[!, :Fixed_OM_Cost_per_MW][g]
                ) * MESS[:vPNewGenCap][g]
            end
        )
        @expression(
            MESS,
            ePObjFixInvGen,
            sum(MESS[:ePObjFixInvGenOG][g] for g in NEW_GEN_CAP; init = 0.0)
        )
    else
        ##TODO: Update cumulative capacity for learning effect
        @expression(
            MESS,
            ePCumGenCap[g in NEW_GEN_CAP],
            sum(
                MESS[:ePGenCap][g] for
                g in dfGen[dfGen.Resource_Type .== dfGen[!, :Resource_Type][g], :R_ID]
            )
        )
        @NLexpression(
            MESS,
            ePObjFixInvGenOGCOMMIT[g in intersect(COMMIT, NEW_GEN_CAP)],
            dfGen[!, :Inv_Cost_per_MW][g] *
            MESS[:ePCumGenCap][g]^dfGen[!, :Scale_Effect][g] *
            dfGen[!, :AF][g] *
            dfGen[!, :Cap_Size_MW][g] *
            MESS[:vPNewGenCap][g]
        )
        @NLexpression(
            MESS,
            ePObjFixInvGenOGREMAIN[g in intersect(setdiff(1:G, COMMIT), NEW_GEN_CAP)],
            dfGen[!, :Inv_Cost_per_MW][g] *
            MESS[:ePCumGenCap][g]^dfGen[!, :Scale_Effect][g] *
            dfGen[!, :AF][g] *
            MESS[:vPNewGenCap][g]
        )
        @expression(
            MESS,
            ePObjFixInvGen,
            sum(
                MESS[:ePObjFixInvGenOGCOMMIT][g] for g in intersect(COMMIT, NEW_GEN_CAP);
                init = 0.0,
            ) + sum(
                MESS[:ePObjFixInvGenOGREMAIN][g] for
                g in intersect(setdiff(1:G, COMMIT), NEW_GEN_CAP);
                init = 0.0,
            )
        )
    end
    ## Add term to objective function expression
    add_to_expression!(MESS[:ePObj], MESS[:ePObjFixInvGen])

    ## Annuitized investment costs for existing capacity
    if IncludeExistingGen > 0
        @expression(
            MESS,
            ePObjFixSunkInvGenOG[g in 1:G],
            AffExpr(
                dfGen[!, :Inv_Cost_per_MW][g] * dfGen[!, :AF][g] * dfGen[!, :Existing_Cap_MW][g] /
                IncludeExistingGen,
            )
        )
        @expression(
            MESS,
            ePObjFixSunkInvGen,
            sum(MESS[:ePObjFixSunkInvGenOG][g] for g in 1:G; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:ePObj], MESS[:ePObjFixSunkInvGen])
    end

    ## Fixed O&M costs
    @expression(
        MESS,
        ePObjFixFomGenOG[g in 1:G],
        dfGen[!, :Fixed_OM_Cost_per_MW][g] * MESS[:ePExiGenCap][g] /
        (IncludeExistingGen > 0 ? IncludeExistingGen : 1)
    )
    @expression(MESS, ePObjFixFomGen, sum(MESS[:ePObjFixFomGenOG][g] for g in 1:G; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:ePObj], MESS[:ePObjFixFomGen])
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Constraints on retirements and capacity additions
    ## Cannot retire more capacity than existing capacity
    if !isempty(intersect(RET_GEN_CAP, NO_COMMIT))
        @constraint(
            MESS,
            cPGenMaxRetireNoCommit[g in intersect(RET_GEN_CAP, NO_COMMIT)],
            MESS[:vPRetGenCap][g] <= dfGen[!, :Existing_Cap_MW][g]
        )
    end
    if !isempty(intersect(RET_GEN_CAP, COMMIT))
        @constraint(
            MESS,
            cPGenMaxRetireCommit[g in intersect(RET_GEN_CAP, COMMIT)],
            dfGen[!, :Cap_Size_MW][g] * MESS[:vPRetGenCap][g] <= dfGen[!, :Existing_Cap_MW][g]
        )
    end

    ## Constraints on new built capacity
    ## Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    if !isempty(intersect(1:G, dfGen[dfGen.Max_Cap_MW .>= 0, :R_ID]))
        @constraint(
            MESS,
            cPGenMaxCap[g in intersect(1:G, dfGen[dfGen.Max_Cap_MW .>= 0, :R_ID])],
            MESS[:ePGenCap][g] <= dfGen[!, :Max_Cap_MW][g]
        )
    end

    ## Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    if !isempty(intersect(1:G, dfGen[dfGen.Min_Cap_MW .>= 0, :R_ID]))
        @constraint(
            MESS,
            cPGenMinCap[g in intersect(1:G, dfGen[dfGen.Min_Cap_MW .>= 0, :R_ID])],
            MESS[:ePGenCap][g] >= dfGen[!, :Min_Cap_MW][g]
        )
    end
    ### End Constraints ###

    return MESS
end
