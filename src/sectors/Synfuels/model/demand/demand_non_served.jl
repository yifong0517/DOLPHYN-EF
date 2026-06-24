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

    print_and_log(settings, "i", "Synfuels Demand Non-served Module")

    Z = inputs["Z"]
    T = inputs["T"]     # Number of time steps
    weights = inputs["weights"]

    synfuels_inputs = inputs["SynfuelsInputs"]

    SEG = synfuels_inputs["SEG"] # Number of load curtailment segments

    ### Variables ###
    # Non-served synfuels/curtailed demand in the segment "s" at hour "t" in zone "z"
    @variable(MESS, vSDNse[s in 1:SEG, z in 1:Z, t in 1:T] >= 0)

    ### Expressions ###
    ## Objective Expressions ##
    ## Cost of non-served synfuels/curtailed demand at hour "t" in zone "z"
    @expression(
        MESS,
        eSObjVarNseOSZT[s in 1:SEG, z in 1:Z, t in 1:T],
        weights[t] * synfuels_inputs["Demand_Curtail_Cost"][s] * MESS[:vSDNse][s, z, t]
    )
    @expression(
        MESS,
        eSObjVarNseOSZ[s in 1:SEG, z in 1:Z],
        sum(MESS[:eSObjVarNseOSZT][s, z, t] for t in 1:T)
    )
    @expression(MESS, eSObjVarNseOS[s in 1:SEG], sum(MESS[:eSObjVarNseOSZ][s, z] for z in 1:Z))
    @expression(MESS, eSObjVarNseOZ[z in 1:Z], sum(MESS[:eSObjVarNseOS][s] for s in 1:SEG))
    @expression(MESS, eSObjVarNse, sum(MESS[:eSObjVarNseOZ][z] for z in 1:Z))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eSObj], MESS[:eSObjVarNse])
    ## End Objective Expressions ##

    ## Balance Expressions ##
    @expression(MESS, eSBalanceNse[z in 1:Z, t in 1:T], sum(MESS[:vSDNse][s, z, t] for s in 1:SEG))

    ## Add non-served energy/curtailed demand contribution into synfuels balance
    add_to_expression!.(MESS[:eSBalance], MESS[:eSBalanceNse])

    ## Minus non-served energy/curtailed demand contribution from synfuels demand expression
    add_to_expression!.(MESS[:eSDemand], -MESS[:eSBalanceNse])
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Demand curtailed in each segment of curtailable demands cannot exceed maximum allowable share of demand
    @constraint(
        MESS,
        cSDNsePerSeg[s in 1:SEG, z in 1:Z, t in 1:T],
        MESS[:vSDNse][s, z, t] <=
        synfuels_inputs["Max_Demand_Curtail"][s] * synfuels_inputs["D"][z, t]
    )

    ## Total demand curtailed in each time step (hourly) cannot exceed total demand
    @constraint(
        MESS,
        cSMaxDNse[z in 1:Z, t in 1:T],
        sum(MESS[:vSDNse][s, z, t] for s in 1:SEG) <= synfuels_inputs["D"][z, t]
    )
    ### End Constraints ###

    return MESS
end
