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
function mga_settings(path::AbstractString, op::AbstractString, settings::Dict, iter::Int64)

    slack = settings["MGASlack"]

    ## Create results directory for mga iterations
    save_path = "$(path)_MGA$(op)_Slack$(slack)_Iter$(iter)"

    ## Check whether save path exists, if not, create it
    if settings["Write"] == 1
        if settings["OverWrite"] == 1
            if !ispath(save_path)
                mkdir(save_path)
            end
        else
            init_path = save_path
            counter = 1
            while ispath(save_path)
                save_path = string(init_path, "_", counter)
                counter += 1
            end
            mkdir(save_path)
        end

        settings["SavePath"] = save_path
        settings["SolverUserSettings"]["SavePath"] = save_path
    else
        settings["SolverUserSettings"]["SavePath"] = ""
        settings["DBFile"] = ""
        settings["LogFile"] = ""
        settings["ModelFile"] = ""
    end

    ## Database settings
    if settings["DBFile"] != ""
        DB = SQLite.DB(joinpath(settings["SavePath"], settings["DBFile"]))
        settings["DB"] = DB
    end

    ## Logging settings
    if settings["LogFile"] != ""
        settings["Log"] = true
        logger = FileLogger(joinpath(settings["SavePath"], settings["LogFile"]))
        global_logger(logger)
    else
        settings["Log"] = false
    end

    ## Console logging settings
    if !haskey(settings, "Silent")
        settings["Silent"] = 0
    end
    settings["SolverUserSettings"]["Silent"] = settings["Silent"]

    ## Check whether model file exists
    if settings["ModelFile"] != ""
        model_path = joinpath(settings["SavePath"], settings["ModelFile"])
        if isfile(model_path)
            settings["ExistingModel"] = 1
            settings["ModelPath"] = model_path
        else
            settings["ExistingModel"] = 0
        end
    else
        settings["ExistingModel"] = 0
    end

    return settings
end
