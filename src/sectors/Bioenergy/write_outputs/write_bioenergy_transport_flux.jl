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
function write_bioenergy_transport_flux(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        bioenergy_settings = settings["BioenergySettings"]
        save_path = bioenergy_settings["SavePath"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        bioenergy_inputs = inputs["BioenergyInputs"]
        dfRoute = bioenergy_inputs["dfRoute"]

        R = bioenergy_inputs["R"]
        Residuals = bioenergy_inputs["Residuals"]

        ## Residuals transport flux
        dfFlux = DataFrame(Time = tsymbols)
        temp = round.(value.(MESS[:vBResidualFlux]); digits = 2)
        for r in 1:R
            for rs in eachindex(Residuals)
                dfFlux[!, Symbol(dfRoute[!, "-1"][r], " ", Residuals[rs])] = temp[r, rs, -1, :].data
                dfFlux[!, Symbol(dfRoute[!, "1"][r], " ", Residuals[rs])] = temp[r, rs, 1, :].data
            end
        end

        ## Add total flux
        total = Any[Symbol("Sum")]
        for r in 1:R
            for rs in eachindex(Residuals)
                push!(
                    total,
                    round(
                        sum(weights .* dfFlux[!, Symbol(dfRoute[!, "-1"][r], " ", Residuals[rs])]);
                        digits = 2,
                    ),
                )
                push!(
                    total,
                    round(
                        sum(weights .* dfFlux[!, Symbol(dfRoute[!, "1"][r], " ", Residuals[rs])]);
                        digits = 2,
                    ),
                )
            end
        end

        pushfirst!(dfFlux, total)

        CSV.write(joinpath(save_path, "bioenergy_residuals_flux.csv"), dfFlux)
    end
end
