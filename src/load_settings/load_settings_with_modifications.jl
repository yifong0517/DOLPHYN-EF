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
function load_settings_with_modifications(
    settings_path::AbstractString,
    modifications::AbstractVector{Dict{String, Any}},
    modification_number::Integer,
)

    ## Load settings from settings path
    if settings_path == ""
        settings = Dict{Any, Any}()
    else
        settings = YAML.load(open(settings_path))
    end

    ## Load default settings
    settings = load_default_settings(settings)

    ## Add project path to settings
    project_path = pkgdir(@__MODULE__)
    settings["Project"] = project_path

    ## Start time
    settings["StartTime"] = time()
    settings["StartDateTime"] = Dates.now()

    ## User-specific settings dictionary
    settings["ResourceUserSettings"] = Dict()
    settings["SolverUserSettings"] = Dict()
    settings["ClusterUserSettings"] = Dict()

    ## Specify modification number in usage
    modification = modifications[modification_number]

    ## Modify settings with modification
    settings = modify_settings(settings, modification)

    ## Check whether save path exists, if not, create it
    if settings["Write"] == 1
        save_path = settings["SavePath"]
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

    ## Update solver settings from settings file
    solver_setting_keys =
        ["TimeLimit", "MipGap", "CrossOver", "Method", "BarHomogeneous", "BarConvTol", "Threads"]
    for key in solver_setting_keys
        if haskey(settings, key)
            settings["SolverUserSettings"][key] = settings[key]
            delete!(settings, key)
        end
    end

    print_and_log(
        settings,
        "i",
        "Loading Settings from $settings_path with\nNo.$modification_number Modification",
    )
    print_and_log(settings, "i", "Save Path Initialized to $save_path")

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

    ## Solver settings path
    if settings["SolverPath"] == "default"
        settings["SolverPath"] = joinpath(project_path, "default")
    elseif settings["SolverPath"] == "root"
        settings["SolverPath"] = settings["RootPath"]
    end

    ## Case sectors settings path
    if settings["SettingPath"] == "default"
        settings["SettingPath"] = joinpath(project_path, "default", "Settings")
    elseif settings["SettingPath"] == "root"
        settings["SettingPath"] = joinpath(settings["RootPath"], "Settings")
    end

    ## Global carbon policy
    if in(0, settings["CO2Policy"])
        settings["CO2Policy"] = [0]
    elseif in(-1, settings["CO2Policy"])
        settings["CO2Policy"] = [-1]
    end

    ## Case resource settings path
    resource_settings_path = joinpath(settings["SettingPath"], settings["ResourceSettings"])
    resource_settings = YAML.load(open(resource_settings_path))
    ## Load default resource settings
    resource_settings =
        load_default_resource_settings(resource_settings, settings["ResourceUserSettings"])
    settings["ResourceSettings"] = resource_settings
    settings["ResourceAvailability"] == haskey(settings, "ResourceAvailability") &&
        settings["ResourceAvailability"]

    return settings
end
