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
function storage_investment_charge(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Synfuels Storage Charge Investment Module")

    ## Get synfuels sector settings
    synfuels_settings = settings["SynfuelsSettings"]
    IncludeExistingSto = synfuels_settings["IncludeExistingSto"]

    synfuels_inputs = inputs["SynfuelsInputs"]

    ## Number of storage resources
    S = synfuels_inputs["S"]
    dfSto = synfuels_inputs["dfSto"]

    S = synfuels_inputs["S"]
    ## Set of storage resources eligible for new capacity and retirements
    NEW_STO_CAP = synfuels_inputs["NEW_STO_CAP"]
    RET_STO_CAP = synfuels_inputs["RET_STO_CAP"]

    ### Variables ###
    ## New installed capacity of resource "s"
    @variable(MESS, vSNewStoChaCap[s in NEW_STO_CAP] >= 0)
    ## Retired capacity of resource "s" from existing capacity
    @variable(MESS, vSRetStoChaCap[s in RET_STO_CAP] >= 0)

    ### Expressions ###
    ## Existing capacity = existing capacity - retired capacity
    @expression(
        MESS,
        eSExiStoChaCap[s in 1:S],
        if s in RET_STO_CAP
            dfSto[!, :Existing_Cha_Cap_tonne_per_hr][s] - MESS[:vSRetStoChaCap][s]
        else
            dfSto[!, :Existing_Cha_Cap_tonne_per_hr][s]
        end
    )
    ## Total capacity = existing capacity + new capacity
    @expression(
        MESS,
        eSStoChaCap[s in 1:S],
        if s in NEW_STO_CAP
            MESS[:eSExiStoChaCap][s] + MESS[:vSNewStoChaCap][s]
        else
            MESS[:eSExiStoChaCap][s]
        end
    )

    ## Objective Expressions ##
    ## Fixed costs for resource "s" = annuitized investment cost plus fixed O&M costs
    ## Annuitized investment costs for new built capacity
    @expression(
        MESS,
        eSObjFixInvStoChaOS[s in NEW_STO_CAP],
        (
            dfSto[!, :Inv_Cost_Cha_per_tonne_per_hr][s] * dfSto[!, :AF][s] +
            dfSto[!, :Fixed_OM_Cost_Cha_per_tonne_per_hr][s]
        ) * MESS[:vSNewStoChaCap][s]
    )
    @expression(
        MESS,
        eSObjFixInvStoCha,
        sum(MESS[:eSObjFixInvStoChaOS][s] for s in NEW_STO_CAP; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eSObj], MESS[:eSObjFixInvStoCha])

    ## Annuitized investment costs for existing capacity
    if IncludeExistingSto == 1
        @expression(
            MESS,
            eSObjFixSunkInvStoChaOS[s in 1:S],
            AffExpr(
                dfSto[!, :Inv_Cost_Cha_per_tonne_per_hr][s] *
                dfSto[!, :AF][s] *
                dfSto[!, :Existing_Cha_Cap_tonne_per_hr][s],
            )
        )
        @expression(
            MESS,
            eSObjFixSunkInvStoCha,
            sum(MESS[:eSObjFixSunkInvStoChaOS][s] for s in 1:S; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:eSObj], MESS[:eSObjFixSunkInvStoCha])
    end

    ## Fixed O&M costs
    @expression(
        MESS,
        eSObjFixFomStoChaOS[s in 1:S],
        dfSto[!, :Fixed_OM_Cost_Cha_per_tonne_per_hr][s] * MESS[:eSExiStoChaCap][s]
    )
    @expression(
        MESS,
        eSObjFixFomStoCha,
        sum(MESS[:eSObjFixFomStoChaOS][s] for s in 1:S; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eSObj], MESS[:eSObjFixFomStoCha])
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Constraints on retirements and capacity additions
    ## Cannot retire more capacity than existing capacity
    if !isempty(RET_STO_CAP)
        @constraint(
            MESS,
            cSStoMaxRetChaCap[s in RET_STO_CAP],
            MESS[:vSRetStoChaCap][s] <= dfSto[!, :Existing_Cha_Cap_tonne_per_hr][s]
        )
    end

    ## Constraints on new built capacity
    ## Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    if !isempty(intersect(1:S, dfSto[dfSto.Max_Cha_Cap_tonne_per_hr .> 0, :R_ID]))
        @constraint(
            MESS,
            cSStoMaxChaCap[s in intersect(1:S, dfSto[dfSto.Max_Cha_Cap_tonne_per_hr .> 0, :R_ID])],
            MESS[:eSStoChaCap][s] <= dfSto[!, :Max_Cha_Cap_tonne_per_hr][s]
        )
    end

    ## Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    if !isempty(intersect(1:S, dfSto[dfSto.Min_Cha_Cap_tonne_per_hr .> 0, :R_ID]))
        @constraint(
            MESS,
            cSStoMinChaCap[s in intersect(1:S, dfSto[dfSto.Min_Cha_Cap_tonne_per_hr .> 0, :R_ID])],
            MESS[:eSStoChaCap][s] >= dfSto[!, :Min_Cha_Cap_tonne_per_hr][s]
        )
    end
    ### End Constraints ###

    return MESS
end
