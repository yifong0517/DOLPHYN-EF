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
	configure_solver(settings::Dict)

This method returns a solver-specific MathOptInterface OptimizerWithAttributes optimizer instance to be used in the generate() method.

The argument 'settings' is a dictionary which contains the default solver settings store path and solver name.
"""
function configure_solver(settings::Dict)

    print_and_log(settings, "i", "Configuring Solvers")

    solver_settings_path = joinpath(settings["SolverPath"], "Solvers")

    solver = lowercase(settings["Solver"])

    # Solvers full name
    solvers = Dict(
        "highs" => "HiGHS",
        "gurobi" => "Gurobi",
        "cplex" => "CPLEX",
        "copt" => "COPT",
        "clp" => "Clp",
        "cbc" => "Cbc",
    )

    print_and_log(settings, "i", "Using Solver $(solvers[solver])")

    SolverUserSettings = settings["SolverUserSettings"]

    if solver == "highs"
        # Set solver as HiGHS
        highs_settings_path = joinpath(solver_settings_path, "highs_settings.yml")
        OPTIMIZER = configure_highs(highs_settings_path, SolverUserSettings)
    elseif solver == "gurobi"
        # Set solver as Gurobi
        gurobi_settings_path = joinpath(solver_settings_path, "gurobi_settings.yml")
        OPTIMIZER = configure_gurobi(gurobi_settings_path, SolverUserSettings)
    elseif solver == "cplex"
        # Set solver as CPLEX
        cplex_settings_path = joinpath(solver_settings_path, "cplex_settings.yml")
        OPTIMIZER = configure_cplex(cplex_settings_path, SolverUserSettings)
    elseif solver == "copt"
        # Set solver as COPT
        copt_settings_path = joinpath(solver_settings_path, "copt_settings.yml")
        OPTIMIZER = configure_copt(copt_settings_path, SolverUserSettings)
    elseif solver == "clp"
        # Set solver as Clp
        clp_settings_path = joinpath(solver_settings_path, "clp_settings.yml")
        OPTIMIZER = configure_clp(clp_settings_path, SolverUserSettings)
    elseif solver == "cbc"
        # Set solver as Cbc
        cbc_settings_path = joinpath(solver_settings_path, "cbc_settings.yml")
        OPTIMIZER = configure_cbc(cbc_settings_path, SolverUserSettings)
    end

    return OPTIMIZER
end
