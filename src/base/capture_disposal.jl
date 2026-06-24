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
function capture_disposal(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Captured Carbon from Point Source Disposal Module")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    if settings["CO2Disposal"] == 1
        @expression(MESS, eObjCO2DisposalTransportOZT[z = 1:Z, t = 1:T], AffExpr(0))
        @expression(MESS, eObjCO2DisposalStorageOZT[z = 1:Z, t = 1:T], AffExpr(0))
        ## Power sector carbon disposal costs for transport and storage
        if settings["ModelPower"] == 1
            add_to_expression!.(
                MESS[:eObjCO2DisposalTransportOZT],
                MESS[:ePObjCO2DisposalTransportOZT],
            )
            add_to_expression!.(MESS[:eObjCO2DisposalStorageOZT], MESS[:ePObjCO2DisposalStorageOZT])
        end
        ## Hydrogen sector carbon disposal costs for transport and storage
        if settings["ModelHydrogen"] == 1
            add_to_expression!.(
                MESS[:eObjCO2DisposalTransportOZT],
                MESS[:eHObjCO2DisposalTransportOZT],
            )
            add_to_expression!.(MESS[:eObjCO2DisposalStorageOZT], MESS[:eHObjCO2DisposalStorageOZT])
        end
        ## Synfuels sector carbon disposal costs for transport and storage
        if settings["ModelSynfuels"] == 1
            add_to_expression!.(
                MESS[:eObjCO2DisposalTransportOZT],
                MESS[:eSObjCO2DisposalTransportOZT],
            )
            add_to_expression!.(MESS[:eObjCO2DisposalStorageOZT], MESS[:eSObjCO2DisposalStorageOZT])
        end
        ## Ammonia sector carbon disposal costs for transport and storage
        if settings["ModelAmmonia"] == 1
            add_to_expression!.(
                MESS[:eObjCO2DisposalTransportOZT],
                MESS[:eAObjCO2DisposalTransportOZT],
            )
            add_to_expression!.(MESS[:eObjCO2DisposalStorageOZT], MESS[:eAObjCO2DisposalStorageOZT])
        end
    elseif settings["CO2Disposal"] == 2
        dfDisposal = inputs["dfDisposal"]
        ### Expressions ###
        ## Captured carbon transport disposal
        @expression(
            MESS,
            eObjCO2DisposalTransportOZT[z = 1:Z, t = 1:T],
            MESS[:eCapture][z, t] *
            dfDisposal[!, "Carbon_Transport_Cost_per_tonne_per_mile"][z] *
            dfDisposal[!, "Average_Transport_Distance"][z]
        )

        ## Captured carbon geological storage disposal
        @expression(
            MESS,
            eObjCO2DisposalStorageOZT[z = 1:Z, t = 1:T],
            MESS[:eCapture][z, t] * dfDisposal[!, "Carbon_Storage_Cost_per_tonne"][z]
        )
    end

    ## Captured carbon zonal transport disposal
    @expression(
        MESS,
        eObjCO2DisposalTransportOZ[z = 1:Z],
        sum(MESS[:eObjCO2DisposalTransportOZT][z, t] for t in 1:T)
    )

    ## Captured carbon transport disposal
    @expression(
        MESS,
        eObjCO2DisposalTransport,
        sum(MESS[:eObjCO2DisposalTransportOZ][z] for z in 1:Z)
    )

    ## Captured carbon zonal storage disposal
    @expression(
        MESS,
        eObjCO2DisposalStorageOZ[z = 1:Z],
        sum(MESS[:eObjCO2DisposalStorageOZT][z, t] for t in 1:T)
    )

    ## Captured carbon storage disposal
    @expression(MESS, eObjCO2DisposalStorage, sum(MESS[:eObjCO2DisposalStorageOZ][z] for z in 1:Z))

    ## Captured carbon disposal
    @expression(
        MESS,
        eObjCarbonDisposal[z = 1:Z, t = 1:T],
        MESS[:eObjCO2DisposalTransportOZT][z, t] + MESS[:eObjCO2DisposalStorageOZT][z, t]
    )

    return MESS
end
