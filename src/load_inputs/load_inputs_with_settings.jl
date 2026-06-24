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
function load_inputs_with_settings(settings::Dict)

    print_and_log(settings, "i", "Loading Multi Energy System Inputs with Settings")

    ## Initialize inputs dictionary
    inputs = Dict()

    ## Load spatial inputs
    inputs = load_spatial_inputs(settings, inputs)

    ## Load temporal inputs
    inputs = load_temporal_inputs(settings, inputs)

    ## Load external price signals
    inputs = load_external_inputs(settings, inputs)

    ## Load power sector inputs
    if settings["ModelPower"] == 1
        inputs = load_power_inputs(settings, inputs)
        ## Update power sector settings due to internal changes
        settings = update_power_settings(settings, inputs)
    end

    ## Load hydrogen sector inputs
    if settings["ModelHydrogen"] == 1
        inputs = load_hydrogen_inputs(settings, inputs)
        ## Update hydrogen sector settings due to internal changes
        settings = update_hydrogen_settings(settings, inputs)
    end

    ## Load carbon sector inputs
    if settings["ModelCarbon"] == 1
        inputs = load_carbon_inputs(settings, inputs)
        ## Update carbon sector settings due to internal changes
        settings = update_carbon_settings(settings, inputs)
    end

    ## Load synfuels sector inputs
    if settings["ModelSynfuels"] == 1
        inputs = load_synfuels_inputs(settings, inputs)
        ## Update synfuels sector settings due to internal changes
        settings = update_synfuels_settings(settings, inputs)
    end

    ## Load ammonia sector inputs
    if settings["ModelAmmonia"] == 1
        inputs = load_ammonia_inputs(settings, inputs)
        ## Update ammonia sector settings due to internal changes
        settings = update_ammonia_settings(settings, inputs)
    end

    ## Load foodstuff sector inputs
    if settings["ModelFoodstuff"] == 1
        inputs = load_foodstuff_inputs(settings, inputs)
        ## Update foodstuff sector settings due to internal changes
        settings = update_foodstuff_settings(settings, inputs)
    end

    ## Load bioenergy sector inputs
    if settings["ModelBioenergy"] == 1
        inputs = load_bioenergy_inputs(settings, inputs)
        ## Update bioenergy sector settings due to internal changes
        settings = update_bioenergy_settings(settings, inputs)
    end

    ## Load auxiliary inputs
    inputs = load_auxiliary_inputs(settings, inputs)

    return inputs
end
