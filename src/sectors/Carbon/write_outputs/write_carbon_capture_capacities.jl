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
function write_carbon_capture_capacities(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        carbon_settings = settings["CarbonSettings"]
        path = carbon_settings["SavePath"]

        carbon_inputs = inputs["CarbonInputs"]

        ## Capture capacities
        dfGen = carbon_inputs["dfGen"]

        NEW_CAPTURE_CAP = carbon_inputs["NEW_CAPTURE_CAP"]
        RET_CAPTURE_CAP = carbon_inputs["RET_CAPTURE_CAP"]

        COMMIT = carbon_inputs["COMMIT"]

        RESOURCES = carbon_inputs["GenResources"]

        ## New generation capacities
        newcapdischarge = zeros(size(RESOURCES))
        temp = value.(MESS[:vCNewCaptureCap])
        for i in NEW_CAPTURE_CAP
            if i in COMMIT
                newcapdischarge[i] = temp[i] * dfGen[!, :Cap_Size_tonne_per_hr][i]
            else
                newcapdischarge[i] = temp[i]
            end
        end

        ## Retired generation capacities
        retcapdischarge = zeros(size(RESOURCES))
        temp = value.(MESS[:vCRetCaptureCap])
        for i in RET_CAPTURE_CAP
            if i in COMMIT
                retcapdischarge[i] = temp[i] * dfGen[!, :Cap_Size_tonne_per_hr][i]
            else
                retcapdischarge[i] = temp[i]
            end
        end

        ## Generation capacities dataframe
        dfCap = DataFrame(
            Resource = string.(RESOURCES),
            ResourceType = string.(dfGen[!, :Resource_Type]),
            Zone = string.(dfGen[!, :Zone]),
            StartGenCap = round.(dfGen[!, :Existing_Cap_tonne_per_hr]; digits = 2),
            RetGenCap = round.(retcapdischarge[:]; digits = 2),
            NewGenCap = round.(newcapdischarge[:]; digits = 2),
            EndGenCap = round.(value.(MESS[:eCCaptureCap]); digits = 2),
        )

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(dfCap, settings["DB"], "CGenerator")
        end

        ## Total generation capacities
        total = DataFrame(
            Resource = "Sum",
            ResourceType = "Sum",
            Zone = "Sum",
            StartGenCap = round(sum(dfCap[!, :StartGenCap]); digits = 2),
            RetGenCap = round(sum(dfCap[!, :RetGenCap]); digits = 2),
            NewGenCap = round(sum(dfCap[!, :NewGenCap]); digits = 2),
            EndGenCap = round(sum(dfCap[!, :EndGenCap]); digits = 2),
        )

        ## Merge total dataframe for csv results
        dfCap = vcat(dfCap, total)

        ## CSV writing
        CSV.write(joinpath(path, "capacities_capture.csv"), dfCap)
    end
end
