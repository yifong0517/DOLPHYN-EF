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
function consumption_blg(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Bioenergy Synfuels Liqufication Consumption Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    bioenergy_settings = settings["BioenergySettings"]
    HVs = bioenergy_settings["HVs"]

    ## Get synfuels sector generators' data from dataframe
    synfuels_inputs = inputs["SynfuelsInputs"]
    dfGen = synfuels_inputs["dfGen"]
    BLG = synfuels_inputs["BLG"]

    ## Get bioenergy sector residual list
    bioenergy_inputs = inputs["BioenergyInputs"]
    Residuals = bioenergy_inputs["Residuals"]

    ## Bioenergy consumption for synfuels generation from resource "g" during hour "t"
    ## 1.055 is the conversion factor from MMBTu to GJ
    @expression(
        MESS,
        eBBalanceBLG[z = 1:Z, rs in eachindex(Residuals), t = 1:T],
        sum(
            MESS[:vSGen][g, t] * dfGen[!, :Bioenergy_Rate_MMBTU_per_tonne][g] * 1.055 / HVs[rs] for
            g in intersect(
                BLG,
                dfGen[dfGen.Zone .== Zones[z], :R_ID],
                dfGen[dfGen.Bioenergy .== Residuals[rs], :R_ID],
            );
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:eBBalance], -MESS[:eBBalanceBLG])
    add_to_expression!.(MESS[:eBDemandAddition], MESS[:eBBalanceBLG])

    return MESS
end
