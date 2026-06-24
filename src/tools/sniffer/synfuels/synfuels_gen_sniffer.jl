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
function synfuels_gen_sniffer(settings::Dict, inputs::Dict, MESS::Model, sniffer::AbstractDict)

    print_and_log(settings, "i", "Start Sniffing Synfuels Sector Generation")

    ## Synfuels sector inputs
    synfuels_inputs = inputs["SynfuelsInputs"]
    dfGen = synfuels_inputs["dfGen"]
    G = synfuels_inputs["G"]

    ## Synfuels sector generation capacity sniffer
    existing_gen_cap = sum(dfGen[!, :Existing_Cap_tonne_per_hr])
    mapping_gen_cap = sum(value.(MESS[:eSGenCap]))
    maximum_gen_cap = sum(
        dfGen[!, :Max_Cap_tonne_per_hr][dfGen[dfGen.Max_Cap_tonne_per_hr .!= -1, :R_ID]];
        init = 0.0,
    )
    gen_resource_adequacy =
        maximum_gen_cap > 0.0 ? round(mapping_gen_cap / maximum_gen_cap; digits = 4) : -1

    ## Synfuels sector generation sniffer
    actual_generation = sum(value.(MESS[:vSGen]))
    available_generation = sum(value.(MESS[:eSGenCap] .* synfuels_inputs["P_Max"]))
    gen_capacity_factor = actual_generation / available_generation

    sniffer = merge(
        sniffer,
        Dict(
            "S_Existing_Gen_Cap" => existing_gen_cap,
            "S_Mapping_Gen_Cap" => mapping_gen_cap,
            "S_Maximum_Gen_Cap" => maximum_gen_cap,
            "S_Gen_Resource_Adequacy" => gen_resource_adequacy,
            "S_Actual_Generation" => actual_generation,
            "S_Available_Generation" => available_generation,
            "S_Gen_Capacity_Factor" => gen_capacity_factor,
        ),
    )

    return sniffer
end
