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
    capture_investment(settings::Dict, inputs::Dict, MESS::Model)

"""
function capture_investment(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Carbon Capture Direct Air Investment Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Get carbon sector settings
    carbon_settings = settings["CarbonSettings"]
    ScaleEffect = carbon_settings["ScaleEffect"]
    IncludeExistingCap = carbon_settings["IncludeExistingCap"]

    carbon_inputs = inputs["CarbonInputs"]
    dfGen = carbon_inputs["dfGen"]

    ## Number of generators resources
    G = carbon_inputs["G"]

    ## Set of all resources eligible for new capacity and retirements
    NEW_CAPTURE_CAP = carbon_inputs["NEW_CAPTURE_CAP"]
    RET_CAPTURE_CAP = carbon_inputs["RET_CAPTURE_CAP"]

    ## Set of all resources eligible for unit commitment
    COMMIT = carbon_inputs["COMMIT"]
    NO_COMMIT = carbon_inputs["NO_COMMIT"]
    ResourceType = carbon_inputs["GenResourceType"]

    ### Variables ###
    ## New installed capacity of resource "g"
    @variable(MESS, vCNewCaptureCap[g in NEW_CAPTURE_CAP] >= 0)
    ## Retired capacity of resource "g" from existing capacity
    @variable(MESS, vCRetCaptureCap[g in RET_CAPTURE_CAP] >= 0)

    ### Expressions ###
    ## Cap_Size_tonne_per_hr is set to 1 for all variables when CapCommit == 0
    ## When CapCommit > 0, Cap_Size_tonne_per_hr is set to 1 for all variables except those where THERM == 1
    @expression(
        MESS,
        eCCaptureCap[g in 1:G],
        ## Resources eligible for new capacity and retirements
        if g in intersect(NEW_CAPTURE_CAP, RET_CAPTURE_CAP)
            if g in COMMIT
                dfGen[!, :Existing_Cap_tonne_per_hr][g] +
                dfGen[!, :Cap_Size_tonne_per_hr][g] *
                (MESS[:vCNewCaptureCap][g] - MESS[:vCRetCaptureCap][g])
            else
                dfGen[!, :Existing_Cap_tonne_per_hr][g] + MESS[:vCNewCaptureCap][g] -
                MESS[:vCRetCaptureCap][g]
            end
            ## Resources eligible for only new capacity
        elseif g in setdiff(NEW_CAPTURE_CAP, RET_CAPTURE_CAP)
            if g in COMMIT
                dfGen[!, :Existing_Cap_tonne_per_hr][g] +
                dfGen[!, :Cap_Size_tonne_per_hr][g] * MESS[:vCNewCaptureCap][g]
            else
                dfGen[!, :Existing_Cap_tonne_per_hr][g] + MESS[:vCNewCaptureCap][g]
            end
            ## Resources eligible for only capacity retirements
        elseif g in setdiff(RET_CAPTURE_CAP, NEW_CAPTURE_CAP)
            if g in COMMIT
                dfGen[!, :Existing_Cap_tonne_per_hr][g] -
                dfGen[!, :Cap_Size_tonne_per_hr][g] * MESS[:vCRetCaptureCap][g]
            else
                dfGen[!, :Existing_Cap_tonne_per_hr][g] - MESS[:vCRetCaptureCap][g]
            end
            ## Resources not eligible for new capacity or retirements
        else
            dfGen[!, :Existing_Cap_tonne_per_hr][g]
        end
    )

    @expression(
        MESS,
        eCCaptureCapOZRT[z in 1:Z, rt in ResourceType],
        sum(
            MESS[:eCCaptureCap][g] for
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
            eCObjFixInvCapOG[g in NEW_CAPTURE_CAP],
            if g in COMMIT
                dfGen[!, :Inv_Cost_per_tonne_per_hr][g] *
                dfGen[!, :Cap_Size_tonne_per_hr][g] *
                dfGen[!, :AF][g] *
                MESS[:vCNewCaptureCap][g]
            else
                dfGen[!, :Inv_Cost_per_tonne_per_hr][g] *
                dfGen[!, :AF][g] *
                MESS[:vCNewCaptureCap][g]
            end
        )
        @expression(
            MESS,
            eCObjFixInvCap,
            sum(MESS[:eCObjFixInvCapOG][g] for g in NEW_CAPTURE_CAP; init = 0.0)
        )
    else
        @expression(
            MESS,
            eCCumCaptureCap[g in NEW_CAPTURE_CAP],
            sum(
                MESS[:eCCaptureCap][g] for
                g in dfGen[dfGen.Resource_Type .== dfGen[!, :Resource_Type][g], :R_ID]
            )
        )
        @NLexpression(
            MESS,
            eCObjFixInvCapOGCOMMIT[g in intersect(COMMIT, NEW_CAPTURE_CAP)],
            dfGen[!, :Inv_Cost_per_tonne_per_hr][g] *
            MESS[:eCCumCaptureCap][g]^dfGen[!, :Scale_Effect][g] *
            dfGen[!, :AF][g] *
            dfGen[!, :Cap_Size_tonne_per_hr][g] *
            MESS[:vCNewGenCap][g]
        )
        @NLexpression(
            MESS,
            eCObjFixInvCapOGREMAIN[g in intersect(setdiff(1:G, COMMIT), NEW_CAPTURE_CAP)],
            dfGen[!, :Inv_Cost_per_MW][g] *
            MESS[:eCCumCaptureCap][g]^dfGen[!, :Scale_Effect][g] *
            dfGen[!, :AF][g] *
            MESS[:vCNewGenCap][g]
        )
        @expression(
            MESS,
            eCObjFixInvCap,
            sum(
                MESS[:eCObjFixInvCapOGCOMMIT][g] for g in intersect(COMMIT, NEW_GEN_CAP);
                init = 0.0,
            ) + sum(
                MESS[:eCObjFixInvCapOGREMAIN][g] for
                g in intersect(setdiff(1:G, COMMIT), NEW_GEN_CAP);
                init = 0.0,
            )
        )
    end
    ## Add term to objective function expression
    add_to_expression!(MESS[:eCObj], MESS[:eCObjFixInvCap])

    ## Annuitized investment costs for existing capacity
    if IncludeExistingCap == 1
        @expression(
            MESS,
            eCObjFixSunkInvCapOG[g in 1:G],
            AffExpr(
                dfGen[!, :Inv_Cost_per_tonne_per_hr][g] *
                dfGen[!, :AF][g] *
                dfGen[!, :Existing_Cap_tonne_per_hr][g],
            )
        )
        @expression(
            MESS,
            eCObjFixSunkInvCap,
            sum(MESS[:eCObjFixSunkInvCapOG][g] for g in 1:G; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:eCObj], MESS[:eCObjFixSunkInvCap])
    end

    ## Fixed O&M costs
    @expression(
        MESS,
        eCObjFixFomCapOG[g in 1:G],
        dfGen[!, :Fixed_OM_Cost_per_tonne_per_hr][g] * MESS[:eCCaptureCap][g]
    )
    @expression(MESS, eCObjFixFomCap, sum(MESS[:eCObjFixFomCapOG][g] for g in 1:G; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eCObj], MESS[:eCObjFixFomCap])
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Constraints on retirements and capacity additions
    ## Cannot retire more capacity than existing capacity
    @constraint(
        MESS,
        cCCaptureMaxRetireNoCommit[g in intersect(RET_CAPTURE_CAP, NO_COMMIT)],
        MESS[:vCRetCaptureCap][g] <= dfGen[!, :Existing_Cap_tonne_per_hr][g]
    )

    @constraint(
        MESS,
        cCCaptureMaxRetireCommit[g in intersect(RET_CAPTURE_CAP, COMMIT)],
        dfGen[!, :Cap_Size_tonne_per_hr][g] * MESS[:vCRetCaptureCap][g] <=
        dfGen[!, :Existing_Cap_tonne_per_hr][g]
    )

    ## Constraints on new built capacity
    ## Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    if !isempty(intersect(dfGen[dfGen.Max_Cap_tonne_per_hr .>= 0, :R_ID], 1:G))
        @constraint(
            MESS,
            cCCaptureMaxCap[g in intersect(dfGen[dfGen.Max_Cap_tonne_per_hr .>= 0, :R_ID], 1:G)],
            MESS[:eCCaptureCap][g] <= dfGen[!, :Max_Cap_tonne_per_hr][g]
        )
    end

    ## Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    if !isempty(intersect(dfGen[dfGen.Min_Cap_tonne_per_hr .>= 0, :R_ID], 1:G))
        @constraint(
            MESS,
            cCCaptureMinCap[g in intersect(dfGen[dfGen.Min_Cap_tonne_per_hr .>= 0, :R_ID], 1:G)],
            MESS[:eCCaptureCap][g] >= dfGen[!, :Min_Cap_tonne_per_hr][g]
        )
    end
    ### End Constraints ###

    return MESS
end
