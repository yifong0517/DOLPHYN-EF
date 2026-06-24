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
function storage_investment(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Storage Investment Module")

    power_inputs = inputs["PowerInputs"]

    dfSto = power_inputs["dfSto"]

    S = power_inputs["S"]

    STO_ASYMMETRIC = power_inputs["STO_ASYMMETRIC"]

    ## Power sector storage energy investment
    MESS = storage_investment_energy(settings, inputs, MESS)

    ## Power sector storage discharge investment
    MESS = storage_investment_discharge(settings, inputs, MESS)

    ## Power sector storage charge investment
    if !isempty(STO_ASYMMETRIC)
        MESS = storage_investment_charge(settings, inputs, MESS)
    end

    ### Constraints ###
    ## Max and min constraints on energy storage capacity built (as proportion to discharge power capacity)
    @constraints(
        MESS,
        begin
            cPStoMinDuration[s in intersect(1:S, dfSto[dfSto.Min_Duration .> 0, :R_ID])],
            MESS[:ePStoEneCap][s] >= dfSto[!, :Min_Duration][s] * MESS[:ePStoDisCap][s]
            cPStoMaxDuration[s in intersect(1:S, dfSto[dfSto.Max_Duration .> 0, :R_ID])],
            MESS[:ePStoEneCap][s] <= dfSto[!, :Max_Duration][s] * MESS[:ePStoDisCap][s]
        end
    )
    ### End Constraints ###

    return MESS
end
