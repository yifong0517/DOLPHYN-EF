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
function generate_synfuels(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Generating Synfuels Sub Model")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    synfuels_settings = settings["SynfuelsSettings"]

    ## Synfuels sector objective
    @expression(MESS, eSObj, AffExpr(0))

    ## Synfuels sector generation, transmission, storage and demand balance
    @expression(MESS, eSBalance[z in 1:Z, t in 1:T], AffExpr(0))

    ## Synfuels sector emissions
    @expression(MESS, eSEmissions[z in 1:Z, t in 1:T], AffExpr(0))

    ## Synfuels sector captured emissions
    @expression(MESS, eSCapture[z in 1:Z, t in 1:T], AffExpr(0))

    ## Synfuels sector feedstock consumption
    MESS = consumption_in_synfuels(settings, inputs, MESS)

    ## Synfuels sector generation
    MESS = generation_investment(settings, inputs, MESS)
    MESS = generation_all(settings, inputs, MESS)

    ## Synfuels sector transmission
    @expression(MESS, eSTransmission[z in 1:Z, t in 1:T], AffExpr(0))

    ## Synfuels sector transport
    if synfuels_settings["SimpleTransport"] == 1
        MESS = synfuels_transport(settings, inputs, MESS)
    end

    ## Synfuels sector pipeline transmission
    if synfuels_settings["ModelPipelines"] == 1
        MESS = pipeline_investment(settings, inputs, MESS)
        MESS = pipeline_all(settings, inputs, MESS)
    end

    ## Synfuels sector trucks transmission
    if synfuels_settings["ModelTrucks"] == 1
        MESS = truck_investment(settings, inputs, MESS)
        MESS = truck_all(settings, inputs, MESS)
    end

    ## Synfuels sector storage
    if synfuels_settings["ModelStorage"] == 1
        MESS = storage_investment(settings, inputs, MESS)
        MESS = storage_all(settings, inputs, MESS)
    end

    ## Synfuels sector demand
    MESS = demand_all(settings, inputs, MESS)

    ## Synfuels sector feedstock consumption
    MESS = consumption(settings, inputs, MESS)

    ## Synfuels sector emission policy
    if !in(0, synfuels_settings["CO2Policy"])
        MESS = synfuels_emission_policy(settings, inputs, MESS)
    end

    ## Synfuels sector minimum capacity policy
    if synfuels_settings["MinCapacity"] >= 1
        MESS = synfuels_capacity_minimum(settings, inputs, MESS)
    end

    ## Synfuels sector maximum capacity policy
    if synfuels_settings["MaxCapacity"] >= 1
        MESS = synfuels_capacity_maximum(settings, inputs, MESS)
    end

    ## Synfuels sector captured carbon disposal
    if synfuels_settings["CO2Disposal"] == 1
        MESS = carbon_disposal_in_synfuels(settings, inputs, MESS)
    end

    ## Add synfuels sector objective into total objective function
    add_to_expression!(MESS[:eObj], MESS[:eSObj])

    ## Add synfuels sector emissions into total emissions
    add_to_expression!.(MESS[:eEmissions], MESS[:eSEmissions])

    ## Add synfuels sector captured carbon into total captured carbon
    add_to_expression!.(MESS[:eCapture], MESS[:eSCapture])

    return MESS
end
