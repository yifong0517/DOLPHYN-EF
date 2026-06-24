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
function sector_sniffer(settings::Dict, inputs::Dict, MESS::Model, sniffer::AbstractDict)

    print_and_log(settings, "i", "Initializing Sector Sniffer for Results Recording and Analysis")

    ## Power sector sniffer
    if settings["ModelPower"] == 1
        sniffer = power_sniffer(settings, inputs, MESS, sniffer)
    end

    ## Hydrogen sector sniffer
    if settings["ModelHydrogen"] == 1
        sniffer = hydrogen_sniffer(settings, inputs, MESS, sniffer)
    end

    ## Carbon sector sniffer
    if settings["ModelCarbon"] == 1
        sniffer = carbon_sniffer(settings, inputs, MESS, sniffer)
    end

    ## Synfuels sector sniffer
    if settings["ModelSynfuels"] == 1
        sniffer = synfuels_sniffer(settings, inputs, MESS, sniffer)
    end

    ## Ammonia sector sniffer
    if settings["ModelAmmonia"] == 1
        sniffer = ammonia_sniffer(settings, inputs, MESS, sniffer)
    end

    # ## Bioenergy sector sniffer
    # if settings["ModelBioenergy"] == 1
    #     sniffer = bioenergy_sniffer(settings, inputs, MESS, sniffer)
    # end

    # ## Foodstuff sector sniffer
    # if settings["ModelFoodstuff"] == 1
    #     sniffer = foodstuff_sniffer(settings, inputs, MESS, sniffer)
    # end

    return sniffer
end
