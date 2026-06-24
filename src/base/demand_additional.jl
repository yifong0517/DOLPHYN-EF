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
function demand_additional(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Demand Additional Module")

    ### Expressions ###
    if settings["ModelPower"] == 1
        ## Add additional demand from other sectors into demand
        add_to_expression!.(MESS[:ePDemand], MESS[:ePDemandAddition])
    end

    if settings["ModelHydrogen"] == 1
        ## Add additional demand from other sectors into demand
        add_to_expression!.(MESS[:eHDemand], MESS[:eHDemandAddition])
    end

    if settings["ModelCarbon"] == 1
        ## Add additional demand from other sectors into demand
        add_to_expression!.(MESS[:eCDemand], MESS[:eCDemandAddition])
    end

    if settings["ModelSynfuels"] == 1
        ## Add additional demand from other sectors into demand
        add_to_expression!.(MESS[:eSDemand], MESS[:eSDemandAddition])
    end

    if settings["ModelAmmonia"] == 1
        ## Add additional demand from other sectors into demand
        add_to_expression!.(MESS[:eADemand], MESS[:eADemandAddition])
    end

    if settings["ModelBioenergy"] == 1
        ## Add additional demand from other sectors into demand
        add_to_expression!.(MESS[:eBDemand], MESS[:eBDemandAddition])
    end

    return MESS
end
