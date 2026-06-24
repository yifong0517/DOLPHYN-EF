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
    demand_non_served(settings::Dict, inputs::Dict, MESS::Model)

"""
function demand_non_served(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Demand Non-served Module")

    Z = inputs["Z"]
    T = inputs["T"]     # Number of time steps
    weights = inputs["weights"]

    power_inputs = inputs["PowerInputs"]

    SEG = power_inputs["SEG"] # Number of load curtailment segments

    ### Variables ###
    ## Non-served energy/curtailed demand in the segment "s" at hour "t" in zone "z"
    @variable(MESS, vPDNse[s in 1:SEG, z in 1:Z, t in 1:T] >= 0)

    ### Expressions ###
    ## Objective Expressions ##
    ## Cost of non-served energy/curtailed demand at hour "t" in zone "z"
    @expression(
        MESS,
        ePObjVarNseOSZT[s in 1:SEG, z in 1:Z, t in 1:T],
        weights[t] * power_inputs["Demand_Curtail_Cost"][s] * MESS[:vPDNse][s, z, t]
    )
    @expression(
        MESS,
        ePObjVarNseOSZ[s in 1:SEG, z in 1:Z],
        sum(MESS[:ePObjVarNseOSZT][s, z, t] for t in 1:T; init = 0.0)
    )
    @expression(
        MESS,
        ePObjVarNseOS[s in 1:SEG],
        sum(MESS[:ePObjVarNseOSZ][s, z] for z in 1:Z; init = 0.0)
    )
    @expression(
        MESS,
        ePObjVarNseOZ[z in 1:Z],
        sum(MESS[:ePObjVarNseOSZ][s, z] for s in SEG; init = 0.0)
    )
    @expression(MESS, ePObjVarNse, sum(MESS[:ePObjVarNseOS][s] for s in 1:SEG; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:ePObj], MESS[:ePObjVarNse])
    ## End Objective Expressions ##

    ## Balance Expressions ##
    @expression(MESS, ePBalanceNse[z in 1:Z, t in 1:T], sum(MESS[:vPDNse][s, z, t] for s in 1:SEG))

    ## Add non-served energy/curtailed demand contribution into power balance
    add_to_expression!.(MESS[:ePBalance], MESS[:ePBalanceNse])

    ## Minus non-served energy/curtailed demand contribution from power demand expression
    add_to_expression!.(MESS[:ePDemand], -MESS[:ePBalanceNse])
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Demand curtailed in each segment of curtailable demands cannot exceed maximum allowable share of demand
    @constraint(
        MESS,
        cPDNsePerSeg[s in 1:SEG, z in 1:Z, t in 1:T],
        MESS[:vPDNse][s, z, t] <= power_inputs["Max_Demand_Curtail"][s] * power_inputs["D"][z, t]
    )

    ## Total demand curtailed in each time step (hourly) cannot exceed total demand
    @constraint(
        MESS,
        cPDMaxNse[z in 1:Z, t in 1:T],
        sum(MESS[:vPDNse][s, z, t] for s in 1:SEG) <= power_inputs["D"][z, t]
    )
    ### End Constraints ###

    return MESS
end
