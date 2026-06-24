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
function run_stochastic_cases(
    configurations_path::AbstractString,
    settings_path::AbstractString,
    summary_path::AbstractString = "summary.csv",
)

    ## Initialize the timer
    to = TimerOutput()

    ## Load modification seed
    seeds = YAML.load_file(configurations_path, dicttype = OrderedDict)

    ## Generate modifications csv
    @timeit to "Generating Modifications" generate_modifications(seeds)

    modifications = load_modifications(joinpath(pwd(), seeds["FileName"]))

    summary = DataFrame(SubCase = eachindex(modifications), Cost = 0.0)

    for modification_number in eachindex(modifications)
        ## Load settings
        settings = @timeit to "Loading Settings" load_settings_with_modifications(
            settings_path,
            modifications,
            modification_number,
        )

        ## Configure solver
        OPTIMIZER = @timeit to "Configuring Solvers" configure_solver(settings)

        ## Load inputs
        inputs = @timeit to "Loading Inputs" load_inputs(settings)

        ## Generate model
        Model = @timeit to "Generating Model" generate(settings, inputs, OPTIMIZER)

        ## Solve model
        Model = @timeit to "Solving Model" solve(settings, Model)

        ## Write outputs
        outputs = @timeit to "Writing Outputs" write_outputs(settings, inputs, Model)

        summary[!, :Cost][modification_number] = outputs
    end

    if summary_path != ""
        CSV.write(summary_path, summary)
    end

    ## Show time
    show(to)

    ## Delete created csv
    rm(seeds["FileName"])

    return summary
end
