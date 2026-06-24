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

    print_and_log(settings, "i", "Power Storage Core Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    ## Get power sector settings
    power_settings = settings["PowerSettings"]
    CapReserve = power_settings["CapReserve"]
    PReserve = power_settings["PReserve"]

    power_inputs = inputs["PowerInputs"]
    dfSto = power_inputs["dfSto"]

    S = power_inputs["S"]
    if CapReserve >= 1
        STO_CRSV = power_inputs["STO_CRSV"]
    end
    if PReserve == 1
        STO_PRSV = power_inputs["STO_PRSV"]
    end
    AGING_STO = power_inputs["AGING_STO"]

    ## Power sector storage discharge
    MESS = storage_discharge(settings, inputs, MESS)

    ## Power sector storage charge
    MESS = storage_charge(settings, inputs, MESS)

    ## Power sector storage energy
    MESS = storage_energy(settings, inputs, MESS)

    ## Power sector storage aging
    if !isempty(AGING_STO)
        MESS = storage_aging(settings, inputs, MESS)
    end

    ### Expressions ###
    ## Term to represent net dispatch from storage in any period
    @expression(
        MESS,
        ePBalanceStoDis[z in 1:Z, t in 1:T],
        sum(
            MESS[:vPStoDis][s, t] for s in intersect(1:S, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    @expression(
        MESS,
        ePBalanceStoCha[z in 1:Z, t in 1:T],
        sum(
            -MESS[:vPStoCha][s, t] for s in intersect(1:S, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    @expression(
        MESS,
        ePBalanceSto[z in 1:Z, t in 1:T],
        sum(
            MESS[:vPStoDis][s, t] - MESS[:vPStoCha][s, t] for
            s in intersect(1:S, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:ePBalance], MESS[:ePBalanceSto])

    ## Capacity reserve storage expressions
    if CapReserve >= 1
        @expression(
            MESS,
            ePStoCapacityReserve[p in 1:CapReserve, z in 1:Z, t in 1:T],
            sum(
                dfSto[!, Symbol("CRV$p")][s] * (MESS[:vPStoDis][s, t] - MESS[:vPStoCha][s, t]) for
                s in intersect(1:S, STO_CRSV, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
                init = 0.0,
            )
        )
    end

    ## Primary reserve storage expressions
    if PReserve == 1
        @expression(
            MESS,
            ePStoPrimaryReserve[z in 1:Z, t in 1:T],
            sum(
                MESS[:vPStoDisPRSV][s, t] + MESS[:vPStoChaPRSV][s, t] for
                s in intersect(1:S, dfSto[dfSto.Zone .== Zones[z], :R_ID]);
                init = 0.0,
            ),
        )
    end
    ### End Expressions ###

    return MESS
end
