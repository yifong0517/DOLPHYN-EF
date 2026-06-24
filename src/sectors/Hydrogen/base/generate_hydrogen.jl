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
function generate_hydrogen(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Generating Hydrogen Sub Model")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    hydrogen_settings = settings["HydrogenSettings"]

    ## Hydrogen sector objective
    @expression(MESS, eHObj, AffExpr(0))

    ## Hydrogen sector generation, transmission, storage and demand balance
    @expression(MESS, eHBalance[z in 1:Z, t in 1:T], AffExpr(0))

    ## Hydrogen sector emissions
    @expression(MESS, eHEmissions[z in 1:Z, t in 1:T], AffExpr(0))

    ## Hydrogen sector captured emissions
    @expression(MESS, eHCapture[z in 1:Z, t in 1:T], AffExpr(0))

    ## Hydrogen sector feedstock consumption
    MESS = consumption_in_hydrogen(settings, inputs, MESS)

    ## Hydrogen sector generation
    MESS = generation_investment(settings, inputs, MESS)
    MESS = generation_all(settings, inputs, MESS)

    ## Hydrogen sector transmission
    @expression(MESS, eHTransmission[z in 1:Z, t in 1:T], AffExpr(0))

    ## Hydrogen sector simple transport
    if hydrogen_settings["SimpleTransport"] == 1
        MESS = hydrogen_transport(settings, inputs, MESS)
    end

    ## Hydrogen sector pipeline transmission
    if hydrogen_settings["ModelPipelines"] == 1
        MESS = pipeline_investment(settings, inputs, MESS)
        MESS = pipeline_all(settings, inputs, MESS)
    end

    ## Hydrogen sector truck transmission
    if hydrogen_settings["ModelTrucks"] == 1
        MESS = truck_investment(settings, inputs, MESS)
        MESS = truck_all(settings, inputs, MESS)
    end

    ## Hydrogen sector storage
    if hydrogen_settings["ModelStorage"] == 1
        MESS = storage_investment(settings, inputs, MESS)
        MESS = storage_all(settings, inputs, MESS)
    end

    ## Hydrogen sector demand
    MESS = demand_all(settings, inputs, MESS)

    ## Hydrogen sector feedstock consumption
    MESS = consumption(settings, inputs, MESS)

    ## Hydrogen sector emission policy
    if !in(0, hydrogen_settings["CO2Policy"])
        MESS = hydrogen_emission_policy(settings, inputs, MESS)
    end

    ## Hydrogen sector minimum capacity policy
    if hydrogen_settings["MinCapacity"] >= 1
        MESS = hydrogen_capacity_minimum(settings, inputs, MESS)
    end

    ## Hydrogen sector maximum capacity policy
    if hydrogen_settings["MaxCapacity"] >= 1
        MESS = hydrogen_capacity_maximum(settings, inputs, MESS)
    end

    ## Hydrogen sector captured carbon disposal
    if hydrogen_settings["CO2Disposal"] == 1
        MESS = carbon_disposal_in_hydrogen(settings, inputs, MESS)
    end

    ## Add hydrogen sector objective into total objective function
    add_to_expression!(MESS[:eObj], MESS[:eHObj])

    ## Add hydrogen sector emissions into total emissions
    add_to_expression!.(MESS[:eEmissions], MESS[:eHEmissions])

    ## Add hydrogen sector captured carbon into total captured carbon
    add_to_expression!.(MESS[:eCapture], MESS[:eHCapture])

    return MESS
end
