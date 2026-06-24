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
function load_synfuels_time_series(settings::Dict, inputs::Dict)

    ## Read synfuels sector settings
    if typeof(settings["SynfuelsSettings"]) != String
        synfuels_settings = settings["SynfuelsSettings"]
    else
        synfuels_settings = load_synfuels_settings(settings)
        settings["SynfuelsSettings"] = synfuels_settings
    end

    ## Synfuels sector data path
    path = joinpath(settings["RootPath"], settings["SynfuelsInputs"])

    ## Synfuels inputs dictionary
    inputs["SynfuelsInputs"] = Dict()

    ## Read in synfuels sector generator/resource related inputs
    inputs = load_synfuels_generators(path, synfuels_settings, inputs)

    ## Read in synfuels sector generator/resource availability profiles
    inputs = load_synfuels_generators_variability(path, synfuels_settings, inputs)

    ## Read in synfuels sector demand data
    inputs = load_synfuels_demand(path, synfuels_settings, inputs)

    return inputs
end
