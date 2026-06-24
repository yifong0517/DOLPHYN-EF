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
function dynamic_sniffers(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Initializing Dynamic Sniffers for Results Recording and Analysis")

    ## Initialize sniffer with basic temporal and spatial information
    sniffer = OrderedDict{Any, Any}(
        "TotalTime" => inputs["T"],
        "TimeMode" => inputs["TimeMode"],
        "Period" => inputs["Period"],
        "TimeStep" => "hour",
        "TotalZone" => inputs["Z"],
    )

    ## System sniffer
    sniffer = system_sniffer(settings, sniffer)

    ## Settings sniffer
    sniffer = settings_sniffer(settings, sniffer)

    ## Sectorial sniffer
    sniffer = sector_sniffer(settings, inputs, MESS, sniffer)

    return sniffer
end
