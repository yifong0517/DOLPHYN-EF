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
function consumption_bfg(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Bioenergy Power Generation Consumption Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    bioenergy_settings = settings["BioenergySettings"]
    HVs = bioenergy_settings["HVs"]

    ## Get power sector generators' data from dataframe
    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]
    BFG = power_inputs["BFG"]

    ## Get bioenergy sector residual list
    bioenergy_inputs = inputs["BioenergyInputs"]
    Residuals = bioenergy_inputs["Residuals"]

    ## Bioenergy consumption for power generation from resource "g" during hour "t"
    ## 1.055 is the conversion factor from MMBTu to GJ
    @expression(
        MESS,
        eBBalanceBFG[z = 1:Z, rs in eachindex(Residuals), t = 1:T],
        sum(
            MESS[:vPGen][g, t] * dfGen[!, :Bioenergy_Rate_MMBTU_per_MWh][g] * 1.055 / HVs[rs] for
            g in intersect(
                BFG,
                dfGen[dfGen.Zone .== Zones[z], :R_ID],
                dfGen[dfGen.Bioenergy .== Residuals[rs], :R_ID],
            );
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:eBBalance], -MESS[:eBBalanceBFG])
    add_to_expression!.(MESS[:eBDemandAddition], MESS[:eBBalanceBFG])

    return MESS
end
