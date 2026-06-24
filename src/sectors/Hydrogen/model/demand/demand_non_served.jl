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

    print_and_log(settings, "i", "Hydrogen Demand Non-served Module")

    Z = inputs["Z"]
    T = inputs["T"]     # Number of time steps
    weights = inputs["weights"]

    hydrogen_inputs = inputs["HydrogenInputs"]

    SEG = hydrogen_inputs["SEG"] # Number of load curtailment segments

    ### Variables ###
    # Non-served hydrogen/curtailed demand in the segment "s" at hour "t" in zone "z"
    @variable(MESS, vHDNse[s in 1:SEG, z in 1:Z, t in 1:T] >= 0)

    ### Expressions ###
    ## Objective Expressions ##
    ## Cost of non-served hydrogen/curtailed demand at hour "t" in zone "z"
    @expression(
        MESS,
        eHObjVarNseOSZT[s in 1:SEG, z in 1:Z, t in 1:T],
        weights[t] * hydrogen_inputs["Demand_Curtail_Cost"][s] * MESS[:vHDNse][s, z, t]
    )
    @expression(
        MESS,
        eHObjVarNseOSZ[s in 1:SEG, z in 1:Z],
        sum(MESS[:eHObjVarNseOSZT][s, z, t] for t in 1:T; init = 0.0)
    )
    @expression(
        MESS,
        eHObjVarNseOS[s in 1:SEG],
        sum(MESS[:eHObjVarNseOSZ][s, z] for z in 1:Z; init = 0.0)
    )
    @expression(
        MESS,
        eHObjVarNseOZ[z in 1:Z],
        sum(MESS[:eHObjVarNseOSZ][s, z] for s in SEG; init = 0.0)
    )
    @expression(MESS, eHObjVarNse, sum(MESS[:eHObjVarNseOS][s] for s in 1:SEG; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eHObj], MESS[:eHObjVarNse])
    ## End Objective Expressions ##

    ## Balance Expressions ##
    @expression(
        MESS,
        eHBalanceNse[z in 1:Z, t in 1:T],
        sum(MESS[:vHDNse][s, z, t] for s in 1:SEG; init = 0.0)
    )

    ## Add non-served hydrogen/curtailed demand contribution into power balance
    add_to_expression!.(MESS[:eHBalance], MESS[:eHBalanceNse])

    ## Minus non-served hydrogen/curtailed demand contribution from power demand expression
    add_to_expression!.(MESS[:eHDemand], -MESS[:eHBalanceNse])
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Demand curtailed in each segment of curtailable demands cannot exceed maximum allowable share of demand
    @constraint(
        MESS,
        cHDNsePerSeg[s in 1:SEG, z in 1:Z, t in 1:T],
        MESS[:vHDNse][s, z, t] <=
        hydrogen_inputs["Max_Demand_Curtail"][s] * hydrogen_inputs["D"][z, t]
    )

    ## Total demand curtailed in each time step (hourly) cannot exceed total demand
    @constraint(
        MESS,
        cHDMaxNse[z in 1:Z, t in 1:T],
        sum(MESS[:vHDNse][s, z, t] for s in 1:SEG) <= hydrogen_inputs["D"][z, t]
    )
    ### End Constraints ###

    return MESS
end
