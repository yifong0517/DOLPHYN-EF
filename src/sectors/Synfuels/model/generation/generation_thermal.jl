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

    print_and_log(settings, "i", "Synfuels Generation Thermal Resources Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    synfuels_settings = settings["SynfuelsSettings"]
    synfuels_inputs = inputs["SynfuelsInputs"]
    dfGen = synfuels_inputs["dfGen"]

    THERM = synfuels_inputs["THERM"]

    ### Expressions ###
    ## Balance Expressions ##
    @expression(
        MESS,
        eSBalanceTherm[z in 1:Z, t in 1:T],
        sum(
            MESS[:vSGen][g, t] for g in intersect(THERM, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    add_to_expression!.(MESS[:eSBalance], MESS[:eSBalanceTherm])
    add_to_expression!.(MESS[:eSGeneration], MESS[:eSBalanceTherm])
    ## End Balance Expressions ##
    ## Sub zonal thermal generation expressions
    if synfuels_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = synfuels_inputs["SubZones"]
        ## Synfuels sector sub zonal thermal generation
        @expression(
            MESS,
            eSGenerationSubZonalTherm[z in SubZones, t = 1:T],
            sum(
                MESS[:vSGen][g, t] for g in intersect(THERM, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            ),
        )

        ## Add thermal generation onto sub zonal generation
        add_to_expression!.(MESS[:eSGenerationSubZonal], MESS[:eSGenerationSubZonalTherm])
    end
    ### End Expressions ###

    return MESS
end
