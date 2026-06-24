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
    run_mess_case(
        modifications_path::AbstractString = "",
        modification_number::Integer = 1;
        save_path::AbstractString = "",
        settings_path::AbstractString = "",
    )

This function accepts the same parameters as ```load_settings``` and will detect the current working directory for settings, inputs, and modifications if absent.
"""
function run_mess_case(
    modifications_path::AbstractString = "",
    modification_number::Integer = 1;
    save_path::AbstractString = "",
    settings_path::AbstractString = "",
)

    ## Initialize the timer
    to = TimerOutput()

    ## Load settings
    settings = @timeit to "Loading Settings" load_settings(
        modifications_path,
        modification_number;
        save_path = save_path,
        settings_path = settings_path,
    )
    if modifications_path == "" && settings_path == ""
        working_dir = pwd()
        settings["RootPath"] = working_dir
    end

    ## Configure solver
    OPTIMIZER = @timeit to "Configuring Solvers" configure_solver(settings)

    ## Load inputs
    inputs = @timeit to "Loading Inputs" load_inputs(settings)

    ## Generate model
    Model = @timeit to "Generating Model" generate(settings, inputs, OPTIMIZER)

    ## Solve model
    Model = @timeit to "Solving Model" solve(settings, Model)

    ## Write outputs and return total cost
    cost = @timeit to "Writing Outputs" write_outputs(settings, inputs, Model)

    print_and_log(settings, "i", "The Total Costs are $cost")

    showtime(settings, to)

    return cost
end
