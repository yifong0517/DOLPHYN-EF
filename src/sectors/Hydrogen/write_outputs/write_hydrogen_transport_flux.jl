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
function write_hydrogen_transport_flux(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        hydrogen_settings = settings["HydrogenSettings"]
        path = hydrogen_settings["SavePath"]

        T = inputs["T"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        hydrogen_inputs = inputs["HydrogenInputs"]
        dfRoute = hydrogen_inputs["dfRoute"]

        R = hydrogen_inputs["R"]

        ## Hydrogen transport flux
        dfFlux = DataFrame(Time = tsymbols)
        temp = round.(value.(MESS[:vHTransportFlux]); digits = 2)
        for r in 1:R
            dfFlux[!, Symbol(dfRoute[!, "-1"][r])] = temp[r, -1, :].data
            dfFlux[!, Symbol(dfRoute[!, "1"][r])] = temp[r, 1, :].data
        end

        ## Add total flow
        total = Any[Symbol("Total")]
        for r in 1:R
            push!(total, round(sum(weights .* dfFlux[!, Symbol(dfRoute[!, "-1"][r])]); digits = 2))
            push!(total, round(sum(weights .* dfFlux[!, Symbol(dfRoute[!, "1"][r])]); digits = 2))
        end

        pushfirst!(dfFlux, total)

        CSV.write(joinpath(path, "hydrogen_transport_flux.csv"), dfFlux)
    end
end
