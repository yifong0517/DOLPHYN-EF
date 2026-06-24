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
function generate_ammonia(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Generating Ammonia Sub Model")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    ammonia_settings = settings["AmmoniaSettings"]

    ## Ammonia sector objective
    @expression(MESS, eAObj, AffExpr(0))

    ## Ammonia sector generation, transmission, storage and demand balance
    @expression(MESS, eABalance[z in 1:Z, t in 1:T], AffExpr(0))

    ## Ammonia sector emissions
    @expression(MESS, eAEmissions[z in 1:Z, t in 1:T], AffExpr(0))

    ## Ammonia sector captured emissions
    @expression(MESS, eACapture[z in 1:Z, t in 1:T], AffExpr(0))

    ## Ammonia sector feedstock consumption
    MESS = consumption_in_ammonia(settings, inputs, MESS)

    ## Ammonia sector generation
    MESS = generation_investment(settings, inputs, MESS)
    MESS = generation_all(settings, inputs, MESS)

    ## Ammonia sector transmission
    @expression(MESS, eATransmission[z in 1:Z, t in 1:T], AffExpr(0))

    ## Ammonia sector simple transport
    if ammonia_settings["SimpleTransport"] == 1
        MESS = ammonia_transport(settings, inputs, MESS)
    end

    ## Ammonia sector truck transmission
    if ammonia_settings["ModelTrucks"] == 1
        MESS = truck_investment(settings, inputs, MESS)
        MESS = truck_all(settings, inputs, MESS)
    end

    ## Ammonia sector storage
    if ammonia_settings["ModelStorage"] == 1
        MESS = storage_investment(settings, inputs, MESS)
        MESS = storage_all(settings, inputs, MESS)
    end

    ## Ammonia sector demand
    MESS = demand_all(settings, inputs, MESS)

    ## Ammonia sector feedstock consumption
    MESS = consumption(settings, inputs, MESS)

    ## Ammonia sector emission policy
    if !in(0, ammonia_settings["CO2Policy"])
        MESS = ammonia_emission_policy(settings, inputs, MESS)
    end

    ## Ammonia sector minimum capacity policy
    if ammonia_settings["MinCapacity"] >= 1
        MESS = ammonia_capacity_minimum(settings, inputs, MESS)
    end

    ## Ammonia sector maximum capacity policy
    if ammonia_settings["MaxCapacity"] >= 1
        MESS = ammonia_capacity_maximum(settings, inputs, MESS)
    end

    ## Ammonia sector captured carbon disposal
    if ammonia_settings["CO2Disposal"] == 1
        MESS = carbon_disposal_in_ammonia(settings, inputs, MESS)
    end

    ## Add ammonia sector objective into total objective function
    add_to_expression!(MESS[:eObj], MESS[:eAObj])

    ## Add ammonia sector emissions into total emissions
    add_to_expression!.(MESS[:eEmissions], MESS[:eAEmissions])

    ## Add ammonia sector captured carbon into total captured carbon
    add_to_expression!.(MESS[:eCapture], MESS[:eACapture])

    return MESS
end
