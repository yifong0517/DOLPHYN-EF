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
function load_time_series(settings::Dict, inputs::Dict)

    ## Used in clustering
    pre_inputs = Dict()

    pre_inputs["T"] = inputs["T"]
    pre_inputs["Time_Index"] = inputs["Time_Index"]

    ## Load spatial inputs
    pre_inputs = load_spatial_inputs(settings, pre_inputs)

    ## Load external resources price signals and availability
    pre_inputs = load_external_inputs(settings, pre_inputs)

    ## Load power sector inputs for clustering
    if settings["ModelPower"] == 1
        pre_inputs = load_power_time_series(settings, pre_inputs)
    end

    ## Load hydrogen sector inputs for clustering
    if settings["ModelHydrogen"] == 1
        pre_inputs = load_hydrogen_time_series(settings, pre_inputs)
    end

    ## Load carbon sector inputs for clustering
    if settings["ModelCarbon"] == 1
        pre_inputs = load_carbon_time_series(settings, pre_inputs)
    end

    ## Load synfuels sector inputs for clustering
    if settings["ModelSynfuels"] == 1
        pre_inputs = load_synfuels_time_series(settings, pre_inputs)
    end

    ## Load ammonia sector inputs for clustering
    if settings["ModelAmmonia"] == 1
        pre_inputs = load_ammonia_time_series(settings, pre_inputs)
    end

    return pre_inputs
end
