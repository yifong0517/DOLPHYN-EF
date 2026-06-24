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
function hydrogen_gen_sniffer(settings::Dict, inputs::Dict, MESS::Model, sniffer::AbstractDict)

    print_and_log(settings, "i", "Start Sniffing Hydrogen Sector Generation")

    ## Hydrogen sector inputs
    hydrogen_inputs = inputs["HydrogenInputs"]
    dfGen = hydrogen_inputs["dfGen"]
    G = hydrogen_inputs["G"]

    ## Hydrogen sector generation capacity sniffer
    existing_gen_cap = sum(dfGen[!, :Existing_Cap_tonne_per_hr])
    mapping_gen_cap = sum(value.(MESS[:eHGenCap]))
    maximum_gen_cap = sum(
        dfGen[!, :Max_Cap_tonne_per_hr][dfGen[dfGen.Max_Cap_tonne_per_hr .!= -1, :R_ID]];
        init = 0.0,
    )
    gen_resource_adequacy =
        maximum_gen_cap > 0.0 ? round(mapping_gen_cap / maximum_gen_cap; digits = 4) : -1

    ## Hydrogen sector generation sniffer
    actual_generation = sum(value.(MESS[:vHGen]))
    available_generation = sum(value.(MESS[:eHGenCap] .* hydrogen_inputs["P_Max"]))
    gen_capacity_factor = actual_generation / available_generation

    sniffer = merge(
        sniffer,
        Dict(
            "H_Existing_Gen_Cap" => existing_gen_cap,
            "H_Mapping_Gen_Cap" => mapping_gen_cap,
            "H_Maximum_Gen_Cap" => maximum_gen_cap,
            "H_Gen_Resource_Adequacy" => gen_resource_adequacy,
            "H_Actual_Generation" => actual_generation,
            "H_Available_Generation" => available_generation,
            "H_Gen_Capacity_Factor" => gen_capacity_factor,
        ),
    )

    return sniffer
end
