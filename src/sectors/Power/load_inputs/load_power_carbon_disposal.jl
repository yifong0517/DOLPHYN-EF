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
function load_power_carbon_disposal(path::AbstractString, power_settings::Dict, inputs::Dict)

    ## Set indices for internal use
    T = inputs["T"]   # Number of time steps (hours)
    Zones = inputs["Zones"] # List of modeled zones

    ## Power sector inputs dictionary
    power_inputs = inputs["PowerInputs"]

    ## Carbon disposal related inputs
    path = joinpath(path, power_settings["DisposalPath"])
    dfDisposal = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter disposal costs in modeled zones
    dfDisposal = filter(row -> (row.Zone in Zones), dfDisposal)

    ## Store DataFrame of disposal input data for use in model
    power_inputs["dfDisposal"] = dfDisposal

    print_and_log(
        power_settings,
        "i",
        "Power Sector Carbon Disposal Policy Data Successfully Read from $path",
    )

    inputs["PowerInputs"] = power_inputs

    return inputs
end
