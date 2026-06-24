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
    configure_copt(solver_settings_path::String, solver_user_settings::Union{Dict, Nothing} = nothing)

Reads user-specified solver settings from copt\_settings.yml in the directory specified by the string solver\_settings\_path.
solver_user_settings is a user-defined dictionary containing some settings that could be altered by user.

Returns a MathOptInterface OptimizerWithAttributes COPT optimizer instance to be used in the generate() method.
"""
function configure_copt(
    solver_settings_path::String,
    solver_user_settings::Union{Dict, Nothing} = nothing,
)

    solver_settings = YAML.load(open(solver_settings_path))
    ## Optional solver parameters ############################################
    MyTimeLimit = 1e20 # Limits total time solver.
    if (haskey(solver_settings, "TimeLimit"))
        MyTimeLimit = solver_settings["TimeLimit"]
    end
    MySolTimeLimit = 1e20
    if (haskey(solver_settings, "SolTimeLimit"))
        MySolTimeLimit = solver_settings["SolTimeLimit"]
    end
    MyNodeLimit = -1
    if (haskey(solver_settings, "NodeLimit"))
        MyNodeLimit = Int(solver_settings["NodeLimit"])
    end
    MyBarIterLimit = 10000
    if (haskey(solver_settings, "BarIterLimit"))
        MyBarIterLimit = Int(solver_settings["BarIterLimit"])
    end
    MyMatrixTol = 1e-10
    if (haskey(solver_settings, "MatrixTol"))
        MyMatrixTol = Float64(solver_settings["MatrixTol"])
    end
    MyFeasTol = 1e-6
    if (haskey(solver_settings, "FeasTol"))
        MyFeasTol = Float64(solver_settings["FeasTol"])
    end
    MyDualTol = 1e-6
    if (haskey(solver_settings, "DualTol"))
        MyDualTol = Float64(solver_settings["DualTol"])
    end
    MyIntTol = 1e-6
    if (haskey(solver_settings, "IntTol"))
        MyIntTol = Float64(solver_settings["IntTol"])
    end
    MyRelGap = 1e-4
    if (haskey(solver_settings, "RelGap"))
        MyRelGap = Float64(solver_settings["RelGap"])
    end
    MyAbsGap = 1e-6
    if (haskey(solver_settings, "AbsGap"))
        MyAbsGap = Float64(solver_settings["AbsGap"])
    end
    MyPresolve = -1
    if (haskey(solver_settings, "Presolve"))
        MyPresolve = Int(solver_settings["Presolve"])
    end
    MyScaling = -1
    if (haskey(solver_settings, "Scaling"))
        MyScaling = Int(solver_settings["Scaling"])
    end
    MyDualize = -1
    if (haskey(solver_settings, "Dualize"))
        MyDualize = Int(solver_settings["Dualize"])
    end
    MyLpMethod = -1
    if (haskey(solver_settings, "Method"))
        MyLpMethod = Int(solver_settings["Method"])
    end
    MyDualPrice = -1
    if (haskey(solver_settings, "DualPrice"))
        MyDualPrice = Int(solver_settings["DualPrice"])
    end
    MyDualPerturb = -1
    if (haskey(solver_settings, "DualPerturb"))
        MyDualPerturb = Int(solver_settings["DualPerturb"])
    end
    MyBarHomogeneous = -1
    if (haskey(solver_settings, "BarHomogeneous"))
        MyBarHomogeneous = Int(solver_settings["BarHomogeneous"])
    end
    MyBarOrder = -1
    if (haskey(solver_settings, "BarOrder"))
        MyBarOrder = Int(solver_settings["BarOrder"])
    end
    MyBarStart = -1
    if (haskey(solver_settings, "BarStart"))
        MyBarStart = Int(solver_settings["BarStart"])
    end
    MyCrossover = -1
    if (haskey(solver_settings, "Crossover"))
        MyCrossover = Int(solver_settings["Crossover"])
    end
    MyReqFarkasRay = 0
    if (haskey(solver_settings, "ReqFarkasRay"))
        MyReqFarkasRay = Int(solver_settings["ReqFarkasRay"])
    end
    MyCutLevel = -1
    if (haskey(solver_settings, "CutLevel"))
        MyCutLevel = Int(solver_settings["CutLevel"])
    end
    MyRootCutLevel = -1
    if (haskey(solver_settings, "RootCutLevel"))
        MyRootCutLevel = Int(solver_settings["RootCutLevel"])
    end
    MyTreeCutLevel = -1
    if (haskey(solver_settings, "TreeCutLevel"))
        MyTreeCutLevel = Int(solver_settings["TreeCutLevel"])
    end
    MyRootCutRounds = -1
    if (haskey(solver_settings, "RootCutRounds"))
        MyRootCutRounds = Int(solver_settings["RootCutRounds"])
    end
    MyNodeCutRounds = -1
    if (haskey(solver_settings, "NodeCutRounds"))
        MyNodeCutRounds = Int(solver_settings["NodeCutRounds"])
    end
    MyHeurLevel = -1
    if (haskey(solver_settings, "HeurLevel"))
        MyHeurLevel = Int(solver_settings["HeurLevel"])
    end
    MyRoundingHeurLevel = -1
    if (haskey(solver_settings, "RoundingHeurLevel"))
        MyRoundingHeurLevel = Int(solver_settings["RoundingHeurLevel"])
    end
    MyDivingHeurLevel = -1
    if (haskey(solver_settings, "DivingHeurLevel"))
        MyDivingHeurLevel = Int(solver_settings["DivingHeurLevel"])
    end
    MySubMipHeurLevel = -1
    if (haskey(solver_settings, "SubMipHeurLevel"))
        MySubMipHeurLevel = Int(solver_settings["SubMipHeurLevel"])
    end
    MyFAPHeurLevel = -1
    if (haskey(solver_settings, "FAPHeurLevel"))
        MyFAPHeurLevel = Int(solver_settings["FAPHeurLevel"])
    end
    MyStrongBranching = -1
    if (haskey(solver_settings, "StrongBranching"))
        MyStrongBranching = Int(solver_settings["StrongBranching"])
    end
    MyConflictAnalysis = -1
    if (haskey(solver_settings, "ConflictAnalysis"))
        MyConflictAnalysis = Int(solver_settings["ConflictAnalysis"])
    end
    MyMipStartMode = -1
    if (haskey(solver_settings, "MipStartMode"))
        MyMipStartMode = Int(solver_settings["MipStartMode"])
    end
    MyMipStartNodeLimit = -1
    if (haskey(solver_settings, "MipStartNodeLimit"))
        MyMipStartNodeLimit = Int(solver_settings["MipStartNodeLimit"])
    end
    MySDPMethod = -1
    if (haskey(solver_settings, "SDPMethod"))
        MySDPMethod = Int(solver_settings["SDPMethod"])
    end
    MyIISMethod = -1
    if (haskey(solver_settings, "IISMethod"))
        MyIISMethod = Int(solver_settings["IISMethod"])
    end
    MyFeasRelaxMode = 0
    if (haskey(solver_settings, "FeasRelaxMode"))
        MyFeasRelaxMode = Int(solver_settings["FeasRelaxMode"])
    end
    MyTuneTimeLimit = 0
    if (haskey(solver_settings, "TuneTimeLimit"))
        MyTuneTimeLimit = Int(solver_settings["TuneTimeLimit"])
    end
    MyTuneTargetTime = 0
    if (haskey(solver_settings, "TuneTargetTime"))
        MyTuneTargetTime = Int(solver_settings["TuneTargetTime"])
    end
    MyTuneTargetRelGap = 1e-4
    if (haskey(solver_settings, "TuneTargetRelGap"))
        MyTuneTargetRelGap = Float64(solver_settings["TuneTargetRelGap"])
    end
    MyTuneMethod = -1
    if (haskey(solver_settings, "TuneMethod"))
        MyTuneMethod = Int(solver_settings["TuneMethod"])
    end
    MyTuneMode = -1
    if (haskey(solver_settings, "TuneMode"))
        MyTuneMode = Int(solver_settings["TuneMode"])
    end
    MyTuneMeasure = -1
    if (haskey(solver_settings, "TuneMeasure"))
        MyTuneMeasure = Int(solver_settings["TuneMeasure"])
    end
    MyTunePermutes = 0
    if (haskey(solver_settings, "TunePermutes"))
        MyTunePermutes = int(solver_settings["TunePermutes"])
    end
    MyTuneOutputLevel = 2
    if (haskey(solver_settings, "TuneOutputLevel"))
        MyTuneOutputLevel = Int(solver_settings["TuneOutputLevel"])
    end
    MyLazyConstraints = -1
    if (haskey(solver_settings, "LazyConstraints"))
        MyLazyConstraints = Int(solver_settings["LazyConstraints"])
    end
    MyThreads = -1
    if (haskey(solver_settings, "Threads"))
        MyThreads = Int(solver_settings["Threads"])
    end
    MyBarThreads = -1
    if (haskey(solver_settings, "BarThreads"))
        MyBarThreads = Int(solver_settings["BarThreads"])
    end
    MySimplexThreads = -1
    if (haskey(solver_settings, "SimplexThreads"))
        MySimplexThreads = Int(solver_settings["SimplexThreads"])
    end
    MyCrossoverThreads = -1
    if (haskey(solver_settings, "CrossoverThreads"))
        MyCrossoverThreads = Int(solver_settings["CrossoverThreads"])
    end
    MyMipTasks = -1
    if (haskey(solver_settings, "MipTasks"))
        MyMipTasks = Int(solver_settings["MipTasks"])
    end
    MyGPUMode = -1
    if (haskey(solver_settings, "GPUMode"))
        MyGPUMode = Int(solver_settings["GPUMode"])
    end
    MyGPUDevice = -1
    if (haskey(solver_settings, "GPUDevice"))
        MyGPUDevice = Int(solver_settings["GPUDevice"])
    end
    MyPDLPTol = 1e-6
    if (haskey(solver_settings, "PDLPTol"))
        MyPDLPTol = Float64(solver_settings["PDLPTol"])
    end
    MyLogging = 1
    if (haskey(solver_settings, "Logging"))
        MyLogging = Int(solver_settings["Logging"])
    end
    MyLogToConsole = 1 # Control console logging.
    if (haskey(solver_settings, "LogToConsole"))
        MyLogToConsole = solver_settings["LogToConsole"]
    end
    MyLogFile = "" # COPT log file.
    if (haskey(solver_settings, "LogFile"))
        MyLogFile = solver_settings["LogFile"]
    end
    ########################################################################

    ## User modified solver settings #######################################
    if haskey(solver_user_settings, "TimeLimit")
        MyTimeLimit = solver_user_settings["TimeLimit"]
    end
    if haskey(solver_user_settings, "CrossOver")
        MyCrossover = solver_user_settings["CrossOver"] == "on" ? 1 : 0
    end
    if haskey(solver_user_settings, "Method")
        MyLpMethod = solver_user_settings["Method"]
    end
    if haskey(solver_user_settings, "BarHomogeneous")
        MyBarHomogeneous = solver_user_settings["BarHomogeneous"]
    end
    if haskey(solver_user_settings, "BarIterLimit")
        MyBarIterLimit = solver_user_settings["BarIterLimit"]
    end
    if haskey(solver_user_settings, "Threads")
        MyThreads = solver_user_settings["Threads"]
        MyBarThreads = solver_user_settings["Threads"]
        MySimplexThreads = solver_user_settings["Threads"]
        MyCrossoverThreads = solver_user_settings["Threads"]
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
        COPT.Optimizer,
        "TimeLimit" => MyTimeLimit,
        "Presolve" => MyPresolve,
        "BarIterLimit" => MyBarIterLimit,
        "LpMethod" => MyLpMethod,
        "Crossover" => MyCrossover,
        "BarHomogeneous" => MyBarHomogeneous,
        "Threads" => MyThreads,
        "Logging" => MyLogging,
        "LogFile" => MyLogFile,
        "LogToConsole" => MyLogToConsole,
    )

    return OPTIMIZER
end
