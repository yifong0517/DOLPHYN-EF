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
	configure_cbc(solver_settings_path::String, solver_user_settings::Union{Dict, Nothing} = nothing)

Reads user-specified solver settings from cbc\_settings.yml in the directory specified by the string solver\_settings\_path.
solver_user_settings is a user-defined dictionary containing some settings that could be altered by user.

Returns a MathOptInterface OptimizerWithAttributes Cbc optimizer instance to be used in the generate() method.

The Cbc optimizer instance is configured with the following default parameters if a user-specified parameter for each respective field is not provided:

 - seconds = 110000
 - logLevel = 1e-6
 - maxSolutions = -1
 - maxNodes = -1
 - allowableGap = -1
 - ratioGap = Inf
 - threads = 1

"""
function configure_cbc(
    solver_settings_path::String,
    solver_user_settings::Union{Dict, Nothing} = nothing,
)

    solver_settings = YAML.load(open(solver_settings_path))

    ## Optional solver parameters ############################################
    Myseconds = 110000
    if (haskey(solver_settings, "TimeLimit"))
        Myseconds = solver_settings["TimeLimit"]
    end
    MylogLevel = 1e-6
    if (haskey(solver_settings, "logLevel"))
        MylogLevel = solver_settings["logLevel"]
    end
    MymaxSolutions = -1
    if (haskey(solver_settings, "maxSolutions"))
        MymaxSolutions = solver_settings["maxSolutions"]
    end
    MymaxNodes = -1
    if (haskey(solver_settings, "maxNodes"))
        MymaxNodes = solver_settings["maxNodes"]
    end
    MyallowableGap = -1
    if (haskey(solver_settings, "allowableGap"))
        MyallowableGap = solver_settings["allowableGap"]
    end
    MyratioGap = Inf
    if (haskey(solver_settings, "ratioGap"))
        MyratioGap = solver_settings["ratioGap"]
    end
    Mythreads = 1
    if (haskey(solver_settings, "threads"))
        Mythreads = solver_settings["threads"]
    end
    ########################################################################

    ## User modified solver settings #######################################
    if haskey(solver_user_settings, "TimeLimit")
        Myseconds = solver_user_settings["TimeLimit"]
    end
    ########################################################################

    OPTIMIZER = optimizer_with_attributes(
        Cbc.Optimizer,
        "seconds" => Myseconds,
        "logLevel" => MylogLevel,
        "maxSolutions" => MymaxSolutions,
        "maxNodes" => MymaxNodes,
        "allowableGap" => MyallowableGap,
        "ratioGap" => MyratioGap,
        "threads" => Mythreads,
    )

    return OPTIMIZER
end
