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
    food_warehouse_investment_volume(settings::Dict, inputs::Dict, MESS::Model)

"""
function food_warehouse_investment_volume(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Sector Foods Warehouse Volume Investment Module")

    foodstuff_inputs = inputs["FoodstuffInputs"]

    ## Number of storage resources
    S = foodstuff_inputs["S"]
    dfSto = foodstuff_inputs["dfSto"]

    ## Set of storage resources eligible for new capacity and retirements
    NEW_STO_CAP = foodstuff_inputs["NEW_STO_CAP"]
    RET_STO_CAP = foodstuff_inputs["RET_STO_CAP"]

    ### Variables ###
    ## New installed capacity of resource "s"
    @variable(MESS, vFFoodNewStoVolumeCap[s in NEW_STO_CAP] >= 0)
    ## Retired capacity of resource "s" from existing capacity
    @variable(MESS, vFFoodRetStoVolumeCap[s in RET_STO_CAP] >= 0)

    ### Expressions ###
    @expression(
        MESS,
        eFFoodStoVolumeCap[s in 1:S],
        ## Storage resources eligible for new capacity and retirements
        if s in intersect(NEW_STO_CAP, RET_STO_CAP)
            dfSto[!, :Existing_Volume_Cap_tonne][s] + MESS[:vFFoodNewStoVolumeCap][s] -
            MESS[:vFFoodRetStoVolumeCap][s]
            ## Storage resources eligible for only new capacity
        elseif s in setdiff(NEW_STO_CAP, RET_STO_CAP)
            dfSto[!, :Existing_Volume_Cap_tonne][s] + MESS[:vFFoodNewStoVolumeCap][s]
            ## Storage resources eligible for only capacity retirements
        elseif s in setdiff(RET_STO_CAP, NEW_STO_CAP)
            dfSto[!, :Existing_Volume_Cap_tonne][s] - MESS[:vFFoodRetStoVolumeCap][s]
            ## Storage resources not eligible for new capacity or retirements
        else
            dfSto[!, :Existing_Volume_Cap_tonne][s]
        end
    )

    ## Objective Expressions ##
    ## Fixed costs for resource "s" = annuitized investment cost plus fixed O&M costs
    @expression(
        MESS,
        eFObjFixInvFoodStoVolumeOS[s in NEW_STO_CAP],
        dfSto[!, :Inv_Cost_Volume_per_tonne][s] *
        dfSto[!, :AF][s] *
        MESS[:vFFoodNewStoVolumeCap][s]
    )

    ## Add term to objective function expression
    @expression(
        MESS,
        eFObjFixInvFoodStoVolume,
        sum(eFObjFixInvFoodStoVolumeOS[s] for s in NEW_STO_CAP; init = 0.0)
    )
    add_to_expression!(MESS[:eFObj], MESS[:eFObjFixInvFoodStoVolume])

    @expression(
        MESS,
        eFObjFixFomFoodStoVolumeOS[s = 1:S],
        dfSto[!, :Fixed_OM_Cost_Volume_per_tonne][s] * MESS[:eFFoodStoVolumeCap][s]
    )

    ## Add term to objective function expression
    @expression(
        MESS,
        eFObjFixFomFoodStoVolume,
        sum(eFObjFixFomFoodStoVolumeOS[s] for s in 1:S; init = 0.0)
    )
    add_to_expression!(MESS[:eFObj], MESS[:eFObjFixFomFoodStoVolume])
    ### End Expressions ###

    ### Constratints ###
    ## Constraints on retirements and capacity additions
    ## Cannot retire more capacity than existing capacity
    @constraint(
        MESS,
        cFFoodStoMaxRetVolumeCap[s in RET_STO_CAP],
        MESS[:vFFoodRetStoVolumeCap][s] <= dfSto[!, :Existing_Volume_Cap_tonne][s]
    )

    ## Constraints on new built capacity
    ## Constraint on maximum capacity (if applicable) [set input to -1 if no constraint on maximum capacity]
    @constraint(
        MESS,
        cFFoodStoMaxVolumeCap[s in intersect(1:S, dfSto[dfSto.Max_Volume_Cap_tonne .>= 0, :R_ID])],
        MESS[:eFFoodStoVolumeCap][s] <= dfSto[!, :Max_Volume_Cap_tonne][s]
    )

    ## Constraint on minimum capacity (if applicable) [set input to -1 if no constraint on minimum capacity]
    @constraint(
        MESS,
        cFFoodStoMinVolumeCap[s in intersect(1:S, dfSto[dfSto.Min_Volume_Cap_tonne .>= 0, :R_ID])],
        MESS[:eFFoodStoVolumeCap][s] >= dfSto[!, :Min_Volume_Cap_tonne][s]
    )
    ### End Constraints ###

    return MESS
end
