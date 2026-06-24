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
function generate_carbon(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Generating Carbon Sub Model")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    carbon_settings = settings["CarbonSettings"]

    ## Carbon sector objective
    @expression(MESS, eCObj, AffExpr(0))

    ## Carbon sector generation, transmission, storage and demand balance
    @expression(MESS, eCBalance[z in 1:Z, t in 1:T], AffExpr(0))

    ## Carbon sector emissions
    @expression(MESS, eCEmissions[z in 1:Z, t in 1:T], AffExpr(0))

    ## Carbon sector captured emissions
    @expression(MESS, eCCapture[z in 1:Z, t in 1:T], AffExpr(0))

    ## Carbon sector feedstock consumption
    MESS = consumption_in_carbon(settings, inputs, MESS)

    ## Carbon sector capture from direct air
    if carbon_settings["ModelDAC"] == 1
        MESS = capture_investment(settings, inputs, MESS)
        MESS = capture_all(settings, inputs, MESS)
    else
        @expression(MESS, eCCaptureDirectAir[z in 1:Z, t in 1:T], AffExpr(0))
    end

    ## Total capture
    add_to_expression!.(MESS[:eCCapture], MESS[:eCCaptureDirectAir])
    ## Direct air capture
    add_to_expression!.(MESS[:eDCapture], MESS[:eCCaptureDirectAir])

    ## Carbon sector transmission
    @expression(MESS, eCTransmission[z in 1:Z, t in 1:T], AffExpr(0))

    ## Carbon sector simple transport
    if carbon_settings["SimpleTransport"] == 1
        MESS = carbon_transport(settings, inputs, MESS)
    end

    ## Carbon sector pipeline transmission
    if carbon_settings["ModelPipelines"] == 1
        MESS = pipeline_investment(settings, inputs, MESS)
        MESS = pipeline_all(settings, inputs, MESS)
    end

    ## Carbon sector truck transmission
    if carbon_settings["ModelTrucks"] == 1
        MESS = truck_investment(settings, inputs, MESS)
        MESS = truck_all(settings, inputs, MESS)
    end

    ## Carbon sector storage
    if carbon_settings["ModelStorage"] == 1
        MESS = storage_investment(settings, inputs, MESS)
        MESS = storage_all(settings, inputs, MESS)
    end

    ## Carbon sector demand
    MESS = demand_all(settings, inputs, MESS)

    ## Carbon sector feedstock consumption
    MESS = consumption(settings, inputs, MESS)

    # Carbon sector emission policy
    if !in(0, carbon_settings["CO2Policy"])
        MESS = carbon_emission_policy(settings, inputs, MESS)
    end

    ## Add carbon sector objective into total objective function
    add_to_expression!(MESS[:eObj], MESS[:eCObj])

    ## Add power sector emissions into total emissions
    add_to_expression!.(MESS[:eEmissions], MESS[:eCEmissions])

    ## Add power sector captured carbon into total captured carbon
    add_to_expression!.(MESS[:eCapture], MESS[:eCCapture])

    return MESS
end
