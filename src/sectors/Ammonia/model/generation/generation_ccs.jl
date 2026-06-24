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
function generation_ccs(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Ammonia Point Source Capture Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    ammonia_inputs = inputs["AmmoniaInputs"]
    ammonia_settings = settings["AmmoniaSettings"]

    CCS = ammonia_inputs["CCS"]
    dfGen = ammonia_inputs["dfGen"]

    ### Expressions ###
    ## Ammonia sector point source capture ##
    @expression(
        MESS,
        eACaptureOGT[g in CCS, t = 1:T],
        dfGen[!, :CCS_Percentage][g] / (1 - dfGen[!, :CCS_Percentage][g]) *
        MESS[:eAEmissionsOGT][g, t]
    )

    @expression(
        MESS,
        eACaptureByGen[z = 1:Z, t = 1:T],
        sum(
            MESS[:eACaptureOGT][g, t] for g in intersect(CCS, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )
    add_to_expression!.(MESS[:eACapture], MESS[:eACaptureByGen])

    return MESS
end
