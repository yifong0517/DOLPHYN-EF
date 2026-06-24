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
    update_hydrogen_settings(settings::Dict, inputs::Dict)

"""
function update_hydrogen_settings(settings::Dict, inputs::Dict)

    ## Read hydrogen sector settings
    hydrogen_settings = settings["HydrogenSettings"]

    ## Read hydrogen sector inputs
    hydrogen_inputs = inputs["HydrogenInputs"]

    ## Update hydrogen sector settings
    if hydrogen_inputs["OneZone"] == 1
        ## Corresponding to ```load_hydrogen_inputs``` line 79
        hydrogen_settings["SimpleTransport"] = 0
        ## Corresponding to ```load_hydrogen_inputs``` line 80
        hydrogen_settings["ModelPipelines"] = 0
        ## Corresponding to ```load_hydrogen_inputs``` line 81
        hydrogen_settings["ModelTrucks"] = 0
    end

    ## Store hydrogen settings in global settings
    settings["HydrogenSettings"] = hydrogen_settings

    return settings
end
