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
function bioenergy_residuals(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Bioenergy Sector Residuals Collection Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    bioenergy_inputs = inputs["BioenergyInputs"]
    bioenergy_settings = settings["BioenergySettings"]

    ## All residuals considered in bioenergy sector
    Residuals = bioenergy_inputs["Residuals"]

    @expression(MESS, eBResiduals[z in 1:Z, rs in eachindex(Residuals), t in 1:T], AffExpr(0))

    ## Residuals collection expression construction in a blocked way
    if settings["ModelFoodstuff"] == 1
        ## Residuals from foodstuff sector
        foodstuff_inputs = inputs["FoodstuffInputs"]
        Straws = foodstuff_inputs["Straws"]
        if !isempty(intersect(Residuals, Straws))
            MESS = foodstuff_residuals_straw(settings, inputs, MESS)
        end
        Agriculture_Production_Residuals = foodstuff_inputs["Agriculture_Production_Residuals"]
        if !isempty(intersect(Residuals, Agriculture_Production_Residuals))
            MESS = foodstuff_residuals_production(settings, inputs, MESS)
        end
    else
        ## TODO: Residuals without foodstuff sector
        bioenergy_inputs = inputs["BioenergyInputs"]
    end

    add_to_expression!.(MESS[:eBBalance], MESS[:eBResiduals])

    return MESS
end
