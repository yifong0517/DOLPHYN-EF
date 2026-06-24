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
	configure_gurobi(solver_settings_path::String, solver_user_settings::Union{Dict, Nothing} = nothing)

Reads user-specified solver settings from gurobi\_settings.yml in the directory specified by the string solver\_settings\_path.
solver_user_settings is a user-defined dictionary containing some settings that could be altered by user.

Returns a MathOptInterface OptimizerWithAttributes Gurobi optimizer instance to be used in the generate() method.

The Gurobi optimizer instance is configured with the following default parameters if a user-specified parameter for each respective field is not provided:

 - FeasibilityTol = 1e-6 (Constraint (primal) feasibility tolerances. See https://www.gurobi.com/documentation/10.0/refman/feasibilitytol.html)
 - OptimalityTol = 1e-6 (Dual feasibility tolerances. See https://www.gurobi.com/documentation/10.0/refman/optimalitytol.html#parameter:OptimalityTol)
 - Presolve = -1 (Controls presolve level. See https://www.gurobi.com/documentation/10.0/refman/presolve.html)
 - AggFill = -1 (Allowed fill during presolve aggregation. See https://www.gurobi.com/documentation/10.0/refman/aggfill.html#parameter:AggFill)
 - PreDual = -1 (Presolve dualization. See https://www.gurobi.com/documentation/10.0/refman/predual.html#parameter:PreDual)
 - TimeLimit = Inf (Limits total time solver. See https://www.gurobi.com/documentation/10.0/refman/timelimit.html)
 - IterationLimit = 1e4 (Limits total MIP, barrier crossover, simplex iterations. See https://www.gurobi.com/documentation/10.0/refman/iterationlimit.html)
 - BarIterLimit = 1e4 (Limits barrier iterations. See https://www.gurobi.com/documentation/10.0/refman/bariterlimit.html)
 - MIPGap = 1e-4 (Relative (p.u. of optimal) mixed integer optimality tolerance for MIP problems (ignored otherwise). See https://www.gurobi.com/documentation/10.0/refman/mipgap2.html)
 - Crossover = -1 (Barrier crossver strategy. See https://www.gurobi.com/documentation/10.0/refman/crossover.html#parameter:Crossover)
 - Method = -1	(Algorithm used to solve continuous models (including MIP root relaxation). See https://www.gurobi.com/documentation/10.0/refman/method.html)
 - BarConvTol = 1e-8 (Barrier convergence tolerance (determines when barrier terminates). See https://www.gurobi.com/documentation/10.0/refman/barconvtol.html)
 - NumericFocus = 0 (Numerical precision emphasis. See https://www.gurobi.com/documentation/10.0/refman/numericfocus.html)
 - BarHomogeneous = -1 (Controls whether barrier algorithm uses homogeneous or inhomogeneous model. See https://www.gurobi.com/documentation/10.0/refman/barhomogeneous.html)
 - OutputFlag = 1 (Controls the output of log lines to the screen. See https://www.gurobi.com/documentation/10.0/refman/outputflag.html)
 - LogFile = "" (Name of the file to which Gurobi will send logging output. See https://www.gurobi.com/documentation/10.0/refman/logfile.html)
 - LogToConsole = 1 (Control console logging. See https://www.gurobi.com/documentation/10.0/refman/logtoconsole.html)
 - Threads = 0 (Number of threads to use for parallel computations. See https://www.gurobi.com/documentation/10.0/refman/threads.html)

"""
function configure_gurobi(
    solver_settings_path::String,
    solver_user_settings::Union{Dict, Nothing} = nothing,
)

    solver_settings = YAML.load(open(solver_settings_path))

    ## Optional solver parameters ############################################
    MyFeasibilityTol = 1e-6 # Constraint (primal) feasibility tolerances. See https://www.gurobi.com/documentation/10.0/refman/feasibilitytol.html
    if (haskey(solver_settings, "Feasib_Tol"))
        MyFeasibilityTol = solver_settings["Feasib_Tol"]
    end
    MyOptimalityTol = 1e-4 # Dual feasibility tolerances. See https://www.gurobi.com/documentation/10.0/refman/optimalitytol.html#parameter:OptimalityTol
    if (haskey(solver_settings, "Optimal_Tol"))
        MyOptimalityTol = solver_settings["Optimal_Tol"]
    end
    MyPresolve = -1 # Controls presolve level. See https://www.gurobi.com/documentation/10.0/refman/presolve.html
    if (haskey(solver_settings, "Presolve"))
        MyPresolve = solver_settings["Presolve"]
    end
    MyAggFill = -1 # Allowed fill during presolve aggregation. See https://www.gurobi.com/documentation/10.0/refman/aggfill.html#parameter:AggFill
    if (haskey(solver_settings, "AggFill"))
        MyAggFill = solver_settings["AggFill"]
    end
    MyPreDual = -1 # Presolve dualization. See https://www.gurobi.com/documentation/10.0/refman/predual.html#parameter:PreDual
    if (haskey(solver_settings, "PreDual"))
        MyPreDual = solver_settings["PreDual"]
    end
    MyTimeLimit = Inf # Limits total time solver. See https://www.gurobi.com/documentation/10.0/refman/timelimit.html
    if (haskey(solver_settings, "TimeLimit"))
        MyTimeLimit = solver_settings["TimeLimit"]
    end
    MyMIPGap = 1e-3 # Relative (p.u. of optimal) mixed integer optimality tolerance for MIP problems (ignored otherwise). See https://www.gurobi.com/documentation/10.0/refman/mipgap2.html
    if (haskey(solver_settings, "MIPGap"))
        MyMIPGap = solver_settings["MIPGap"]
    end
    MyCrossover = -1 # Barrier crossver strategy. See https://www.gurobi.com/documentation/10.0/refman/crossover.html#parameter:Crossover
    if (haskey(solver_settings, "Crossover"))
        MyCrossover = solver_settings["Crossover"]
    end
    MyMethod = -1 # Algorithm used to solve continuous models (including MIP root relaxation). See https://www.gurobi.com/documentation/10.0/refman/method.html
    if (haskey(solver_settings, "Method"))
        MyMethod = solver_settings["Method"]
    end
    MyBarConvTol = 1e-8 # Barrier convergence tolerance (determines when barrier terminates). See https://www.gurobi.com/documentation/10.0/refman/barconvtol.html
    if (haskey(solver_settings, "BarConvTol"))
        MyBarConvTol = solver_settings["BarConvTol"]
    end
    MyBarIterLimit = 1e4 # Limits barrier iterations. See https://www.gurobi.com/documentation/10.0/refman/bariterlimit.html
    if (haskey(solver_settings, "BarIterLimit"))
        MyBarIterLimit = solver_settings["BarIterLimit"]
    end
    MyNumericFocus = 0 # Numerical precision emphasis. See https://www.gurobi.com/documentation/10.0/refman/numericfocus.html
    if (haskey(solver_settings, "NumericFocus"))
        MyNumericFocus = solver_settings["NumericFocus"]
    end
    MyScaleFlag = -1 # Coefficient scaling. See https://www.gurobi.com/documentation/10.0/refman/scaleflag.html
    if (haskey(solver_settings, "MyScaleFlag"))
        MyScaleFlag = solver_settings["MyScaleFlag"]
    end
    MyBarHomogeneous = -1 # Controls whether barrier algorithm uses homogeneous or heterogeneous model. See https://www.gurobi.com/documentation/10.0/refman/barhomogeneous.html
    if (haskey(solver_settings, "BarHomogeneous"))
        MyBarHomogeneous = solver_settings["BarHomogeneous"]
    end
    MyOutputFlag = 1 # Controls Gurobi output. See https://www.gurobi.com/documentation/10.0/refman/numericfocus.html
    if (haskey(solver_settings, "OutputFlag"))
        MyOutputFlag = solver_settings["OutputFlag"]
    end
    MyLogFile = "" # Gurobi log file. See https://www.gurobi.com/documentation/10.0/refman/logfile.html#parameter:LogFile
    if (haskey(solver_settings, "LogFile"))
        MyLogFile = solver_settings["LogFile"]
    end
    MyLogToConsole = 1 # Control console logging. See https://www.gurobi.com/documentation/10.0/refman/logtoconsole.html
    if (haskey(solver_settings, "LogToConsole"))
        MyLogToConsole = solver_settings["LogToConsole"]
    end
    MyThreads = 0 # Number of threads to use for parallel computations. See https://www.gurobi.com/documentation/10.0/refman/threads.html
    if (haskey(solver_settings, "Threads"))
        MyThreads = solver_settings["Threads"]
    end
    ########################################################################

    ## User modified solver settings #######################################
    if haskey(solver_user_settings, "TimeLimit")
        MyTimeLimit = solver_user_settings["TimeLimit"]
    end
    if haskey(solver_user_settings, "MipGap")
        MyMIPGap = solver_user_settings["MipGap"]
    end
    if haskey(solver_user_settings, "CrossOver")
        MyCrossover = solver_user_settings["CrossOver"] == "on" ? 1 : 0
    end
    if haskey(solver_user_settings, "Method")
        MyMethod = solver_user_settings["Method"]
    end
    if haskey(solver_user_settings, "BarConvTol")
        MyBarConvTol = solver_user_settings["BarConvTol"]
    end
    if haskey(solver_user_settings, "BarIterLimit")
        MyBarIterLimit = solver_user_settings["BarIterLimit"]
    end
    if haskey(solver_user_settings, "BarHomogeneous")
        MyBarHomogeneous = solver_user_settings["BarHomogeneous"]
    end
    if (haskey(solver_user_settings, "MyScaleFlag"))
        MyScaleFlag = solver_user_settings["MyScaleFlag"]
    end
    if haskey(solver_user_settings, "Threads")
        MyThreads = solver_user_settings["Threads"]
    end
    if haskey(solver_user_settings, "Silent")
        MyLogToConsole = solver_user_settings["Silent"] == 1 ? 0 : 1
    end
    if solver_user_settings["SavePath"] != "" && MyLogFile != ""
        MyLogFile = joinpath(solver_user_settings["SavePath"], MyLogFile)
    else
        MyLogFile = ""
    end
    ########################################################################

    OPTIMIZER = optimizer_with_attributes(
        Gurobi.Optimizer,
        "OptimalityTol" => MyOptimalityTol,
        "FeasibilityTol" => MyFeasibilityTol,
        "Presolve" => MyPresolve,
        "AggFill" => MyAggFill,
        "PreDual" => MyPreDual,
        "TimeLimit" => MyTimeLimit,
        "BarIterLimit" => MyBarIterLimit,
        "MIPGap" => MyMIPGap,
        "Method" => MyMethod,
        "BarConvTol" => MyBarConvTol,
        "NumericFocus" => MyNumericFocus,
        "ScaleFlag" => MyScaleFlag,
        "Crossover" => MyCrossover,
        "BarHomogeneous" => MyBarHomogeneous,
        "OutputFlag" => MyOutputFlag,
        "LogFile" => MyLogFile,
        "LogToConsole" => MyLogToConsole,
        "Threads" => MyThreads,
    )

    return OPTIMIZER
end
