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

    print_and_log(settings, "i", "Power Storage Energy Investment Module")

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

    ### Variables ###
    ## New installed capacity of resource "s"
    @variable(MESS, vPNewStoEneCap[s in NEW_STO_CAP] >= 0)
    ## Retired capacity of resource "s" from existing capacity
    @variable(MESS, vPRetStoEneCap[s in RET_STO_CAP] >= 0)

    ### Expressions ###
    ## Eisting capacity = existing capacity - retired capacity
    @expression(
        MESS,
        ePExiStoEneCap[s in 1:S],
        if s in RET_STO_CAP
            dfSto[!, :Existing_Ene_Cap_MWh][s] - MESS[:vPRetStoEneCap][s]
        else
            dfSto[!, :Existing_Ene_Cap_MWh][s]
        end
    )
    ## Total capacity = existing capacity + new capacity
    @expression(
        MESS,
        ePStoEneCap[s in 1:S],
        if s in NEW_STO_CAP
            MESS[:ePExiStoEneCap][s] + MESS[:vPNewStoEneCap][s]
        else
            MESS[:ePExiStoEneCap][s]
        end
    )

    ## Objective Expressions ##
    ## Fixed costs for resource "s" = annuitized investment cost plus fixed O&M costs
    ## Annuitized investment costs for new built capacity
    @expression(
        MESS,
        ePObjFixInvStoEneOS[s in NEW_STO_CAP],
        (
            dfSto[!, :Inv_Cost_Ene_per_MWh][s] * dfSto[!, :AF][s] +
            dfSto[!, :Fixed_OM_Cost_Ene_per_MWh][s]
        ) * MESS[:vPNewStoEneCap][s]
    )
    @expression(
        MESS,
        ePObjFixInvStoEne,
        sum(MESS[:ePObjFixInvStoEneOS][s] for s in NEW_STO_CAP; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:ePObj], MESS[:ePObjFixInvStoEne])

    ## Annuitized sunk investment costs for existing capacity
    if IncludeExistingSto > 0
        @expression(
            MESS,
            ePObjFixSunkInvStoEneOS[s in 1:S],
            AffExpr(
                (
                    dfSto[!, :Inv_Cost_Ene_per_MWh][s] * dfSto[!, :AF][s] +
                    dfSto[!, :Fixed_OM_Cost_Ene_per_MWh][s]
                ) * dfSto[!, :Existing_Ene_Cap_MWh][s] / IncludeExistingSto,
            )
        )
        @expression(
            MESS,
            ePObjFixSunkInvStoEne,
            sum(MESS[:ePObjFixSunkInvStoEneOS][s] for s in 1:S; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:ePObj], MESS[:ePObjFixSunkInvStoEne])
    end

    ## Fixed O&M costs
    @expression(
        MESS,
        ePObjFixFomStoEneOS[s in 1:S],
        dfSto[!, :Fixed_OM_Cost_Ene_per_MWh][s] * MESS[:ePExiStoEneCap][s] /
        (IncludeExistingSto > 0 ? IncludeExistingSto : 1)
    )
    @expression(
        MESS,
        ePObjFixFomStoEne,
        sum(MESS[:ePObjFixFomStoEneOS][s] for s in 1:S; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:ePObj], MESS[:ePObjFixFomStoEne])
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Constraints on retirements and capacity additions
    ## Cannot retire more capacity than existing capacity
    if !isempty(RET_STO_CAP)
        @constraint(
            MESS,
            cPStoMaxRetEneCap[s in RET_STO_CAP],
            MESS[:vPRetStoEneCap][s] <= dfSto[!, :Existing_Ene_Cap_MWh][s]
        )
    end

    ## Constraints on new built capacity
    ## Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    if !isempty(intersect(1:S, dfSto[dfSto.Max_Ene_Cap_MWh .> 0, :R_ID]))
        @constraint(
            MESS,
            cPStoMaxEneCap[s in intersect(1:S, dfSto[dfSto.Max_Ene_Cap_MWh .> 0, :R_ID])],
            MESS[:ePStoEneCap][s] <= dfSto[!, :Max_Ene_Cap_MWh][s]
        )
    end

    ## Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    if !isempty(intersect(1:S, dfSto[dfSto.Min_Ene_Cap_MWh .> 0, :R_ID]))
        @constraint(
            MESS,
            cPStoMinEneCap[s in intersect(1:S, dfSto[dfSto.Min_Ene_Cap_MWh .> 0, :R_ID])],
            MESS[:ePStoEneCap][s] >= dfSto[!, :Min_Ene_Cap_MWh][s]
        )
    end
    ### End Constraints ###

    return MESS
end
