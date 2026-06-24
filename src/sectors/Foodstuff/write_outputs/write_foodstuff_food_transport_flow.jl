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

@doc """
"""

function write_foodstuff_food_transport_flow(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        foodstuff_settings = settings["FoodstuffSettings"]
        save_path = foodstuff_settings["SavePath"]

        T = inputs["T"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        foodstuff_inputs = inputs["FoodstuffInputs"]
        TRANSPORT_ZONES = foodstuff_inputs["TRANSPORT_ZONES"]
        Foods = foodstuff_inputs["Foods"]

        ## Shipping methanol flow
        dfFlow = DataFrame(Time = tsymbols)
        temp = round.(value.(MESS[:vFBalanceFoodFlow]); digits = 2)
        for z in TRANSPORT_ZONES
            for fs in eachindex(Foods)
                dfFlow[!, Symbol("$(z)_$(Foods[fs])")] = temp[z, fs, :].data
            end
        end

        ## Add total flow
        total = Any[Symbol("Total")]
        for z in TRANSPORT_ZONES
            for fs in eachindex(Foods)
                push!(
                    total,
                    round(sum(weights .* dfFlow[!, Symbol("$(z)_$(Foods[fs])")]); digits = 2),
                )
            end
        end

        pushfirst!(dfFlow, total)

        CSV.write(joinpath(save_path, "foodstuff_food_transport_flow.csv"), dfFlow)
    end
end
