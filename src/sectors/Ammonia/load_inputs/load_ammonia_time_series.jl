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
function load_ammonia_time_series(settings::Dict, inputs::Dict)

    ## Read ammonia sector settings
    if typeof(settings["AmmoniaSettings"]) != String
        ammonia_settings = settings["AmmoniaSettings"]
    else
        ammonia_settings = load_ammonia_settings(settings)
        settings["AmmoniaSettings"] = ammonia_settings
    end

    ## Ammonia sector data path
    path = joinpath(settings["RootPath"], settings["AmmoniaInputs"])

    ## Ammonia inputs dictionary
    inputs["AmmoniaInputs"] = Dict()

    ## Read in ammonia sector generator/resource related inputs
    inputs = load_ammonia_generators(path, ammonia_settings, inputs)

    ## Read in ammonia sector generator/resource availability profiles
    inputs = load_ammonia_generators_variability(path, ammonia_settings, inputs)

    ## Read in ammonia sector demand data
    inputs = load_ammonia_demand(path, ammonia_settings, inputs)

    return inputs
end
