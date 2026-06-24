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
function generation_clg(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Synfuels Generation Coal Liquefaction Resources Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]

    synfuels_settings = settings["SynfuelsSettings"]
    synfuels_inputs = inputs["SynfuelsInputs"]
    dfGen = synfuels_inputs["dfGen"]
    CLG = synfuels_inputs["CLG"]

    ### Expressions ###
    ## Synfuels generation from coal liquefaction generators - used for writing results, this term is added into balance already
    @expression(
        MESS,
        eSGenerationCLG[z = 1:Z, t = 1:T],
        sum(
            MESS[:vSGen][g, t] for g in intersect(CLG, dfGen[dfGen.Zone .== Zones[z], :R_ID]);
            init = 0.0,
        )
    )

    ## Sub zonal coal liquefaction generation expressions
    if synfuels_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = synfuels_inputs["SubZones"]
        ## Synfuels sector sub zonal coal liquefaction generation
        @expression(
            MESS,
            eSGenerationSubZonalCLG[z in SubZones, t = 1:T],
            sum(
                MESS[:vSGen][g, t] for g in intersect(CLG, dfGen[dfGen.SubZone .== z, :R_ID]);
                init = 0.0,
            ),
        )
    end
    ### End Expressions ###

    return MESS
end
