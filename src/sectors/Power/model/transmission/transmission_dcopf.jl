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
function transmission_dcopf(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Transmission Direct Current Flow Module")

    Z = inputs["Z"]
    T = inputs["T"]

    power_settings = settings["PowerSettings"]
    power_inputs = inputs["PowerInputs"]

    ## Number of transmission lines
    L = power_inputs["L"]
    dfLine = power_inputs["dfLine"]

    ### Variables ###
    ## Voltage angle variables of each zone "z" at hour "t"
    @variable(MESS, vPLineAngle[z = 1:Z, t = 1:T])

    ### Constraints ###
    ## Power flow constraint:: vPLineFlow = DC_OPF_coeff * (vPLineAngle[START_ZONE] - vPLineAngle[END_ZONE])
    @constraint(
        MESS,
        cPDCOPF[l = 1:L, t = 1:T],
        MESS[:vPLineFlow][l, t] ==
        dfLine[!, :DC_OPF_coeff][l] *
        sum(power_inputs["Network_map"][l, z] * vPLineAngle[z, t] for z in 1:Z)
    )

    ## Bus angle limits (except slack bus)
    @constraints(
        MESS,
        begin
            cPLineAngleUpperBound[l = 1:L, t = 1:T],
            sum(power_inputs["Network_map"][l, z] * vPLineAngle[z, t] for z in 1:Z) <=
            dfLine[!, :Line_Angle_Limit][l]
            cPLineAngleLowerBound[l = 1:L, t = 1:T],
            sum(power_inputs["Network_map"][l, z] * vPLineAngle[z, t] for z in 1:Z) >=
            -dfLine[!, :Line_Angle_Limit][l]
        end
    )

    ## Slack bus angle limit
    @constraint(MESS, cPLineAngleSlack[t = 1:T], vPLineAngle[1, t] == 0)

    return MESS
end
