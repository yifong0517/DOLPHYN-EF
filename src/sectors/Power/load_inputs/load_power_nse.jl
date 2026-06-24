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
    load_power_nse(path::AbstractString, power_settings::Dict, inputs::Dict)

"""
function load_power_nse(path::AbstractString, power_settings::Dict, inputs::Dict)

    ## Power sector inputs dictionary
    power_inputs = inputs["PowerInputs"]

    path = joinpath(path, power_settings["NsePath"])
    dfNse = DataFrame(CSV.File(path, header = true), copycols = true)

    power_inputs["SEG"] = size(collect(skipmissing(dfNse[!, :Demand_Segment])), 1)

    ## Max value of non-served energy
    power_inputs["Voll"] = collect(skipmissing(dfNse[!, :Voll]))

    ## Cost of non-served energy/demand curtailment (for each segment)
    SEG = power_inputs["SEG"]  # Number of demand segments
    power_inputs["Demand_Curtail_Cost"] = zeros(SEG)
    power_inputs["Max_Demand_Curtail"] = zeros(SEG)
    for s in 1:SEG
        ## Cost of each segment reported as a fraction of value of non-served energy - scaled implicitly
        power_inputs["Demand_Curtail_Cost"][s] =
            collect(skipmissing(dfNse[!, :Cost_of_Demand_Curtailment_per_MW]))[s] *
            power_inputs["Voll"][1]
        ## Maximum hourly demand curtailable as % of the max demand (for each segment)
        power_inputs["Max_Demand_Curtail"][s] =
            collect(skipmissing(dfNse[!, :Max_Demand_Curtailment]))[s]
    end

    print_and_log(power_settings, "i", "Non-served-energy Data Successfully Read from $path")

    inputs["PowerInputs"] = power_inputs

    return inputs
end
