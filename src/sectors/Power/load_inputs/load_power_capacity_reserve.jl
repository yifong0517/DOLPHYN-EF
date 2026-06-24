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
function load_power_capacity_reserve(path::AbstractString, power_settings::Dict, inputs::Dict)

    Zones = inputs["Zones"] # List of modeled zones

    ## Power sector inputs dictionary
    power_inputs = inputs["PowerInputs"]

    ## Primary reserve policy related inputs
    path = joinpath(path, power_settings["CapReservePath"])
    dfCrv = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Number of capacity reserve policies
    CapReserve = power_settings["CapReserve"]

    ## Filter capacity reserve policy in modeled zones
    dfCrv = filter(row -> (row.Zone in Zones), dfCrv)

    ## Store dataframe of capacity reserve for use in model
    power_inputs["dfCrv"] = dfCrv

    dfGen = power_inputs["dfGen"]
    dfSto = power_inputs["dfSto"]

    ## Set of generators with capacity reserve (PRSV) eligibility
    power_inputs["GEN_CRSV"] = sort(
        unique(reduce(vcat, [dfGen[dfGen[!, Symbol("CRV$i")] .> 0, :R_ID] for i in 1:CapReserve])),
    )

    ## Set of storage with capacity reserve (PRSV) eligibility
    power_inputs["STO_CRSV"] = sort(
        unique(reduce(vcat, [dfSto[dfSto[!, Symbol("CRV$i")] .> 0, :R_ID] for i in 1:CapReserve])),
    )

    inputs["PowerInputs"] = power_inputs

    print_and_log(power_settings, "i", "Capacity Reserve Policy Successfully Read from $path")

    return inputs
end
