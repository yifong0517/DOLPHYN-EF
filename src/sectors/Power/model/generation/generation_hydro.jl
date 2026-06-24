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
function generation_hydro(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Generation Hydroelectric Resource Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    ## Before shifted 1 time index
    BS1T = inputs["BS1T"]
    Period = inputs["Period"]

    ## Get power sector settings
    power_settings = settings["PowerSettings"]
    CapReserve = power_settings["CapReserve"]
    PReserve = power_settings["PReserve"]

    ## Get generators' data from dataframe
    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]

    HYDRO = power_inputs["HYDRO"]
    if CapReserve >= 1
        GEN_CRSV = power_inputs["GEN_CRSV"]
    end
    if PReserve == 1
        GEN_PRSV = power_inputs["GEN_PRSV"]
    end

    ### Variables ###
    ## Reservoir hydro storage level of resource "g" at hour "t" [MWh]
    @variable(MESS, vPHydroLevel[g in HYDRO, t = 1:T] >= 0)

    ## Hydro reservoir overflow (water spill) variable
    @variable(MESS, vPSpill[g in HYDRO, t = 1:T] >= 0)

    ### Expressions ###
    ## Balance Expressions ##
    @expression(
        MESS,
        ePBalanceHydro[z in 1:Z, t in 1:T],
        sum(
            MESS[:vPGen][g, t] for g in intersect(HYDRO, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:ePBalance], MESS[:ePBalanceHydro])
    add_to_expression!.(MESS[:ePGeneration], MESS[:ePBalanceHydro])
    ## End Balance Expressions ##

    ## Power sector available hydro generation
    @expression(
        MESS,
        ePAvailableHydro[z in 1:Z, t in 1:T],
        sum(
            MESS[:ePGenCap][g] * power_inputs["P_Max"][g, t] for
            g in intersect(HYDRO, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    ## Capacity reserve hydro expressions
    if CapReserve >= 1
        @expression(
            MESS,
            ePGenCapacityReserveHydro[p in 1:CapReserve, z in 1:Z, t in 1:T],
            sum(
                dfGen[!, Symbol("CRV$p")][g] * MESS[:vPGen][g, t] for
                g in intersect(HYDRO, GEN_CRSV, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
                init = 0.0,
            )
        )

        add_to_expression!.(MESS[:ePGenCapacityReserve], MESS[:ePGenCapacityReserveHydro])
    end

    ## Primary reserve hydro expressions
    if PReserve == 1
        @expression(
            MESS,
            ePGenPrimaryReserveHydro[z in 1:Z, t in 1:T],
            sum(
                MESS[:vPGenPRSV][g, t] for
                g in intersect(HYDRO, GEN_PRSV, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
                init = 0.0,
            )
        )

        add_to_expression!.(MESS[:ePGenPrimaryReserve], MESS[:ePGenPrimaryReserveHydro])
    end

    ## Sub zonal hydro generation expressions
    if power_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = power_inputs["SubZones"]
        ## Power sector sub zonal hydro generation
        @expression(
            MESS,
            ePGenerationSubZonalHydro[z in SubZones, t in 1:T],
            sum(
                MESS[:vPGen][g, t] for g in intersect(HYDRO, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            )
        )

        ## Add hydro generation onto sub zonal generation
        add_to_expression!.(MESS[:ePGenerationSubZonal], MESS[:ePGenerationSubZonalHydro])
    end
    ### End Expressions ###

    ### Constraints ###
    ## Hydro reservoir level constraints
    @constraint(
        MESS,
        cPGenHydroLevel[g in HYDRO, t in 1:T],
        MESS[:vPHydroLevel][g, t] ==
        MESS[:vPHydroLevel][g, BS1T[t]] - MESS[:vPGen][g, t] - vPSpill[g, t] +
        power_inputs["P_Max"][g, t] * MESS[:ePGenCap][g]
    )

    ## Hydro reservoir ramp up and down constraints
    ## Maximum ramp up between consecutive hours
    if !isempty(intersect(HYDRO, dfGen[dfGen.Ramp_Up_Percentage .< 1, :R_ID]))
        @constraint(
            MESS,
            cPGenHydroRampUp[
                g in intersect(HYDRO, dfGen[dfGen.Ramp_Up_Percentage .< 1, :R_ID]),
                t in 1:T,
            ],
            MESS[:vPGen][g, t] - MESS[:vPGen][g, BS1T[t]] <=
            dfGen[!, :Ramp_Up_Percentage][g] * MESS[:ePGenCap][g]
        )
    end

    ## Maximum ramp down between consecutive hours
    if !isempty(intersect(HYDRO, dfGen[dfGen.Ramp_Dn_Percentage .< 1, :R_ID]))
        @constraint(
            MESS,
            cPGenHydroRampDn[
                g in intersect(HYDRO, dfGen[dfGen.Ramp_Dn_Percentage .< 1, :R_ID]),
                t in 1:T,
            ],
            MESS[:vPGen][g, BS1T[t]] - MESS[:vPGen][g, t] <=
            dfGen[!, :Ramp_Dn_Percentage][g] * MESS[:ePGenCap][g]
        )
    end

    ## Minimum stable power generated per technology "g" at hour "t"
    @constraint(
        MESS,
        cPGenHydroMinPower[g in HYDRO, t = 1:T],
        MESS[:vPGen][g, t] + MESS[:vPSpill][g, t] >= dfGen[!, :Min_Power][g] * MESS[:ePGenCap][g]
    )

    ## Maximum power generated per technology "g" at hour "t"
    @constraint(
        MESS,
        cPGenHydroMaxPower[g in HYDRO, t = 1:T],
        MESS[:vPGen][g, t] <= MESS[:ePGenCap][g]
    )

    ## Hydro maximum generation
    @constraint(
        MESS,
        cPGenHydroMaxOutflow[g in HYDRO, t = 1:T],
        MESS[:vPGen][g, t] <= MESS[:vPHydroLevel][g, t]
    )

    ## Primary reserve constraints for hydro resources
    if PReserve == 1 && !isempty(intersect(HYDRO, GEN_PRSV))
        ## Maximum hydro contribution to reserves is a specified fraction of installed capacity
        @constraint(
            MESS,
            cPPrimaryReserveHydro[g in intersect(HYDRO, GEN_PRSV), t in 1:T],
            MESS[:vPGenPRSV][g, t] <= dfGen[!, :PRSV_Max][g] * MESS[:ePGenCap][g]
        )
        ## Maximum discharging rate and contribution to reserves up must be less than power rating
        @constraint(
            MESS,
            cPMaxPrimaryReserveHydroUp[g in intersect(HYDRO, GEN_PRSV), t in 1:T],
            MESS[:vPGen][g, t] + MESS[:vPGenPRSV][g, t] <= MESS[:ePGenCap][g]
        )
        ## Maximum discharging rate and contribution to regulation down must be greater than zero
        @constraint(
            MESS,
            cPMaxPrimaryReserveHydroDn[g in intersect(HYDRO, GEN_PRSV), t in 1:T],
            MESS[:vPGen][g, t] - MESS[:vPGenPRSV][g, t] >= 0
        )
    end
    ### End Constraints ###

    return MESS
end
