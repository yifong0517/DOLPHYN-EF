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
function generation_ele(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Hydrogen Generation Electrolyser Resources Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    hydrogen_settings = settings["HydrogenSettings"]

    hydrogen_inputs = inputs["HydrogenInputs"]
    dfGen = hydrogen_inputs["dfGen"]

    ELE = hydrogen_inputs["ELE"]

    ### Expressions ###
    ## Balance Expressions ##
    @expression(
        MESS,
        eHBalanceELE[z in 1:Z, t in 1:T],
        sum(
            MESS[:vHGen][g, t] for g in intersect(ELE, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:eHBalance], MESS[:eHBalanceELE])
    add_to_expression!.(MESS[:eHGeneration], MESS[:eHBalanceELE])
    ## End Balance Expressions ##

    ## Sub zonal eletrolyser generation expressions
    if hydrogen_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = hydrogen_inputs["SubZones"]
        ## Hydrogen sector sub zonal electrolyser generation
        @expression(
            MESS,
            eHGenerationSubZonalELE[z in SubZones, t = 1:T],
            sum(
                MESS[:vHGen][g, t] for g in intersect(ELE, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            ),
        )

        ## Add thermal generation onto sub zonal generation
        add_to_expression!.(MESS[:eHGenerationSubZonal], MESS[:eHGenerationSubZonalELE])
    end

    ## Balance Expressions ##
    if settings["ModelPower"] == 1
        @expression(
            MESS,
            ePBalanceHELE[z in 1:Z, t in 1:T],
            sum(
                MESS[:vHGen][g, t] * dfGen[!, :Electricity_Rate_MWh_per_tonne][g] for
                g in intersect(ELE, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
                init = 0.0,
            )
        )
        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceHELE])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceHELE])
    end
    ## End Balance Expressions ##
    ### End Expressions ###

    return MESS
end
