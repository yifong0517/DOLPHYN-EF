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
    demand_all(settings::Dict, inputs::Dict, MESS:Model)

"""
function demand_all(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Demand Core Module")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    power_inputs = inputs["PowerInputs"]
    power_settings = settings["PowerSettings"]

    ## Power sector actual demand
    @expression(MESS, ePDemand[z in 1:Z, t in 1:T], AffExpr(power_inputs["D"][z, t]))

    ## Whether non served energy is modeled
    if power_settings["AllowNse"] == 1
        MESS = demand_non_served(settings, inputs, MESS)
    end

    ## Additional demand from other sector
    MESS = demand_additional(settings, inputs, MESS)

    return MESS
end
