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
function carbon_disposal_in_hydrogen(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(
        settings,
        "i",
        "Hydrogen Sector Captured Carbon from Point Source Disposal Module",
    )

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    ## Hydrogen sector inputs
    hydrogen_inputs = inputs["HydrogenInputs"]
    dfDisposal = hydrogen_inputs["dfDisposal"]

    ### Expressions ###
    ## Objective Expressions ##
    ## Captured carbon transport disposal
    @expression(
        MESS,
        eHObjCO2DisposalTransportOZT[z = 1:Z, t = 1:T],
        MESS[:eHCapture][z, t] *
        dfDisposal[!, "Carbon_Transport_Cost_per_tonne_per_mile"][z] *
        dfDisposal[!, "Average_Transport_Distance"][z]
    )

    @expression(
        MESS,
        eHObjCO2DisposalTransportOZ[z = 1:Z],
        sum(MESS[:eHObjCO2DisposalTransportOZT][z, t] for t in 1:T)
    )

    @expression(
        MESS,
        eHObjCO2DisposalTransport,
        sum(MESS[:eHObjCO2DisposalTransportOZ][z] for z in 1:Z)
    )

    ## Add term to objective function expression
    add_to_expression!(MESS[:eHObj], MESS[:eHObjCO2DisposalTransport])

    ## Captured carbon geological storage disposal
    @expression(
        MESS,
        eHObjCO2DisposalStorageOZT[z = 1:Z, t = 1:T],
        MESS[:eHCapture][z, t] * dfDisposal[!, "Carbon_Storage_Cost_per_tonne"][z]
    )

    @expression(
        MESS,
        eHObjCO2DisposalStorageOZ[z = 1:Z],
        sum(MESS[:eHObjCO2DisposalStorageOZT][z, t] for t in 1:T)
    )

    @expression(
        MESS,
        eHObjCO2DisposalStorage,
        sum(MESS[:eHObjCO2DisposalStorageOZ][z] for z in 1:Z)
    )

    ## Add term to objective function expression
    add_to_expression!(MESS[:eHObj], MESS[:eHObjCO2DisposalStorage])
    ## End Objective Expressions ##
    ### End Expressions ###

    return MESS
end
