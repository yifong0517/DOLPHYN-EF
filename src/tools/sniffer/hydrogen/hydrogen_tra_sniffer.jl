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
function hydrogen_tra_sniffer(settings::Dict, inputs::Dict, MESS::Model, sniffer::AbstractDict)

    print_and_log(settings, "i", "Start Sniffing Hydrogen Sector Transport")

    ## Hydrogen sector inputs
    hydrogen_inputs = inputs["HydrogenInputs"]
    dfPipe = hydrogen_inputs["dfPipe"]
    P = hydrogen_inputs["P"]

    ## Hydrogen sector transmission capacity sniffer
    existing_tra_cap = sum(dfPipe[!, :Existing_Pipe_Number])
    mapping_tra_cap = sum(value.(MESS[:eHPipeCap]))
    maximum_tra_cap =
        sum(dfPipe[!, :Max_Pipe_Number][dfPipe[dfPipe.Max_Pipe_Number .!= -1, :P_ID]]; init = 0.0)

    ## Hydrogen sector transmission sniffer
    transmission = sum(value.(MESS[:eHTransmission]))

    sniffer = merge(
        sniffer,
        Dict(
            "H_Existing_Tra_Cap" => existing_tra_cap,
            "H_Mapping_Tra_Cap" => mapping_tra_cap,
            "H_Maximum_Tra_Cap" => maximum_tra_cap,
            "H_Transmission" => transmission,
        ),
    )

    return sniffer
end
