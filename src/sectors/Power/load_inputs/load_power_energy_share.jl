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
function load_power_energy_share(path::AbstractString, power_settings::Dict, inputs::Dict)

    Zones = inputs["Zones"] # List of modeled zones

    ## Power sector inputs dictionary
    power_inputs = inputs["PowerInputs"]
    power_inputs["EnergyShareStandard"] = power_settings["EnergyShareStandard"]

    ## Energy share standard policy related inputs
    path = joinpath(path, power_settings["EnergySharePath"])
    dfEss = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter energy share policy in modeled zones
    dfEss = filter(row -> (row.Zone in Zones), dfEss)

    ## Store dataframe of energy share standard for use in model
    power_inputs["dfEss"] = dfEss

    dfGen = power_inputs["dfGen"]
    if power_settings["ModelStorage"] == 1
        dfSto = power_inputs["dfSto"]
    end

    ## Set of generators with renewable portfolio standard (RPS) eligibility
    power_inputs["GEN_RPS"] = dfGen[dfGen.RPS .== 1, :R_ID]

    ## Set of generators with clean energy standard (CES) eligibility
    power_inputs["GEN_CES"] = dfGen[dfGen.CES .== 1, :R_ID]

    ## Set of storage with clean energy standard (CES) eligibility
    if power_settings["ModelStorage"] == 1
        power_inputs["STO_CES"] = dfSto[dfSto.CES .== 1, :R_ID]
    end

    print_and_log(power_settings, "i", "Energy Share Policy Successfully Read from $path")

    inputs["PowerInputs"] = power_inputs

    return inputs
end
