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
function generate_power(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Generating Power Sub Model")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    power_settings = settings["PowerSettings"]
    QuadricEmission = power_settings["QuadricEmission"]

    ## Power sector objective
    @expression(MESS, ePObj, AffExpr(0))

    ## Power sector generation, transmission, storage and demand balance
    @expression(MESS, ePBalance[z in 1:Z, t in 1:T], AffExpr(0))

    ## Power sector emissions
    @expression(MESS, ePEmissions[z in 1:Z, t in 1:T], AffExpr(0))

    ## Power sector captured emissions
    @expression(MESS, ePCapture[z in 1:Z, t in 1:T], AffExpr(0))

    ## Power sector feedstock consumption
    MESS = consumption_in_power(settings, inputs, MESS)

    ## Power sector generation
    MESS = generation_investment(settings, inputs, MESS)
    MESS = generation_all(settings, inputs, MESS)

    ## Power sector transmission
    @expression(MESS, ePTransmission[z = 1:Z, t = 1:T], AffExpr(0))
    if power_settings["ModelTransmission"] == 1
        MESS = transmission_investment(settings, inputs, MESS)
        MESS = transmission_all(settings, inputs, MESS)
        if power_settings["DCPowerFlow"] == 1
            MESS = transmission_dcopf(settings, inputs, MESS)
        end
    end

    ## Power sector storage
    if power_settings["ModelStorage"] == 1
        MESS = storage_investment(settings, inputs, MESS)
        MESS = storage_all(settings, inputs, MESS)
    end

    ## Power sector demand
    MESS = demand_all(settings, inputs, MESS)

    ## Power sector feedstock consumption
    MESS = consumption(settings, inputs, MESS)

    ## Power sector emission policy
    if !in(0, power_settings["CO2Policy"])
        MESS = power_emission_policy(settings, inputs, MESS)
    end

    ## Power sector capacity reserve policy
    if power_settings["CapReserve"] >= 1
        MESS = power_capacity_reserve(settings, inputs, MESS)
    end

    ## Power sector primary reserve policy
    if power_settings["PReserve"] == 1
        MESS = power_primary_reserve(settings, inputs, MESS)
    end

    ## Power sector energy share policy
    if power_settings["EnergyShareStandard"] >= 1
        MESS = power_energy_share(settings, inputs, MESS)
    end

    ## Power sector minimum capacity policy
    if power_settings["MinCapacity"] >= 1
        MESS = power_capacity_minimum(settings, inputs, MESS)
    end

    ## Power sector maximum capacity policy
    if power_settings["MaxCapacity"] >= 1
        MESS = power_capacity_maximum(settings, inputs, MESS)
    end

    ## Power sector captured carbon disposal
    if power_settings["CO2Disposal"] == 1
        MESS = carbon_disposal_in_power(settings, inputs, MESS)
    end

    ## Add power sector objective into total objective function
    if QuadricEmission == 1
        MESS[:eObj] += MESS[:ePObj]
    else
        add_to_expression!.(MESS[:eObj], MESS[:ePObj])
    end

    ## Add power sector emissions into total emissions
    if QuadricEmission == 1
        MESS[:eEmissions] += MESS[:ePEmissions]
    else
        add_to_expression!.(MESS[:eEmissions], MESS[:ePEmissions])
    end

    ## Add power sector captured carbon into total captured carbon
    if QuadricEmission == 1
        MESS[:eCapture] += MESS[:ePCapture]
    else
        add_to_expression!.(MESS[:eCapture], MESS[:ePCapture])
    end

    return MESS
end
