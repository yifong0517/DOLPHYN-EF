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
	configure_clp(solver_settings_path::String, solver_user_settings::Union{Dict, Nothing} = nothing)

Reads user-specified solver settings from clp\_settings.yml in the directory specified by the string solver\_settings\_path.
solver_user_settings is a user-defined dictionary containing some settings that could be altered by user.

Returns a MathOptInterface OptimizerWithAttributes Clp optimizer instance to be used in the generate() method.

The Clp optimizer instance is configured with the following default parameters if a user-specified parameter for each respective field is not provided:

 - PrimalTolerance = 1e-7 (Primal feasibility tolerance)
 - DualTolerance = 1e-7 (Dual feasibility tolerance)
 - DualObjectiveLimit = 1e308 (When using dual simplex (where the objective is monotonically changing), terminate when the objective exceeds this limit)
 - MaximumIterations = 2147483647 (Terminate after performing this number of simplex iterations)
 - MaximumSeconds = -1.0	(Terminate after this many seconds have passed. A negative value means no time limit)
 - LogLevel = 1 (Set to 1, 2, 3, or 4 for increasing output. Set to 0 to disable output)
 - PresolveType = 0 (Set to 1 to disable presolve)
 - SolveType = 5 (Solution method: dual simplex (0), primal simplex (1), sprint (2), barrier with crossover (3), barrier without crossover (4), automatic (5))
 - InfeasibleReturn = 0 (Set to 1 to return as soon as the problem is found to be infeasible (by default, an infeasibility proof is computed as well))
 - Scaling = 3 (0 0ff, 1 equilibrium, 2 geometric, 3 auto, 4 dynamic (later))
 - Perturbation = 100 (switch on perturbation (50), automatic (100), don't try perturbing (102))

"""
function configure_clp(
    solver_settings_path::String,
    solver_user_settings::Union{Dict, Nothing} = nothing,
)

    solver_settings = YAML.load(open(solver_settings_path))

    ## Optional solver parameters ############################################
    MyDualObjectiveLimit = 1e100
    if (haskey(solver_settings, "DualObjectiveLimit"))
        MyDualObjectiveLimit = solver_settings["DualObjectiveLimit"]
    end
    MyPrimalTolerance = 1e-7#Primal feasibility tolerance
    if (haskey(solver_settings, "Feasib_Tol"))
        MyPrimalTolerance = solver_settings["Feasib_Tol"]
    end
    MyDualTolerance = 1e-7#Dual feasibility tolerance
    if (haskey(solver_settings, "Feasib_Tol "))
        MyDualTolerance = solver_settings["Feasib_Tol"]
    end
    MyDualObjectiveLimit = 1e308#When using dual simplex (where the objective is monotonically changing), terminate when the objective exceeds this limit
    if (haskey(solver_settings, "DualObjectiveLimit"))
        MyDualObjectiveLimit = solver_settings["DualObjectiveLimit"]
    end
    MyMaximumIterations = 2147483647#Terminate after performing this number of simplex iterations
    if (haskey(solver_settings, "MaximumIterations"))
        MyMaximumIterations = solver_settings["MaximumIterations"]
    end
    MyMaximumSeconds = -1.0#Terminate after this many seconds have passed. A negative value means no time limit
    if (haskey(solver_settings, "TimeLimit"))
        MyMaximumSeconds = solver_settings["TimeLimit"]
    end
    MyLogLevel = 1#Set to 1, 2, 3, or 4 for increasing output. Set to 0 to disable output
    if (haskey(solver_settings, "LogLevel"))
        MyLogLevel = solver_settings["LogLevel"]
    end
    MyPresolveType = 0#Set to 1 to disable presolve
    if (haskey(solver_settings, "Pre_Solve"))
        MyPresolveType = solver_settings["Pre_Solve"]
    end
    MySolveType = 5#Solution method: dual simplex (0), primal simplex (1), sprint (2), barrier with crossover (3), barrier without crossover (4), automatic (5)
    if (haskey(solver_settings, "Method"))
        MySolveType = solver_settings["Method"]
    end
    MyInfeasibleReturn = 0#Set to 1 to return as soon as the problem is found to be infeasible (by default, an infeasibility proof is computed as well)
    if (haskey(solver_settings, "InfeasibleReturn"))
        MyInfeasibleReturn = solver_settings["InfeasibleReturn"]
    end
    MyScaling = 3#0 -off, 1 equilibrium, 2 geometric, 3 auto, 4 dynamic(later)
    if (haskey(solver_settings, "Scaling"))
        MyScaling = solver_settings["Scaling"]
    end
    MyPerturbation = 100#switch on perturbation (50), automatic (100), don't try perturbing (102)
    if (haskey(solver_settings, "Perturbation"))
        MyPerturbation = solver_settings["Perturbation"]
    end
    ########################################################################

    ## User modified solver settings #######################################
    if haskey(solver_user_settings, "TimeLimit")
        MyMaximumSeconds = solver_user_settings["TimeLimit"]
    end
    ########################################################################

    OPTIMIZER = optimizer_with_attributes(
        Clp.Optimizer,
        "PrimalTolerance" => MyPrimalTolerance,
        "DualTolerance" => MyDualTolerance,
        "DualObjectiveLimit" => MyDualObjectiveLimit,
        "MaximumIterations" => MyMaximumIterations,
        "MaximumSeconds" => MyMaximumSeconds,
        "LogLevel" => MyLogLevel,
        "PresolveType" => MyPresolveType,
        "SolveType" => MySolveType,
        "InfeasibleReturn" => MyInfeasibleReturn,
        "Scaling" => MyScaling,
        "Perturbation" => MyPerturbation,
    )

    return OPTIMIZER
end
