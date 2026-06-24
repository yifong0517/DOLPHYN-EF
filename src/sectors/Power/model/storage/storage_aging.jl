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
function storage_aging(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Storage Aging Module")

    T = inputs["T"]

    power_inputs = inputs["PowerInputs"]
    dfSto = power_inputs["dfSto"]

    AGING_STO = power_inputs["AGING_STO"]

    ### Expressions ###
    ## Power sector battery storage aging expression
    @expression(MESS, ePStoCapacityAging[s in AGING_STO, t in 1:T], AffExpr(0.0))

    ## Power sector battery storage calendric aging - linear degradation along the lifetime
    @expression(
        MESS,
        ePStoCapacityCalendricAging[s in AGING_STO, t in 1:T],
        1 / dfSto[!, :Lifetime][s] / 8760
    )

    add_to_expression!.(MESS[:ePStoCapacityAging], MESS[:ePStoCapacityCalendricAging])

    ## Power sector battery storage cyclic aging - linear degradation related to energy throughout
    @expression(
        MESS,
        ePStoCapacityCyclicAging[s in AGING_STO, t in 1:T],
        (
            dfSto[!, :Eff_Charge][s] * MESS[:vPStoCha][s, t] +
            MESS[:vPStoDis][s, t] / dfSto[!, :Eff_Discharge][s]
        ) / dfSto[!, :Cap_Size][s] / dfSto[!, :Cycle_Number][s]
    )

    add_to_expression!.(MESS[:ePStoCapacityAging], MESS[:ePStoCapacityCyclicAging])

    ## Objective Expressions ##
    @expression(
        MESS,
        ePObjStoAgingOST[s in AGING_STO, t in 1:T],
        dfSto[!, :Cap_Size][s] *
        dfSto[!, :Inv_Cost_Ene_per_MWh][s] *
        MESS[:ePStoCapacityAging][s, t]
    )

    @expression(
        MESS,
        ePObjStoAgingOS[s in AGING_STO],
        sum(MESS[:ePObjStoAgingOST][s, t] for t in 1:T; init = 0.0)
    )

    @expression(MESS, ePObjStoAging, sum(MESS[:ePObjStoAgingOS][s] for s in AGING_STO; init = 0.0))

    ## Add term to objective function expression
    add_to_expression!(MESS[:ePObj], MESS[:ePObjStoAging])

    ## End Objective Expressions ##
    ### End Expressions ###

    return MESS
end
