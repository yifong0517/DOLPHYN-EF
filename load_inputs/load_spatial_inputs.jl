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
    load_spatial_inputs(settings::Dict, inputs::Dict)


"""
function load_spatial_inputs(settings::Dict, inputs::Dict)

    print_and_log(settings, "i", "Loading Multi Energy System Spatial Inputs")

    ## Parse spatial modeling zone set
    Zones = settings["Zones"]

    ## Parse X-Y to [X, X+1, ..., Y]
    if typeof(Zones) == String
        print_and_log(
            settings,
            "i",
            "Parsing Sequential Zones Inputs like 'X-Y' into List '[X, X+1, ..., Y]'",
        )
        X, Y = split(Zones, "-")
        Zones = collect(parse(Int, X):parse(Int, Y))
    end

    print_and_log(settings, "i", "Spatial Modeling Set: $Zones")

    inputs["Zones"] = Zones

    ## Parse spatial modeling zone number
    Z = length(inputs["Zones"])
    inputs["Z"] = Z

    ## Indicator of spatial scope
    if Z == 1
        inputs["OneZone"] = true
    else
        inputs["OneZone"] = false
    end

    print_and_log(settings, "i", "Spatial Modeling Index: 1-$Z")

    return inputs
end
