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
    fake_scenario(
        path::AbstractString,
        Scenario::Dict{Any, Any} = Dict(
            "RootPath" => "benchmark",
            "SavePath" => "Results",
            "TimeMode" => "FTBM",
            "TotalTime" => 8760,
            "ModelMode" => "DD",
            "ModelPower" => true,
            "ModelHydrogen" => true,
            "ModelCarbon" => true,
            "ModelSynfuels" => true,
            "ModelBioenergy" => true,
            "ModelFoodstuff" => true,
            "OverWrite" => false,
            "CO2Policy" => [0],
            "CO2Disposal" => 0,
            "ModelFile" => "",
            "DBFile" => "",
            "LogFile" => "log.txt",
            "Silent" => false,
        )
    )

This function loads a scenario settings to generate multi modifications.
"""
function fake_modifications(
    path::AbstractString,
    Scenario::Dict{String, Any} = Dict(
        "RootPath" => "benchmark",
        "SavePath" => "Results",
        "TimeMode" => "FTBM",
        "TotalTime" => 8760,
        "ModelMode" => "DD",
        "ModelPower" => true,
        "ModelHydrogen" => true,
        "ModelCarbon" => true,
        "ModelSynfuels" => true,
        "ModelAmmonia" => true,
        "ModelBioenergy" => true,
        "ModelFoodstuff" => true,
        "OverWrite" => false,
        "CO2Policy" => [0],
        "CO2Disposal" => 0,
        "" => "",
        "DBFile" => "",
        "LogFile" => "log.txt",
        "Silent" => false,
    ),
)

    modifications = DataFrame(Scenario)

    modifications[!, :SubCase] = [1]

    CSV.write(joinpath(path, "Modifications.csv"), modifications)

    return modifications
end
