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
function power_energy_share(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Sector Energy Share Policy Module")

    ## Power sector settings
    power_settings = settings["PowerSettings"]

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    ## Power sector inputs
    power_inputs = inputs["PowerInputs"]
    dfEss = power_inputs["dfEss"]
    dfGen = power_inputs["dfGen"]
    if power_settings["ModelStorage"] == 1
        dfSto = power_inputs["dfSto"]
    end

    EnergyShareStandard = power_settings["EnergyShareStandard"]

    ## If storage is not modeled, then energy share standard must be renewable portfolio standard
    if power_settings["ModelStorage"] != 1
        EnergyShareStandard = min(EnergyShareStandard, 1)
    end

    if EnergyShareStandard <= 3
        if EnergyShareStandard == 1
            ## Energy Share Standard: renewable portfolio standard
            GEN_RPS = power_inputs["GEN_RPS"]
            @expression(
                MESS,
                ePGenerationRPS[z in 1:Z, t in 1:T],
                sum(
                    MESS[:vPGen][g, t] for
                    g in intersect(dfGen[dfGen.Zone .== Zones[z], :R_ID], GEN_RPS)
                )
            )

            @constraint(
                MESS,
                cPEnergyShareStandardRPS[z in 1:Z],
                sum(weights[t] * MESS[:ePGenerationRPS][z, t] for t in 1:T) >=
                dfEss[!, :RPS][z] * sum(weights[t] * MESS[:ePDemand][z, t] for t in 1:T)
            )
        end

        if EnergyShareStandard == 2
            ## Energy Share Standard: clean energy standard
            GEN_CES = power_inputs["GEN_CES"]
            STO_CES = power_inputs["STO_CES"]

            ## Energy supply from resources eligible to clean energy standard
            @expression(MESS, ePSupplyCES[z in 1:Z, t in 1:T], 0)

            ## Energy supply from generation resources eligible to clean energy standard
            @expression(
                MESS,
                ePGenerationCES[z in 1:Z, t in 1:T],
                sum(
                    MESS[:vPGen][g, t] for
                    g in intersect(GEN_CES, dfGen[dfGen.Zone .== Zones[z], :R_ID])
                )
            )

            add_to_expression!.(MESS[:ePSupplyCES], MESS[:ePGenerationCES])

            ## Energy supply from storage resources eligible to clean energy standard
            @expression(
                MESS,
                ePStorageCES[z in 1:Z, t in 1:T],
                sum(
                    MESS[:vPStoDis][s, t] for
                    s in intersect(STO_CES, dfSto[dfSto.Zone .== Zones[z], :R_ID])
                )
            )

            add_to_expression!.(MESS[:ePSupplyCES], MESS[:ePStorageCES])

            @constraint(
                MESS,
                cPEnergyShareStandardCES[z in 1:Z, t in 1:T],
                sum(weights[t] * MESS[:ePSupplyCES][z, t] for t in 1:T) >=
                dfEss[!, :CES][z] * sum(weights[t] * MESS[:ePDemand][z, t] for t in 1:T)
            )
        end
    end

    return MESS
end
