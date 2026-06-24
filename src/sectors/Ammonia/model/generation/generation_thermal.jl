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
	generation_thermal(inputs::Dict, MESS::Model)

"""
function generation_thermal(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Ammonia Generation Thermal Resources Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    ammonia_settings = settings["AmmoniaSettings"]
    ammonia_inputs = inputs["AmmoniaInputs"]
    dfGen = ammonia_inputs["dfGen"]

    THERM = ammonia_inputs["THERM"]

    ### Expressions ###
    ## Balance Expressions ##
    @expression(
        MESS,
        eABalanceTherm[z in 1:Z, t in 1:T],
        sum(
            MESS[:vAGen][g, t] for g in intersect(THERM, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:eABalance], MESS[:eABalanceTherm])
    add_to_expression!.(MESS[:eAGeneration], MESS[:eABalanceTherm])
    ## End Balance Expressions ##
    ## Sub zonal thermal generation expressions
    if ammonia_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = ammonia_inputs["SubZones"]
        ## Synfuels sector sub zonal thermal generation
        @expression(
            MESS,
            eAGenerationSubZonalTherm[z in SubZones, t = 1:T],
            sum(
                MESS[:vAGen][g, t] for g in intersect(THERM, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            ),
        )

        ## Add thermal generation onto sub zonal generation
        add_to_expression!.(MESS[:eAGenerationSubZonal], MESS[:eAGenerationSubZonalTherm])
    end
    ### End Expressions ###

    return MESS
end
