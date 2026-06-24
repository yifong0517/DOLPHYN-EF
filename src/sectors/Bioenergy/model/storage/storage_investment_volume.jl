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
    storage_investment_volume(settings::Dict, inputs::Dict, MESS::Model)

"""
function storage_investment_volume(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Bioenergy Storage Volume Investment Module")

    ## Get bioenergy sector settings
    bioenergy_settings = settings["BioenergySettings"]
    IncludeExistingSto = bioenergy_settings["IncludeExistingSto"]

    bioenergy_inputs = inputs["BioenergyInputs"]

    ## Number of storage resources
    S = bioenergy_inputs["S"]
    dfSto = bioenergy_inputs["dfSto"]

    ## Set of storage resources eligible for new capacity and retirements
    NEW_STO_CAP = bioenergy_inputs["NEW_STO_CAP"]
    RET_STO_CAP = bioenergy_inputs["RET_STO_CAP"]

    ### Variables ###
    ## New installed capacity of resource "s"
    @variable(MESS, vBNewStoVolumeCap[s in NEW_STO_CAP] >= 0)
    ## Retired capacity of resource "s" from existing capacity
    @variable(MESS, vBRetStoVolumeCap[s in RET_STO_CAP] >= 0)

    ### Expressions ###
    @expression(
        MESS,
        eBStoVolumeCap[s in 1:S],
        ## Storage resources eligible for new capacity and retirements
        if s in intersect(NEW_STO_CAP, RET_STO_CAP)
            dfSto[!, :Existing_Volume_Cap_tonne][s] + MESS[:vBNewStoVolumeCap][s] -
            MESS[:vBRetStoVolumeCap][s]
            ## Storage resources eligible for only new capacity
        elseif s in setdiff(NEW_STO_CAP, RET_STO_CAP)
            dfSto[!, :Existing_Volume_Cap_tonne][s] + MESS[:vBNewStoVolumeCap][s]
            ## Storage resources eligible for only capacity retirements
        elseif s in setdiff(RET_STO_CAP, NEW_STO_CAP)
            dfSto[!, :Existing_Volume_Cap_tonne][s] - MESS[:vBRetStoVolumeCap][s]
            ## Storage resources not eligible for new capacity or retirements
        else
            dfSto[!, :Existing_Volume_Cap_tonne][s]
        end
    )

    ## Objective Expressions ##
    ## Fixed costs for resource "s" = annuitized investment cost plus fixed O&M costs
    ## Annuitized investment costs for new built capacity
    @expression(
        MESS,
        eBObjFixInvStoVolumeOS[s in NEW_STO_CAP],
        dfSto[!, :Inv_Cost_Volume_per_tonne][s] * dfSto[!, :AF][s] * MESS[:vBNewStoVolumeCap][s]
    )
    @expression(
        MESS,
        eBObjFixInvStoVolume,
        sum(eBObjFixInvStoVolumeOS[s] for s in NEW_STO_CAP; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eBObj], MESS[:eBObjFixInvStoVolume])

    ## Annuitized investment costs for existing capacity
    if IncludeExistingSto == 1
        @expression(
            MESS,
            eBObjFixSunkInvStoVolumeOS[s in 1:S],
            AffExpr(
                dfSto[!, :Inv_Cost_Volume_per_tonne][s] *
                dfSto[!, :AF][s] *
                dfSto[!, :Existing_Volume_Cap_tonne][s],
            )
        )
        @expression(
            MESS,
            eBObjFixSunkInvStoVolume,
            sum(MESS[:eBObjFixSunkInvStoVolumeOS][s] for s in 1:S; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:eBObj], MESS[:eBObjFixSunkInvStoVolume])
    end

    ## Fixed O&M costs
    @expression(
        MESS,
        eBObjFixFomStoVolumeOS[s = 1:S],
        dfSto[!, :Fixed_OM_Cost_Volume_per_tonne][s] * MESS[:eBStoVolumeCap][s]
    )
    @expression(MESS, eBObjFixFomStoVolume, sum(eBObjFixFomStoVolumeOS[s] for s in 1:S; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eBObj], MESS[:eBObjFixFomStoVolume])
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Constraints on retirements and capacity additions
    ## Cannot retire more capacity than existing capacity
    @constraint(
        MESS,
        cBStoMaxRetVolumeCap[s in RET_STO_CAP],
        MESS[:vBRetStoVolumeCap][s] <= dfSto[!, :Existing_Volume_Cap_tonne][s]
    )

    ## Constraints on new built capacity
    ## Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    @constraint(
        MESS,
        cBStoMaxVolumeCap[s in intersect(1:S, dfSto[dfSto.Max_Volume_Cap_tonne .>= 0, :R_ID])],
        MESS[:eBStoVolumeCap][s] <= dfSto[!, :Max_Volume_Cap_tonne][s]
    )

    ## Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    @constraint(
        MESS,
        cBStoMinVolumeCap[s in intersect(1:S, dfSto[dfSto.Min_Volume_Cap_tonne .>= 0, :R_ID])],
        MESS[:eBStoVolumeCap][s] >= dfSto[!, :Min_Volume_Cap_tonne][s]
    )
    ### End Constraints ###

    return MESS
end
