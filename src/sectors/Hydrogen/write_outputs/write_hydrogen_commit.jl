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
function write_hydrogen_commit(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        hydrogen_settings = settings["HydrogenSettings"]
        path = hydrogen_settings["SavePath"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        tsymbols = [Symbol("$t") for t in 1:T]

        hydrogen_inputs = inputs["HydrogenInputs"]

        dfGen = hydrogen_inputs["dfGen"]

        RESOURCES = hydrogen_inputs["GenResources"]
        COMMIT = hydrogen_inputs["COMMIT"]

        ## Commitment state for each resource in each time step
        dfCommit = DataFrame(
            Resource = string.(RESOURCES[COMMIT]),
            Zone = string.(dfGen[!, :Zone][COMMIT]),
        )
        dfCommit =
            hcat(dfCommit, DataFrame(round.(value.(MESS[:vHOnline]).data; digits = 2), :auto))

        auxNew_Names = [Symbol("Resource"); Symbol("Zone"); tsymbols]
        rename!(dfCommit, auxNew_Names)

        ## CSV writing
        CSV.write(
            joinpath(path, "commit.csv"),
            permutedims(dfCommit, "Resource", makeunique = true),
        )

        ## Shutdown state for each resource in each time step
        dfShutdown = DataFrame(
            Resource = string.(RESOURCES[COMMIT]),
            Zone = string.(dfGen[!, :Zone][COMMIT]),
        )
        dfShutdown =
            hcat(dfShutdown, DataFrame(round.(value.(MESS[:vHShut]).data; digits = 2), :auto))

        auxNew_Names = [Symbol("Resource"); Symbol("Zone"); tsymbols]
        rename!(dfShutdown, auxNew_Names)

        ## CSV writing
        CSV.write(
            joinpath(path, "shutdown.csv"),
            permutedims(dfShutdown, "Resource", makeunique = true),
        )

        ## Startup state for each resource in each time step
        dfStart = DataFrame(
            Resource = string.(RESOURCES[COMMIT]),
            Zone = string.(dfGen[!, :Zone][COMMIT]),
        )
        dfStart = hcat(dfStart, DataFrame(round.(value.(MESS[:vHStart]).data; digits = 2), :auto))

        auxNew_Names = [Symbol("Resource"); Symbol("Zone"); tsymbols]
        rename!(dfStart, auxNew_Names)

        ## CSV writing
        CSV.write(joinpath(path, "start.csv"), permutedims(dfStart, "Resource", makeunique = true))
    end
end
