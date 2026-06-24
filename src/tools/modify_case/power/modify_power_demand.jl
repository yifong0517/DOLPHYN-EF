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
function modify_power_demand(
    power_settings::Dict,
    power_inputs::Dict,
    modification::Union{Int64, Float64, AbstractArray{Float64}, AbstractMatrix{Float64}},
    Row::Integer = 1,
)

    if typeof(modification) in [Int64, Float64]
        ## Multiply the power sector demand with modification to scale as a whole
        power_inputs["D"] *= modification
        print_and_log(power_settings, "i", "Rescale the Power Demand with $modification")
    elseif typeof(modification) == Array{Float64}
        if size(power_inputs["D"], 2) == size(modification)
            ## Replace the specified row of power sector demand with modification
            power_inputs["D"][Row, :] = modification
            print_and_log(power_settings, "i", "Replace Row $Row of Power Demand with Modification")
        else
            print_and_log(power_settings, "i", "Power Sector Demand Untouched, Wrong Array Length")
        end
    elseif typeof(modification) == Matrix{Float64}
        if size(power_inputs["D"]) == size(modification)
            ## Replace the power sector demand with modification
            power_inputs["D"] = modification
            print_and_log(power_settings, "i", "Replace the Power Demand with Modification")
        else
            print_and_log(power_settings, "i", "Power Sector Demand Untouched, Wrong Matrix Shape")
        end
    else
        print_and_log(power_settings, "e", "Wrong Modification Type")
    end

    return power_inputs
end
