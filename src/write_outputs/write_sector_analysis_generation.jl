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
function write_sector_analysis_generation(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Writing Sectorial Generation Analysis")

    ## Power sector generation analysis
    if settings["ModelPower"] == 1
        write_power_analysis_generation(settings, inputs, MESS)
        write_power_analysis_renewable(settings, inputs, MESS)
    end

    ## Hydrogen sector generation analysis
    if settings["ModelHydrogen"] == 1
        write_hydrogen_analysis_generation(settings, inputs, MESS)
    end

    ## Carbon sector generation analysis
    if settings["ModelCarbon"] == 1
        write_carbon_analysis_generation(settings, inputs, MESS)
    end

    ## Synfuels sector generation analysis
    if settings["ModelSynfuels"] == 1
        write_synfuels_analysis_generation(settings, inputs, MESS)
    end

    ## Ammonia sector generation analysis
    if settings["ModelAmmonia"] == 1
        write_ammonia_analysis_generation(settings, inputs, MESS)
    end

    ## Foodstuff sector yield analysis
    if settings["ModelFoodstuff"] == 1
        write_foodstuff_analysis(settings, inputs, MESS)
    end

    ## Bioenergy sector biomass analysis
    if settings["ModelBioenergy"] == 1
        write_bioenergy_analysis(settings, inputs, MESS)
    end
end
