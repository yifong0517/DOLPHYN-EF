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

    print_and_log(settings, "i", "Carbon Storage Core Module")

    carbon_settings = settings["CarbonSettings"]

    ## Flags
    AllowDis = carbon_settings["AllowDis"]

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    carbon_inputs = inputs["CarbonInputs"]
    dfSto = carbon_inputs["dfSto"]

    S = carbon_inputs["S"]

    ## Carbon sector storage discharge
    if AllowDis == 1
        MESS = storage_discharge(settings, inputs, MESS)
    end
    ## Carbon sector storage charge
    MESS = storage_charge(settings, inputs, MESS)
    ## Carbon sector storage energy
    MESS = storage_energy(settings, inputs, MESS)

    ### Expressions ###
    ## Term to represent discharge from storage in any period
    if AllowDis == 1
        @expression(
            MESS,
            eCBalanceStoDis[z in 1:Z, t in 1:T],
            sum(
                MESS[:vCStoDis][s, t] for s in intersect(1:S, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
                init = 0.0,
            )
        )
    end

    ## Term to represent charge from storage in any period
    @expression(
        MESS,
        eCBalanceStoCha[z in 1:Z, t in 1:T],
        sum(
            -MESS[:vCStoCha][s, t] for s in intersect(1:S, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    ## Term to represent net dispatch from storage in any period
    if AllowDis == 1
        @expression(
            MESS,
            eCBalanceSto[z in 1:Z, t in 1:T],
            sum(
                MESS[:vCStoDis][s, t] - MESS[:vCStoCha][s, t] for
                s in intersect(1:S, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
                init = 0.0,
            )
        )
    else
        @expression(MESS, eCBalanceSto[z in 1:Z, t in 1:T], MESS[:eCBalanceStoCha][z, t])
    end

    add_to_expression!.(MESS[:eCBalance], MESS[:eCBalanceSto])
    ### End Expressions ###

    ### Constraints ###
    if carbon_settings["StorageOnly"] == 1
        print_and_log(settings, "w", "Carbon Storage is Put into Deployment Compulsively")
        @constraint(
            MESS,
            cCStoOnlyCha[z in 1:Z],
            -sum(MESS[:eCBalanceStoCha][z, t] for t in 1:T) >= carbon_inputs["D_Sto"][z]
        )
    end
    ### End Constraints ###

    return MESS
end
