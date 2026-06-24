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
	configure_cplex(solver_settings_path::String, solver_user_settings::Union{Dict, Nothing} = nothing)

Reads user-specified solver settings from cplex\_settings.yml in the directory specified by the string solver\_settings\_path.
solver_user_settings is a user-defined dictionary containing some settings that could be altered by user.

Returns a MathOptInterface OptimizerWithAttributes CPLEX optimizer instance to be used in the generate() method.

The CPLEX optimizer instance is configured with the following default parameters if a user-specified parameter for each respective field is not provided:

 - CPX\_PARAM\_EPRHS = 1e-6 (Constraint (primal) feasibility tolerances. See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/EpRHS.html)
 - CPX\_PARAM\_EPOPT = 1e-6 (Dual feasibility tolerances. See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/EpOpt.html)
 - CPX\_PARAM\_AGGFILL = 10 (Allowed fill during presolve aggregation. See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/AggFill.html)
 - CPX\_PARAM\_PREDUAL = 0 (Decides whether presolve should pass the primal or dual linear programming problem to the LP optimization algorithm. See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/PreDual.html)
 - CPX\_PARAM\_TILIM = 1e+75	(Limits total time solver. See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/TiLim.html)
 - CPX\_PARAM\_EPGAP = 1e-4	(Relative (p.u. of optimal) mixed integer optimality tolerance for MIP problems (ignored otherwise). See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/EpGap.html)
 - CPX\_PARAM\_LPMETHOD = 0 (Algorithm used to solve continuous models (including MIP root relaxation). See https://www.ibm.com/support/knowledgecenter/de/SSSA5P_12.7.0/ilog.odms.cplex.help/CPLEX/Parameters/topics/LPMETHOD.html)
 - CPX\_PARAM\_BAREPCOMP = 1e-8 (Barrier convergence tolerance (determines when barrier terminates). See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/BarEpComp.html)
 - CPX\_PARAM\_NUMERICALEMPHASIS = 0 (Numerical precision emphasis. See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/NumericalEmphasis.html)
 - CPX\_PARAM\_BAROBJRNG = 1e+75 (Sets the maximum absolute value of the objective function. See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/BarObjRng.html)
 - CPX\_PARAM\_SOLUTIONTYPE = 2 (Solution type for LP or QP. See https://www.ibm.com/support/knowledgecenter/hr/SSSA5P_12.8.0/ilog.odms.cplex.help/CPLEX/Parameters/topics/SolutionType.html)

"""
function configure_cplex(
    solver_settings_path::String,
    solver_user_settings::Union{Dict, Nothing} = nothing,
)

    solver_settings = YAML.load(open(solver_settings_path))

    ## Optional setup parameters ############################################
    MyFeasibilityTol = 1e-6 # Constraint (primal) feasibility tolerances. See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/EpRHS.html
    if (haskey(solver_settings, "Feasib_Tol"))
        MyFeasibilityTol = solver_settings["Feasib_Tol"]
    end
    MyOptimalityTol = 1e-4 # Dual feasibility tolerances. See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/EpOpt.html
    if (haskey(solver_settings, "Optimal_Tol"))
        MyOptimalityTol = solver_settings["Optimal_Tol"]
    end
    MyAggFill = 10 # Allowed fill during presolve aggregation. See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/AggFill.html
    if (haskey(solver_settings, "AggFill"))
        MyAggFill = solver_settings["AggFill"]
    end
    MyPreDual = 0# Decides whether presolve should pass the primal or dual linear programming problem to the LP optimization algorithm. See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/PreDual.html
    if (haskey(solver_settings, "PreDual"))
        MyPreDual = solver_settings["PreDual"]
    end
    MyTimeLimit = 1e+75# Limits total time solver. See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/TiLim.html
    if (haskey(solver_settings, "TimeLimit"))
        MyTimeLimit = solver_settings["TimeLimit"]
    end
    MyMIPGap = 1e-3# Relative (p.u. of optimal) mixed integer optimality tolerance for MIP problems (ignored otherwise). See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/EpGap.html
    if (haskey(solver_settings, "MIPGap"))
        MyMIPGap = solver_settings["MIPGap"]
    end
    MyMethod = 0# Algorithm used to solve continuous models (including MIP root relaxation). See https://www.ibm.com/support/knowledgecenter/de/SSSA5P_12.7.0/ilog.odms.cplex.help/CPLEX/Parameters/topics/LPMETHOD.html
    if (haskey(solver_settings, "Method"))
        MyMethod = solver_settings["Method"]
    end
    MyBarConvTol = 1e-8 # Barrier convergence tolerance (determines when barrier terminates). See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/BarEpComp.html
    if (haskey(solver_settings, "BarConvTol"))
        MyBarConvTol = solver_settings["BarConvTol"]
    end
    MyNumericFocus = 0 # Numerical precision emphasis. See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/NumericalEmphasis.html
    if (haskey(solver_settings, "NumericFocus"))
        MyNumericFocus = solver_settings["NumericFocus"]
    end
    MyBarObjRng = 1e+75 # Sets the maximum absolute value of the objective function. See https://www.ibm.com/support/knowledgecenter/en/SSSA5P_12.5.1/ilog.odms.cplex.help/CPLEX/Parameters/topics/BarObjRng.html
    if (haskey(solver_settings, "BarObjRng"))
        MyBarObjRng = solver_settings["BarObjRng"]
    end
    MySolutionType = 2 # Solution type for LP or QP. See https://www.ibm.com/support/knowledgecenter/hr/SSSA5P_12.8.0/ilog.odms.cplex.help/CPLEX/Parameters/topics/SolutionType.html
    if (haskey(solver_settings, "SolutionType"))
        MySolutionType = solver_settings["SolutionType"]
    end
    ########################################################################

    ## User modified solver settings #######################################
    if haskey(solver_user_settings, "TimeLimit")
        MyTimeLimit = solver_user_settings["TimeLimit"]
    end
    if haskey(solver_user_settings, "MipGap")
        MyMIPGap = solver_user_settings["MipGap"]
    end
    if haskey(solver_user_settings, "BarConvTol")
        MyBarConvTol = solver_user_settings["BarConvTol"]
    end
    ########################################################################

    OPTIMIZER = optimizer_with_attributes(
        CPLEX.Optimizer,
        "CPX_PARAM_EPRHS" => MyFeasibilityTol,
        "CPX_PARAM_EPOPT" => MyOptimalityTol,
        "CPX_PARAM_AGGFILL" => MyAggFill,
        "CPX_PARAM_PREDUAL" => MyPreDual,
        "CPX_PARAM_TILIM" => MyTimeLimit,
        "CPX_PARAM_EPGAP" => MyMIPGap,
        "CPX_PARAM_LPMETHOD" => MyMethod,
        "CPX_PARAM_BAREPCOMP" => MyBarConvTol,
        "CPX_PARAM_NUMERICALEMPHASIS" => MyNumericFocus,
        "CPX_PARAM_BAROBJRNG" => MyBarObjRng,
        "CPX_PARAM_SOLUTIONTYPE" => MySolutionType,
    )

    return OPTIMIZER
end
