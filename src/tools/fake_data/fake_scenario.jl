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
    fake_scenario(path::AbstractString, scenario::AbstractString)

This function loads a YAML file from the given path and printing out a fake scenario.
"""
function fake_scenario(path::AbstractString, scenario::AbstractString)

    ## Check whether the path exists
    if !isdir(path)
        mkdir(path)
    end

    ## Expand scenario path
    scenario_path = expanduser(scenario)
    Scenario = YAML.load(open(scenario_path))

    ## Create scenario folder
    path = joinpath(path, Scenario["scenario"])
    if !isdir(path)
        mkdir(path)
    end
    println("Fake scenario: $(Scenario["scenario"]) in $path")

    fake_data(path, Scenario)

    fake_modifications(path)

    println("Fake scenario: $(Scenario["scenario"]) finished!")
end
