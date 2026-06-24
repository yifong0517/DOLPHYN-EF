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
function generation_must_run(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Generation Must Run Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    ## Get power sector settings
    power_settings = settings["PowerSettings"]
    CapReserve = power_settings["CapReserve"]
    PReserve = power_settings["PReserve"]

    ## Get generators' data from dataframe
    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]

    MUST_RUN = power_inputs["MUST_RUN"]
    if CapReserve >= 1
        GEN_CRSV = power_inputs["GEN_CRSV"]
    end
    if PReserve == 1
        GEN_PRSV = power_inputs["GEN_PRSV"]
    end

    ### Expressions ###
    ## Balance Expressions ##
    @expression(
        MESS,
        ePBalanceMustRun[z in 1:Z, t in 1:T],
        sum(
            MESS[:vPGen][g, t] for g in intersect(MUST_RUN, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    ## Capacity reserve must run expressions
    if CapReserve >= 1
        @expression(
            MESS,
            ePGenCapacityReserveMustRun[p in 1:CapReserve, z in 1:Z, t in 1:T],
            sum(
                dfGen[!, Symbol("CRV$p")][g] * MESS[:vPGen][g, t] for
                g in intersect(MUST_RUN, GEN_CRSV, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
                init = 0.0,
            )
        )

        add_to_expression!.(MESS[:ePGenCapacityReserve], MESS[:ePGenCapacityReserveMustRun])
    end

    ## Primary reserve must run expressions
    if PReserve == 1
        @expression(
            MESS,
            ePGenPrimaryReserveMustRun[z in 1:Z, t in 1:T],
            sum(
                MESS[:vPGenPRSV][g, t] for
                g in intersect(MUST_RUN, GEN_PRSV, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
                init = 0.0,
            )
        )

        add_to_expression!.(MESS[:ePGenPrimaryReserve], MESS[:ePGenPrimaryReserveMustRun])
    end

    ## Sub zonal must run generation expressions
    if power_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = power_inputs["SubZones"]
        ## Power sector sub zonal must run generation
        @expression(
            MESS,
            ePGenerationSubZonalMustRun[z in SubZones, t in 1:T],
            sum(
                MESS[:vPGen][g, t] for g in intersect(MUST_RUN, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            )
        )
    end
    ### End Expressions ###

    ### Constraints ###
    if PReserve == 1
        ## Generation and primary reserve equal to capacity factor
        @constraint(
            MESS,
            cPGenPRSVMustRun[g in intersect(MUST_RUN, GEN_PRSV), t in 1:T],
            MESS[:vPGen][g, t] + MESS[:vPGenPRSV][g, t] ==
            MESS[:ePGenCap][g] * power_inputs["P_Max"][g, t]
        )
        @constraint(
            MESS,
            cPGenMustRun[g in setdiff(MUST_RUN, GEN_PRSV), t in 1:T],
            MESS[:vPGen][g, t] == MESS[:ePGenCap][g] * power_inputs["P_Max"][g, t]
        )
    else
        ## Generation equal to capacity factor
        @constraint(
            MESS,
            cPGenMustRun[g in MUST_RUN, t in 1:T],
            MESS[:vPGen][g, t] == MESS[:ePGenCap][g] * power_inputs["P_Max"][g, t]
        )
    end
    ### End Constraints ###

    return MESS
end
