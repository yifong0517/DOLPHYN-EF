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
function power_storage_patch(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Applying Power Storage Patch")

    power_settings = settings["PowerSettings"]
    IncludeExistingSto = power_settings["IncludeExistingSto"]

    power_inputs = inputs["PowerInputs"]
    STO_ASYMMETRIC = power_inputs["STO_ASYMMETRIC"]

    ### Expressions ###
    ## Auxiliary expressions - costs contribution from storage energy
    @expression(MESS, eAuxPObjStoEnergy, MESS[:ePObjFixInvStoEne] + MESS[:ePObjFixFomStoEne])
    if IncludeExistingSto == 1
        add_to_expression!(MESS[:eAuxPObjStoEnergy], MESS[:ePObjFixSunkInvStoEne])
    end

    ## Auxiliary expressions - Costs contribution from storage power
    if !isempty(STO_ASYMMETRIC)
        @expression(
            MESS,
            eAuxPObjStoPower,
            MESS[:ePObjFixInvStoDis] +
            MESS[:ePObjFixFomStoDis] +
            MESS[:ePObjVarStoDis] +
            MESS[:ePObjFixInvStoCha] +
            MESS[:ePObjFixFomStoCha] +
            MESS[:ePObjVarStoCha]
        )
    else
        @expression(
            MESS,
            eAuxPObjStoPower,
            MESS[:ePObjFixInvStoDis] +
            MESS[:ePObjFixFomStoDis] +
            MESS[:ePObjVarStoDis] +
            MESS[:ePObjVarStoCha]
        )
    end
    if IncludeExistingSto == 1
        add_to_expression!(
            MESS[:eAuxPObjStoPower],
            MESS[:ePObjFixSunkInvStoDis] + MESS[:ePObjFixSunkInvStoCha],
        )
    end
    ### End Expressions ###

    return MESS
end
