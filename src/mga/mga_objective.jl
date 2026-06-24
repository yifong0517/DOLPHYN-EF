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
function mga_objective(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Modeling to Generate Alternative Objective Module")

    ### Expressions ###
    ## Remove MGA objective expression from previous model
    if haskey(MESS, :eMGAObjective)
        unregister(MESS, :eMGAObjective)
    end
    @expression(MESS, eMGAObjective, AffExpr(0))
    ### End Expressions ###

    ## Power sector mga objective expression
    if settings["ModelPower"] == 1
        MESS = power_mga_objective(settings, inputs, MESS)
    end

    ## Hydrogen sector mga objective expression
    if settings["ModelHydrogen"] == 1
        MESS = hydrogen_mga_objective(settings, inputs, MESS)
    end

    ## Carbon sector mga objective expression
    if settings["ModelCarbon"] == 1
        MESS = carbon_mga_objective(settings, inputs, MESS)
    end

    ## Synfuels sector mga objective expression
    if settings["ModelSynfuels"] == 1
        MESS = synfuels_mga_objective(settings, inputs, MESS)
    end

    ## Ammonia sector mga objective expression
    if settings["ModelAmmonia"] == 1
        MESS = ammonia_mga_objective(settings, inputs, MESS)
    end

    return MESS
end
