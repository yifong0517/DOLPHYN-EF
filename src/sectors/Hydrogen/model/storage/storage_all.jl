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
function storage_all(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Hydrogen Storage Core Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    hydrogen_inputs = inputs["HydrogenInputs"]
    dfSto = hydrogen_inputs["dfSto"]

    S = hydrogen_inputs["S"]

    ## Hydrogen sector storage discharge
    MESS = storage_discharge(settings, inputs, MESS)

    ## Hydrogen sector storage charge
    MESS = storage_charge(settings, inputs, MESS)

    ## Hydrogen sector storage energy
    MESS = storage_energy(settings, inputs, MESS)

    ### Expressions ###
    ## Term to represent net dispatch from storage in any period
    @expression(
        MESS,
        eHBalanceStoDis[z in 1:Z, t in 1:T],
        sum(
            MESS[:vHStoDis][s, t] for s in intersect(1:S, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    @expression(
        MESS,
        eHBalanceStoCha[z in 1:Z, t in 1:T],
        sum(
            -MESS[:vHStoCha][s, t] for s in intersect(1:S, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    @expression(
        MESS,
        eHBalanceSto[z in 1:Z, t in 1:T],
        sum(
            MESS[:vHStoDis][s, t] - MESS[:vHStoCha][s, t] for
            s in intersect(1:S, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:eHBalance], MESS[:eHBalanceSto])
    ### End Expressions ###

    return MESS
end
