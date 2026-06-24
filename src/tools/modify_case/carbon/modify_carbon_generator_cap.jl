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
function modify_carbon_generator_cap(carbon_settings::Dict, carbon_inputs::Dict)

    CaptureExpansion = carbon_settings["CaptureExpansion"]

    G = carbon_inputs["G"]
    dfGen = carbon_inputs["dfGen"]

    if CaptureExpansion == -1
        carbon_inputs["NEW_CAPTURE_CAP"] = Int64[]
    elseif CaptureExpansion == 0
        carbon_inputs["NEW_CAPTURE_CAP"] = dfGen[dfGen.New_Build .== 1, :R_ID]
    elseif CaptureExpansion == 1
        carbon_inputs["NEW_CAPTURE_CAP"] = 1:G
    end
    carbon_inputs["NEW_CAPTURE_CAP"] = intersect(
        carbon_inputs["NEW_CAPTURE_CAP"],
        union(
            dfGen[dfGen.Max_Cap_tonne_per_hr .== -1, :R_ID],
            intersect(
                dfGen[dfGen.Max_Cap_tonne_per_hr .!= -1, :R_ID],
                dfGen[dfGen.Max_Cap_tonne_per_hr .- dfGen.Existing_Cap_tonne_per_hr .> 0, :R_ID],
            ),
        ),
    )
    ## Set of all resources eligible for capacity retirements
    carbon_inputs["RET_CAPTURE_CAP"] = intersect(
        dfGen[dfGen.Retirement .== 1, :R_ID],
        dfGen[dfGen.Existing_Cap_tonne_per_hr .> 0, :R_ID],
    )

    return carbon_inputs
end
