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
function modify_hydrogen_generator_efficiency(
    hydrogen_settings::Dict,
    hydrogen_inputs::Dict,
    modification::Union{Int64, Float64},
)

    dfGen = hydrogen_inputs["dfGen"]

    if modification < 1
        print_and_log(
            hydrogen_settings,
            "i",
            "Reset Hydrogen Generators' Efficiency to $modification",
        )
        ## 100/3 is used to scale electricity rate from percentage to unit consumption
        dfGen[!, :Efficiency] .= modification
        dfGen[!, :Electricity_Rate_MWh_per_tonne] .= 100 / 3 / modification
    else
        print_and_log(
            hydrogen_settings,
            "i",
            "Rescale Hydrogen Generators' Efficiency to $(modification)x",
        )
        dfGen[!, :Efficiency] .*= modification
        if max(dfGen[!, :Efficiency]) > 1
            print_and_log(
                hydrogen_settings,
                "w",
                "Overshooting Efficiency. Reset Hydrogen Generators' Efficiency to 1",
            )
            dfGen[!, :Efficiency] .= 1
        end
        dfGen[!, :Electricity_Rate_MWh_per_tonne] .= 100 / 3 / modification
    end

    hydrogen_inputs["dfGen"] = dfGen

    return hydrogen_inputs
end
