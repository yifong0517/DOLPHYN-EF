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
    update_foodstuff_settings(settings::Dict, inputs::Dict)

"""
function update_foodstuff_settings(settings::Dict, inputs::Dict)

    ## Read foodstuff sector settings
    foodstuff_settings = settings["FoodstuffSettings"]

    ## Read foodstuff sector inputs
    foodstuff_inputs = inputs["FoodstuffInputs"]

    ## Update foodstuff sector settings
    if foodstuff_inputs["OneZone"] == 1
        ## Corresponding to ```load_foodstuff_inputs``` line 55
        foodstuff_settings["ModelTrucks"] = 0
        ## Corresponding to ```load_foodstuff_inputs``` line 56
        foodstuff_settings["CropTransport"] = 0
        ## Corresponding to ```load_foodstuff_inputs``` line 57
        foodstuff_settings["FoodTransport"] = 0
    end

    if foodstuff_settings["FoodTransport"] == 1
        ## Corresponding to ```load_foodstuff_inputs``` line 69
        foodstuff_settings["ModelTrucks"] = 0
    end

    if foodstuff_settings["ModelTrucks"] == 0
        ## Corresponding to ```load_foodstuff_inputs``` line 75
        foodstuff_settings["TruckExpansion"] = 0
    end

    ## Store foodstuff settings in global settings
    settings["FoodstuffSettings"] = foodstuff_settings

    return settings
end
