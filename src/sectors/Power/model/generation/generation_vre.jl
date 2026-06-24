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
function generation_vre(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Generation Renewable Resources Module")

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

    VRE = power_inputs["VRE"]
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
        ePBalanceVRE[z in 1:Z, t in 1:T],
        sum(
            MESS[:vPGen][g, t] for g in intersect(VRE, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:ePBalance], MESS[:ePBalanceVRE])
    add_to_expression!.(MESS[:ePGeneration], MESS[:ePBalanceVRE])

    ## Power sector available vre generation
    @expression(
        MESS,
        ePAvailableVRE[z in 1:Z, t in 1:T],
        sum(
            MESS[:ePGenCap][g] * power_inputs["P_Max"][g, t] for
            g in intersect(VRE, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    ## Capacity reserve vre expressions
    if CapReserve >= 1
        @expression(
            MESS,
            ePGenCapacityReserveVRE[p in 1:CapReserve, z in 1:Z, t in 1:T],
            sum(
                dfGen[!, Symbol("CRV$p")][g] * MESS[:vPGen][g, t] for
                g in intersect(VRE, GEN_CRSV, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
                init = 0.0,
            )
        )

        add_to_expression!.(MESS[:ePGenCapacityReserve], MESS[:ePGenCapacityReserveVRE])
    end

    ## Primary reserve vre expressions
    if PReserve == 1
        @expression(
            MESS,
            ePGenPrimaryReserveVRE[z in 1:Z, t in 1:T],
            sum(
                MESS[:vPGenPRSV][g, t] for
                g in intersect(VRE, GEN_PRSV, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
                init = 0.0,
            )
        )

        add_to_expression!.(MESS[:ePGenPrimaryReserve], MESS[:ePGenPrimaryReserveVRE])
    end

    ## Sub zonal vre generation expressions
    if power_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = power_inputs["SubZones"]
        ## Power sector sub zonal vre generation
        @expression(
            MESS,
            ePGenerationVRESubZonal[z in SubZones, t in 1:T],
            sum(
                MESS[:vPGen][g, t] for g in intersect(VRE, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            )
        )

        ## Add vre generation onto sub zonal generation
        add_to_expression!.(MESS[:ePGenerationSubZonal], MESS[:ePGenerationVRESubZonal])

        ## Power sector sub zonal available vre generation
        @expression(
            MESS,
            ePAvailableVRESubZonal[z in SubZones, t in 1:T],
            sum(
                MESS[:ePGenCap][g] * power_inputs["P_Max"][g, t] for
                g in intersect(VRE, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            )
        )
    end
    ### End Expressions ###

    ### Constraints ###
    ## Constraints on contribution to regulation and reserves
    ## Maximum power generated per hour by renewable generators must be less than
    ## sum of product of hourly capacity factor for each bin times its the bin installed capacity
    ## Note: inequality constraint allows curtailment of output below maximum level.
    if PReserve == 1
        ## For VRE, reserve contributions must be less than the specified percentage of the capacity factor for the hour
        @constraint(
            MESS,
            cPGenMaxReserveVRECap[g in intersect(VRE, GEN_PRSV), t = 1:T],
            MESS[:vPGenPRSV][g, t] <=
            dfGen[!, :PRSV_Max][g] * power_inputs["P_Max"][g, t] * MESS[:ePGenCap][g]
        )
        ## Power generated and regulation reserve contributions down per hour must be greater than zero
        @constraint(
            MESS,
            cPGenMaxReserveVRE[g in intersect(VRE, GEN_PRSV), t = 1:T],
            MESS[:vPGen][g, t] - MESS[:vPGenPRSV][g, t] >= 0
        )

        ## Power generated and reserve contributions up per hour by renewable generators must be less than
        ## hourly capacity factor. Note: inequality constraint allows curtailment of output below maximum level.
        @constraint(
            MESS,
            cPGenMaxPowerVREPRSV[g in intersect(VRE, GEN_PRSV), t = 1:T],
            MESS[:vPGen][g, t] + MESS[:vPGenPRSV][g, t] <=
            power_inputs["P_Max"][g, t] * MESS[:ePGenCap][g],
        )
        @constraint(
            MESS,
            cPGenMaxPowerVRE[g in setdiff(VRE, GEN_PRSV), t in 1:T],
            MESS[:vPGen][g, t] <= power_inputs["P_Max"][g, t] * MESS[:ePGenCap][g]
        )
    else
        @constraint(
            MESS,
            cPGenMaxPowerVRE[g in VRE, t in 1:T],
            MESS[:vPGen][g, t] <= power_inputs["P_Max"][g, t] * MESS[:ePGenCap][g]
        )
    end
    ### End Constraints ###

    return MESS
end
