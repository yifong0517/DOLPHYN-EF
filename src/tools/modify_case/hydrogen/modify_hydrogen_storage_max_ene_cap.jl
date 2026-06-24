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
function modify_hydrogen_storage_max_ene_cap(
    hydrogen_settings::Dict,
    hydrogen_inputs::Dict,
    modification::Union{AbstractString, Int64, Float64},
)

    dfSto = hydrogen_inputs["dfSto"]

    ## Check type of modification to have modification applied
    if typeof(modification) <: AbstractString && modification == "infinite"
        dfSto[!, :Max_Ene_Cap_tonne] .= -1
    elseif typeof(modification) in [Int64, Float64]
        dfSto[!, :Max_Ene_Cap_tonne] .= modification
        overshooting = dfSto[dfSto.Max_Ene_Cap_tonne .> dfSto.Existing_Ene_Cap_tonne, :R_ID]
        if !isempty(overshooting)
            print_and_log(
                hydrogen_settings,
                "w",
                "Some resources have overshooting existing energy capacity than maximum capacity.\n $overshooting",
            )
        end
    end

    hydrogen_inputs["dfSto"] = dfSto

    return hydrogen_inputs
end
