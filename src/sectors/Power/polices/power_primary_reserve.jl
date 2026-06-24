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
function power_primary_reserve(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Sector Primary Reserve Policy Module")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    ## Power sector inputs
    power_inputs = inputs["PowerInputs"]
    dfRsv = power_inputs["dfRsv"]

    VRE = power_inputs["VRE"]

    ### Expressions ###
    ## Total system reserve expressions
    ## Regulation requirements as a percentage of load and scheduled variable renewable energy production in each hour
    @expression(
        MESS,
        ePPrimaryReserve[z in 1:Z, t = 1:T],
        dfRsv[!, :PRSV_Percent_Load][z] * power_inputs["D"][z, t] +
        dfRsv[!, :PRSV_Percent_VRE][z] *
        sum(power_inputs["P_Max"][g, t] * MESS[:ePGenCap][g] for g in VRE)
    )
    ### End Expressions ###

    ### Constraints ###
    ## Total system reserve constraints
    @constraint(
        MESS,
        cPPrimaryReserve[z in 1:Z, t = 1:T],
        MESS[:ePGenPrimaryReserve][z, t] + MESS[:ePStoPrimaryReserve][z, t] >=
        MESS[:ePPrimaryReserve][z, t]
    )
    ### End Constraints ###

    return MESS
end
