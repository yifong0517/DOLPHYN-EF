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
function ammonia_sto_sniffer(settings::Dict, inputs::Dict, MESS::Model, sniffer::AbstractDict)

    print_and_log(settings, "i", "Start Sniffing Ammonia Sector Storage")

    ## Ammonia sector inputs
    ammonia_inputs = inputs["AmmoniaInputs"]
    dfSto = ammonia_inputs["dfSto"]
    S = ammonia_inputs["S"]

    ## Ammonia sector storage capacity sniffer
    existing_sto_ene_cap = sum(dfSto[!, :Existing_Ene_Cap_tonne])
    mapping_sto_ene_cap = sum(value.(MESS[:eAStoEneCap]))
    maximum_sto_ene_cap =
        sum(dfSto[!, :Max_Ene_Cap_tonne][dfSto[dfSto.Max_Ene_Cap_tonne .!= -1, :R_ID]]; init = 0.0)

    mapping_sto_dis_cap = sum(value.(MESS[:eAStoDisCap]))
    mapping_sto_cha_cap = sum(value.(MESS[:eAStoChaCap]))

    sto_duration =
        mapping_sto_dis_cap > 0.0 ?
        round(mapping_sto_ene_cap / mapping_sto_dis_cap; sigdigits = 2) : -1

    sto_throughout = round(sum(value.(MESS[:vAStoDis]) + value.(MESS[:vAStoCha])); sigdigits = 2)
    sto_cycles = round(sto_throughout / mapping_sto_ene_cap; sigdigits = 2)

    sniffer = merge(
        sniffer,
        Dict(
            "S_Existing_Sto_Ene_Cap" => existing_sto_ene_cap,
            "S_Mapping_Sto_Ene_Cap" => mapping_sto_ene_cap,
            "S_Maximum_Sto_Ene_Cap" => maximum_sto_ene_cap,
            "S_Mapping_Sto_Dis_Cap" => mapping_sto_dis_cap,
            "S_Mapping_Sto_Cha_Cap" => mapping_sto_cha_cap,
            "S_Sto_Duration" => sto_duration,
            "S_Sto_Throughout" => sto_throughout,
            "S_Sto_Cycles" => sto_cycles,
        ),
    )

    return sniffer
end
