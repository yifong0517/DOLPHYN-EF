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
function truck_investment(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Foodstuff Transmission Truck Investment Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]
    T = inputs["T"]

    foodstuff_settings = settings["FoodstuffSettings"]
    foodstuff_inputs = inputs["FoodstuffInputs"]

    dfTru = foodstuff_inputs["dfTru"]
    dfRoute = foodstuff_inputs["dfRoute"]

    TRUCK_TYPES = foodstuff_inputs["TRUCK_TYPES"]
    TRUCK_ZONES = foodstuff_inputs["TRUCK_ZONES"]

    ### Variables ###
    ## Truck capacity built and retired
    if foodstuff_settings["TruckExpansion"] == 1
        ## New installed truck capacity of type "j"
        @variable(MESS, vFNewTruNumber[j in TRUCK_TYPES] >= 0)
    end

    ### Expressions ###
    ## Total available truck numbers
    @expression(
        MESS,
        eFTruNumber[j in TRUCK_TYPES],
        if foodstuff_settings["TruckExpansion"] == 1
            dfTru[!, :Existing_Number][j] + MESS[:vFNewTruNumber][j]
        else
            dfTru[!, :Existing_Number][j]
        end
    )

    ## Objective Expressions ##
    ## Fixed costs for truck type "j" = annuitized investment cost
    ## If truck is not eligible for new charge capacity, fixed costs are zero
    if foodstuff_settings["TruckExpansion"] == 1
        @expression(
            MESS,
            eFObjFixInvTruOJ[j in TRUCK_TYPES],
            dfTru[!, :Inv_Cost_Truck_per_unit][j] * dfTru[!, :AF][j] * MESS[:vFNewTruNumber][j]
        )

        ## Add term to objective function expression
        @expression(
            MESS,
            eFObjFixInvTru,
            sum(MESS[:eFObjFixInvTruOJ][j] for j in TRUCK_TYPES; init = 0.0)
        )
        add_to_expression!(MESS[:eFObj], MESS[:eFObjFixInvTru])
    end

    ## Truck fixed operation and maintainance costs
    @expression(
        MESS,
        eFObjFixFomTruOJ[j in TRUCK_TYPES],
        dfTru[!, :Fixed_OM_Cost_Truck_per_unit][j] * MESS[:eFTruNumber][j]
    )
    @expression(
        MESS,
        eFObjFixFomTru,
        sum(MESS[:eFObjFixFomTruOJ][j] for j in TRUCK_TYPES; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eFObj], MESS[:eFObjFixFomTru])
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constratints ###
    ## Integer constraints
    if foodstuff_settings["TruckInteger"] == 1
        for j in TRUCK_TYPES
            set_integer.(MESS[:vFNewTruNumber][j])
        end
    end
    ### End Constraints ###

    return MESS
end
