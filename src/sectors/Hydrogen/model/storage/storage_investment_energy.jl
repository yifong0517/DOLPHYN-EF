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
    storage_investment_energy(settings::Dict, inputs::Dict, MESS::Model)

"""
function storage_investment_energy(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Hydrogen Storage Energy Investment Module")

    ## Get hydrogen sector settings
    hydrogen_settings = settings["HydrogenSettings"]
    IncludeExistingSto = hydrogen_settings["IncludeExistingSto"]

    hydrogen_inputs = inputs["HydrogenInputs"]

    ## Number of storage resources
    S = hydrogen_inputs["S"]
    dfSto = hydrogen_inputs["dfSto"]

    ## Set of storage resources eligible for new capacity and retirements
    NEW_STO_CAP = hydrogen_inputs["NEW_STO_CAP"]
    RET_STO_CAP = hydrogen_inputs["RET_STO_CAP"]

    ### Variables ###
    ## New installed capacity of resource "s"
    @variable(MESS, vHNewStoEneCap[s in NEW_STO_CAP] >= 0)
    ## Retired capacity of resource "s" from existing capacity
    @variable(MESS, vHRetStoEneCap[s in RET_STO_CAP] >= 0)

    ### Expressions ###
    ## Existing capacity = existing capacity - retired capacity
    @expression(
        MESS,
        eHExiStoEneCap[s in 1:S],
        if s in RET_STO_CAP
            dfSto[!, :Existing_Ene_Cap_tonne][s] - MESS[:vHRetStoEneCap][s]
        else
            dfSto[!, :Existing_Ene_Cap_tonne][s]
        end
    )
    ## Total capacity = existing capacity + new capacity
    @expression(
        MESS,
        eHStoEneCap[s in 1:S],
        if s in NEW_STO_CAP
            MESS[:eHExiStoEneCap][s] + MESS[:vHNewStoEneCap][s]
        else
            MESS[:eHExiStoEneCap][s]
        end
    )

    ## Objective Expressions ##
    ## Fixed costs for resource "s" = annuitized investment cost plus fixed O&M costs
    ## Annuitized investment costs for new built capacity
    @expression(
        MESS,
        eHObjFixInvStoEneOS[s in NEW_STO_CAP],
        (
            dfSto[!, :Inv_Cost_Ene_per_tonne][s] * dfSto[!, :AF][s] +
            dfSto[!, :Fixed_OM_Cost_Ene_per_tonne][s]
        ) * MESS[:vHNewStoEneCap][s]
    )
    @expression(
        MESS,
        eHObjFixInvStoEne,
        sum(MESS[:eHObjFixInvStoEneOS][s] for s in NEW_STO_CAP; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eHObj], MESS[:eHObjFixInvStoEne])

    ## Annuitized investment costs for existing capacity
    if IncludeExistingSto == 1
        @expression(
            MESS,
            eHObjFixSunkInvStoEneOS[s in 1:S],
            AffExpr(
                dfSto[!, :Inv_Cost_Ene_per_tonne][s] *
                dfSto[!, :AF][s] *
                dfSto[!, :Existing_Ene_Cap_tonne][s],
            )
        )
        @expression(
            MESS,
            eHObjFixSunkInvStoEne,
            sum(MESS[:eHObjFixSunkInvStoEneOS][s] for s in 1:S; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:eHObj], MESS[:eHObjFixSunkInvStoEne])
    end

    ## Fixed O&M costs
    @expression(
        MESS,
        eHObjFixFomStoEneOS[s = 1:S],
        dfSto[!, :Fixed_OM_Cost_Ene_per_tonne][s] * MESS[:eHExiStoEneCap][s]
    )
    @expression(
        MESS,
        eHObjFixFomStoEne,
        sum(MESS[:eHObjFixFomStoEneOS][s] for s in 1:S; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eHObj], MESS[:eHObjFixFomStoEne])
    ### End Expressions ###

    ### Constraints ###
    ## Constraints on retirements and capacity additions
    ## Cannot retire more capacity than existing capacity
    if !isempty(RET_STO_CAP)
        @constraint(
            MESS,
            cHStoMaxRetEneCap[s in RET_STO_CAP],
            MESS[:vHRetStoEneCap][s] <= dfSto[!, :Existing_Ene_Cap_tonne][s]
        )
    end

    ## Constraints on new built capacity
    ## Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    if !isempty(intersect(1:S, dfSto[dfSto.Max_Ene_Cap_tonne .> 0, :R_ID]))
        @constraint(
            MESS,
            cHStoMaxEneCap[s in intersect(1:S, dfSto[dfSto.Max_Ene_Cap_tonne .> 0, :R_ID])],
            MESS[:eHStoEneCap][s] <= dfSto[!, :Max_Ene_Cap_tonne][s]
        )
    end

    ## Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    if !isempty(intersect(1:S, dfSto[dfSto.Min_Ene_Cap_tonne .> 0, :R_ID]))
        @constraint(
            MESS,
            cHStoMinEneCap[s in intersect(1:S, dfSto[dfSto.Min_Ene_Cap_tonne .> 0, :R_ID])],
            MESS[:eHStoEneCap][s] >= dfSto[!, :Min_Ene_Cap_tonne][s]
        )
    end
    ### End Constraints ###

    return MESS
end
