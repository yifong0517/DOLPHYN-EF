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
function modify_hydrogen_emission_policy(
    hydrogen_settings::Dict,
    hydrogen_inputs::Dict,
    modification::Dict,
)

    ## Check whether hydrogen sector has set carbon emission constraints
    for key in ["H_Emission_Max_Mtons", "H_Emission_Max_Rate", "H_Emission_Price_tonne"]
        if haskey(modification, key)
            if key != "H_Emission_Max_Mtons"
                modification[key[3:end]] = modification[key]
            else
                hydrogen_inputs["Emission_Max_Mtons"] = modification[key]
            end
            delete!(modification, key)
        end
    end

    if in(1, hydrogen_settings["CO2Policy"])
        if haskey(hydrogen_inputs, "Emission_Max_Mtons")
            hydrogen_inputs["dfEmi"][!, :Emission_Max_Mtons] .=
                hydrogen_inputs["Emission_Max_Mtons"]
            print_and_log(
                hydrogen_settings,
                "i",
                "Replace the Hydrogen Emission Max Cap with $(hydrogen_inputs["Emission_Max_Mtons"]) Mtons",
            )
        end
    end
    if in(2, hydrogen_settings["CO2Policy"]) || in(3, hydrogen_settings["CO2Policy"])
        hydrogen_inputs["dfEmi"][!, :Emission_Max_Tons_tonne] .= modification["Emission_Max_Rate"]
        if in(2, hydrogen_settings["CO2Policy"])
            print_and_log(
                hydrogen_settings,
                "i",
                "Replace the Hydrogen Emission Max Load Rate with $(modification["Emission_Max_Rate"]) kg/kg",
            )
        elseif in(3, hydrogen_settings["CO2Policy"])
            print_and_log(
                hydrogen_settings,
                "i",
                "Replace the Hydrogen Emission Max Generation Rate with $(modification["Emission_Max_Rate"]) kg/kg",
            )
        end
    end
    if in(4, hydrogen_settings["CO2Policy"])
        hydrogen_inputs["dfEmi"][!, :Emission_Price_tonne] .= modification["Emission_Price_tonne"]
        print_and_log(
            hydrogen_settings,
            "i",
            "Replace the Hydrogen Emission Price with $(modification["Emission_Price_tonne"])",
        )
    end

    return hydrogen_inputs
end
