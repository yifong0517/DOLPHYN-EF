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
function modify_hydrogen_demand(
    hydrogen_settings::Dict,
    hydrogen_inputs::Dict,
    modification::Union{Int64, Float64, Array{Float64}, Matrix{Float64}},
    Row::Integer = 1,
)

    if typeof(modification) in [Int64, Float64]
        ## Multiply the hydrogen sector demand with modification to scale as a whole
        hydrogen_inputs["D"] *= modification
        print_and_log(hydrogen_settings, "i", "Rescale the Hydrogen Demand with $modification")
    elseif typeof(modification) == Array{Float64}
        if size(hydrogen_inputs["D"], 2) == size(modification)
            ## Replace the specified row of hydrogen sector demand with modification
            hydrogen_inputs["D"][Row, :] = modification
            print_and_log(
                hydrogen_settings,
                "i",
                "Replace Row $Row of Hydrogen Demand with Modification",
            )
        else
            print_and_log(
                hydrogen_settings,
                "i",
                "Hydrogen Sector Demand Untouched, Wrong Array Length",
            )
        end
    elseif typeof(modification) == Matrix{Float64}
        if size(hydrogen_inputs["D"]) == size(modification)
            ## Replace the hydrogen sector demand with modification
            hydrogen_inputs["D"] = modification
            print_and_log(hydrogen_settings, "i", "Replace the Hydrogen Demand with Modification")
        else
            print_and_log(
                hydrogen_settings,
                "i",
                "Hydrogen Sector Demand Untouched, Wrong Matrix Shape",
            )
        end
    else
        print_and_log(hydrogen_settings, "i", "Wrong Modification Type")
    end

    return hydrogen_inputs
end
