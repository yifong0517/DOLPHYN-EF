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
function generate_bioenergy(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Generating Bioenergy Sub Model")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    bioenergy_inputs = inputs["BioenergyInputs"]
    bioenergy_settings = settings["BioenergySettings"]

    Residuals = bioenergy_inputs["Residuals"]

    ## Bioenergy sector objective
    @expression(MESS, eBObj, AffExpr(0))

    ## Bioenergy sector generation, transmission, storage and demand balance,
    ## specific for each residual in foodstuff sector
    @expression(MESS, eBBalance[z in 1:Z, rs in eachindex(Residuals), t in 1:T], AffExpr(0))

    ## Bioenergy sector emissions
    @expression(MESS, eBEmissions[z in 1:Z, t in 1:T], AffExpr(0))

    ## Bioenergy sector captured emissions
    @expression(MESS, eBCapture[z in 1:Z, t in 1:T], AffExpr(0))

    ## Bioenergy sector feedstock consumption
    MESS = consumption_in_bioenergy(settings, inputs, MESS)

    ## Bioenergy sector residuals collection (foodstuff sector collection, forestry collection and marginal land collection)
    MESS = bioenergy_residuals(settings, inputs, MESS)

    ## Bioenergy sector transmission
    @expression(MESS, eBTransmission[z in 1:Z, rs in eachindex(Residuals), t in 1:T], AffExpr(0))

    ## Bioenergy sector transport
    if bioenergy_settings["ResidualTransport"] == 1
        MESS = residual_transport(settings, inputs, MESS)
    end

    ## Bioenergy sector truck transmission
    if bioenergy_settings["ModelTrucks"] == 1
        MESS = truck_investment(settings, inputs, MESS)
        MESS = truck_all(settings, inputs, MESS)
    end

    ## Bioenergy sector storage
    if bioenergy_settings["ModelStorage"] == 1
        MESS = storage_investment_volume(settings, inputs, MESS)
        MESS = storage_volume(settings, inputs, MESS)
    end

    ## Bioenergy sector demand
    MESS = demand_all(settings, inputs, MESS)

    ## Bioenergy sector feedstock consumption
    MESS = consumption(settings, inputs, MESS)

    # Bioenergy sector emission policy
    if !in(0, bioenergy_settings["CO2Policy"])
        MESS = bioenergy_emission_policy(settings, inputs, MESS)
    end

    ## Add bioenergy sector objective into total objective function
    add_to_expression!(MESS[:eObj], MESS[:eBObj])

    ## Add bioenergy sector emissions into total emissions
    add_to_expression!.(MESS[:eEmissions], MESS[:eBEmissions])

    ## Add bioenergy sector captured carbon into total captured carbon
    add_to_expression!.(MESS[:eCapture], MESS[:eBCapture])

    return MESS
end
