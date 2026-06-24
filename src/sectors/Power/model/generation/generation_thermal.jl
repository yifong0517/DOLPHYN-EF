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
	generation_thermal(inputs::Dict, MESS::Model)

"""
function generation_thermal(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Generation Thermal Resources Module")

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

    THERM = power_inputs["THERM"]
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
        ePBalanceTherm[z in 1:Z, t in 1:T],
        sum(
            MESS[:vPGen][g, t] for g in intersect(THERM, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:ePBalance], MESS[:ePBalanceTherm])
    add_to_expression!.(MESS[:ePGeneration], MESS[:ePBalanceTherm])
    ## End Balance Expressions ##

    ## Capacity reserve thermal expressions
    if CapReserve >= 1
        @expression(
            MESS,
            ePGenCapacityReserveTherm[p in 1:CapReserve, z in 1:Z, t in 1:T],
            sum(
                dfGen[!, Symbol("CRV$p")][g] * MESS[:ePGenCap][g] for
                g in intersect(THERM, GEN_CRSV, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
                init = 0.0,
            )
        )

        add_to_expression!.(MESS[:ePGenCapacityReserve], MESS[:ePGenCapacityReserveTherm])
    end

    ## Primary reserve thermal expressions
    if PReserve == 1
        @expression(
            MESS,
            ePGenPrimaryReserveTherm[z in 1:Z, t in 1:T],
            sum(
                MESS[:vPGenPRSV][g, t] for
                g in intersect(THERM, GEN_PRSV, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
                init = 0.0,
            )
        )

        add_to_expression!.(MESS[:ePGenPrimaryReserve], MESS[:ePGenPrimaryReserveTherm])
    end

    ## Sub zonal thermal generation expressions
    if power_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = power_inputs["SubZones"]
        ## Power sector sub zonal thermal generation
        @expression(
            MESS,
            ePGenerationSubZonalTherm[z in SubZones, t in 1:T],
            sum(
                MESS[:vPGen][g, t] for g in intersect(THERM, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            )
        )

        ## Add thermal generation onto sub zonal generation
        add_to_expression!.(MESS[:ePGenerationSubZonal], MESS[:ePGenerationSubZonalTherm])
    end
    ### End Expressions ###

    return MESS
end
