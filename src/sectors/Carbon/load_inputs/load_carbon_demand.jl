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
	load_carbon_demand(path::AbstractString, carbon_settings::Dict, inputs::Dict)

Function for reading input parameters related to electricity demand.
"""
function load_carbon_demand(path::AbstractString, carbon_settings::Dict, inputs::Dict)

    ## Set indices for internal use
    T = inputs["T"]   # Total number of time steps (hours)
    Zones = inputs["Zones"] # List of modeled zones

    ## Carbon sector inputs dictionary
    carbon_inputs = inputs["CarbonInputs"]

    path = joinpath(path, carbon_settings["DemandPath"])
    load_in = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Demand in tonne for each zone
    carbon_inputs["D"] = transpose(Matrix{Float64}(load_in[1:T, ["Load_tonne_$z" for z in Zones]]))

    ## Carbon storage compulsive deployment forces carbon demand to be transfered by storage charge
    if carbon_settings["StorageOnly"] == 1
        print_and_log(
            carbon_settings,
            "w",
            "Carbon Sector Demand is Assigned to Zero due to Storage Deployment",
        )
        carbon_inputs["D_Sto"] = sum(carbon_inputs["D"], dims = 2)
        carbon_inputs["D"] .= 0
    end

    print_and_log(carbon_settings, "i", "Demand Data Successfully Read from $path")

    inputs["CarbonInputs"] = carbon_inputs

    return inputs
end
