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
    update_synfuels_settings(settings::Dict, inputs::Dict)

"""
function update_synfuels_settings(settings::Dict, inputs::Dict)

    ## Read synfuels sector settings
    synfuels_settings = settings["SynfuelsSettings"]

    ## Read synfuels sector inputs
    synfuels_inputs = inputs["SynfuelsInputs"]

    ## Update synfuels sector settings
    if synfuels_inputs["OneZone"] == 1
        ## Corresponding to ```load_synfuels_inputs``` line 79
        synfuels_settings["SimpleTransport"] = 0
        ## Corresponding to ```load_synfuels_inputs``` line 80
        synfuels_settings["ModelPipelines"] = 0
        ## Corresponding to ```load_synfuels_inputs``` line 81
        synfuels_settings["ModelTrucks"] = 0
    end

    ## Store synfuels settings in global settings
    settings["SynfuelsSettings"] = synfuels_settings

    return settings
end
