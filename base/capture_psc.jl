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
function capture_psc(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Point Source Carbon Capture Core Module")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    ## Point source capture
    @expression(MESS, eCapturePointSource[z = 1:Z, t = 1:T], AffExpr(0))

    ## Point source capture in power sector
    if settings["ModelPower"] == 1
        power_inputs = inputs["PowerInputs"]
        CCS = power_inputs["CCS"]
        if !isempty(CCS)
            add_to_expression!.(MESS[:eCapturePointSource], MESS[:ePCapture])
        end
    end

    ## Point source capture in hydrogen sector
    if settings["ModelHydrogen"] == 1
        hydrogen_inputs = inputs["HydrogenInputs"]
        CCS = hydrogen_inputs["CCS"]
        if !isempty(CCS)
            add_to_expression!.(MESS[:eCapturePointSource], MESS[:eHCapture])
        end
    end

    ## Point source capture in synfuels sector
    if settings["ModelSynfuels"] == 1
        synfuels_inputs = inputs["SynfuelsInputs"]
        CCS = synfuels_inputs["CCS"]
        if !isempty(CCS)
            add_to_expression!.(MESS[:eCapturePointSource], MESS[:eSCapture])
        end
    end

    ## Point source capture in ammonia sector
    if settings["ModelAmmonia"] == 1
        ammonia_inputs = inputs["AmmoniaInputs"]
        CCS = ammonia_inputs["CCS"]
        if !isempty(CCS)
            add_to_expression!.(MESS[:eCapturePointSource], MESS[:eACapture])
        end
    end

    ## Handle point source capture in carbon capture module
    if settings["ModelCarbon"] == 1 && !(settings["CarbonSettings"]["DACOnly"] == 1)
        add_to_expression!.(MESS[:eCBalance], MESS[:eCapturePointSource])
    end

    return MESS
end
