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
function mga(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Modeling to Generate Alternative Module")

    path = settings["SavePath"]

    ## MGA settings
    slack = settings["MGASlack"]
    iteration = settings["MGAIteration"]

    ## Objective function value of the least cost problem
    optimal_objective_value = objective_value(MESS)

    ## Constraint for MGA problem objective slack
    @constraint(MESS, cMGAObj, MESS[:eObj] <= optimal_objective_value * (1 + slack))

    ## Auxiliary variables and constraints for sectors
    MESS = mga_variables(settings, inputs, MESS)

    ## MGA objective maximization
    for iter in 1:iteration
        solve_mga_max(settings, inputs, MESS, path, iter)
    end

    ## MGA objective minimization
    for iter in 1:iteration
        solve_mga_min(settings, inputs, MESS, path, iter)
    end
end
