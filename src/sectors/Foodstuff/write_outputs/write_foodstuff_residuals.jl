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
function write_foodstuff_residuals(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        foodstuff_settings = settings["FoodstuffSettings"]
        path = foodstuff_settings["SavePath"]

        Zones = inputs["Zones"]

        foodstuff_inputs = inputs["FoodstuffInputs"]
        Straws = foodstuff_inputs["Straws"]
        Residuals = foodstuff_inputs["Agriculture_Production_Residuals"]

        dfResiduals = DataFrame(Zone = Zones)
        ## Write zonal straw residuals production
        temp = value.(MESS[:eFCropCollectedStrawZonal])
        dfResiduals = hcat(
            dfResiduals,
            DataFrame(
                Dict(Straws[ss] => round.(temp[:, ss]; sigdigits = 4) for ss in eachindex(Straws)),
            ),
        )
        ## Write zonal residuals production
        temp = value.(MESS[:eFFoodResidualsProductionZonal])
        dfResiduals = hcat(
            dfResiduals,
            DataFrame(
                Dict(
                    Residuals[rs] => round.(temp[:, rs]; sigdigits = 4) for
                    rs in eachindex(Residuals)
                ),
            ),
        )

        CSV.write(joinpath(path, "foodstuff_residuals.csv"), dfResiduals)
    end
end
