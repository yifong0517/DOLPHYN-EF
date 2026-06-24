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
    load_default_settings(settings::Dict)

Set default global settings if absent in settings file and identify settings origination.
"""
function load_default_settings(settings::Dict)

    ## Global settings origination dataframe
    dfGlobalSettings = DataFrame(Scope = String[], Key = String[], Value = Any[], Origin = String[])
    settings["dfGlobalSettings"] = dfGlobalSettings

    ## # Data root absolute path
    ## Add project path to settings
    project_path = pkgdir(@__MODULE__)
    settings["Project"] = project_path
    ## Parse data root path according to relative path to project path
    ## TODO: This script sets case folder relative to project path, seperating project and case folder is something to implement
    RootPath =
        abspath(project_path, haskey(settings, "RootPath") ? settings["RootPath"] : "benchmark")
    set_default_value!(settings, "RootPath", RootPath)

    ## Subfolder for external resources under root
    set_default_value!(settings, "ResourceInputs", "Outer")
    ## Subfolder for power sector inputs under root
    set_default_value!(settings, "PowerInputs", "Power")
    ## Subfolder for hydrogen sector inputs under root
    set_default_value!(settings, "HydrogenInputs", "Hydrogen")
    ## Subfolder for carbon sector inputs under root
    set_default_value!(settings, "CarbonInputs", "Carbon")
    ## Subfolder for synfuels sector inputs under root
    set_default_value!(settings, "SynfuelsInputs", "Synfuels")
    ## Subfolder for ammonia sector inputs under root
    set_default_value!(settings, "AmmoniaInputs", "Ammonia")
    ## Subfolder for foodstuff sector inputs under root
    set_default_value!(settings, "FoodstuffInputs", "Foodstuff")
    ## Subfolder for bioenergy sector inputs under root
    set_default_value!(settings, "BioenergyInputs", "Bioenergy")

    ## Solvers setting path; default (default settings) or root (user specified within root)
    set_default_value!(settings, "SolverPath", "default")
    ## Case sectors setting path; default (default settings) or root (user specified within root)
    set_default_value!(settings, "SettingPath", "default")
    ## Resource setting path
    set_default_value!(settings, "ResourceSettings", "resource_settings.yml")
    ## Power sector setting path
    set_default_value!(settings, "PowerSettings", "power_settings.yml")
    ## Hydrogen sector setting path
    set_default_value!(settings, "HydrogenSettings", "hydrogen_settings.yml")
    ## Carbon sector setting path
    set_default_value!(settings, "CarbonSettings", "carbon_settings.yml")
    ## Synfuels sector setting path
    set_default_value!(settings, "SynfuelsSettings", "synfuels_settings.yml")
    ## Ammonia sector setting path
    set_default_value!(settings, "AmmoniaSettings", "ammonia_settings.yml")
    ## Foodstuff sector setting path
    set_default_value!(settings, "FoodstuffSettings", "foodstuff_settings.yml")
    ## Bioenergy sector setting path
    set_default_value!(settings, "BioenergySettings", "bioenergy_settings.yml")

    ## Time aggregation setting path; default (default settings) or root (user specified within root)
    set_default_value!(settings, "TimeAggregationPath", "default")

    ## Time mode, available modes: FTBM (Full time benchmark), PTFE (Part time feature extration), APTTA-1/2 (Auto part time time aggregation), MPTTA-1/2/3 (Manual part time time aggregation)
    set_default_value!(settings, "TimeMode", "FTBM")
    ## Total time length in hours for modeling, used when TimeMode is FTBM and APTTA
    set_default_value!(settings, "TotalTime", 168)
    ## Periods in a time slice, used when TimeMode is PTFE, APTTA and MPTTA
    set_default_value!(settings, "Period", 168)
    ## Time slices weights file path, active when TimeMode is MPTTA with specific weights
    set_default_value!(settings, "TimeWeight", "")
    ## Period list for modeling, activate when TimeMode is MPTTA with uniform weights
    set_default_value!(settings, "PeriodIndex", [1])
    ## Zone list for modeling
    set_default_value!(settings, "Zones", ["z1", "z2", "z3"])
    ## Zone number
    set_default_value!(settings, "TotalZone", length(settings["Zones"]))

    ## Model mode, "OP" for operation mode, "EP" for expansion mode; "DD" for data defined
    set_default_value!(settings, "ModelMode", "DD")
    ## Flag whether fuels are modeled
    set_default_value!(settings, "ModelFuels", 1)
    ## Flag whether power sector is modeled
    set_default_value!(settings, "ModelPower", 0)
    ## Flag whether hydrogen sector is modeled
    set_default_value!(settings, "ModelHydrogen", 0)
    ## Flag whether carbon sector is modeled
    set_default_value!(settings, "ModelCarbon", 0)
    ## Flag whether synthesis fuels sector is modeled
    set_default_value!(settings, "ModelSynfuels", 0)
    ## Flag whether ammonia sector is modeled
    set_default_value!(settings, "ModelAmmonia", 0)
    ## Flag whether foodstuff sector is modeled
    set_default_value!(settings, "ModelFoodstuff", 0)
    ## Flag whether bioenergy sector is modeled
    set_default_value!(settings, "ModelBioenergy", 0)

    ## Flag whether to use direct_model in JuMP, active when model is linear
    set_default_value!(settings, "DirectModel", 0)

    ## Objective scaling factor for objective range adjustment
    set_default_value!(settings, "ObjScale", 1)

    ## Solver name, available solvers: gurobi, cplex, highs, cbc, clp
    set_default_value!(settings, "Solver", "highs")

    ## Resource availablity policy
    set_default_value!(settings, "ResourceAvailability", 0)

    ## Global carbon emission policy for all sectors
    set_default_value!(settings, "CO2Policy", [0])
    ## Maximum emission in million tonnes - active when CO2Policy is 1
    set_default_value!(settings, "MaxEmissionMts", 400000)
    ## Captured carbon disposal policy, 0 (no disposal), 1 (disposal within sector), 2 (disposal globally). Missing means no disposal
    set_default_value!(settings, "CO2Disposal", 0)

    ## Flag whether outputs will be saved
    set_default_value!(settings, "Write", 1)

    ## Save path for results
    set_default_value!(settings, "SavePath", "Results")

    ## Results writing level, A-level for analysis (1), Z-level (2) for zonal and resource-specific, T-level (3) for temporal. Lined up from A-level to T-level
    set_default_value!(settings, "WriteLevel", 3)

    ## Flag whether to write analysis result
    set_default_value!(settings, "WriteAnalysis", 1)

    ## Flag whether outputs will be overwritten
    set_default_value!(settings, "OverWrite", 0)

    ## Model name for recording it into file
    set_default_value!(settings, "ModelFile", "")

    ## Sniffer file name for recording it into file
    set_default_value!(settings, "SnifferFile", "")

    ## SQLite database name for recording it into file
    set_default_value!(settings, "DBFile", "")

    ## Log file name for recording it into file
    set_default_value!(settings, "LogFile", "log.txt")

    return settings
end

@doc raw"""
    set_default_value!(settings::Dict, key::String, default_value::Any)

Set a default value for a given key in a settings dictionary. If the key does not exist in the dictionary, it is added with the given default value. The function also adds an entry to the global settings origination dataframe, indicating the source of the default value (i.e., whether it was set by the user or loaded from default settings).

# Arguments
- `settings::Dict`: Dictionary of settings.
- `key::String`: Key of the setting to set the default value for.
- `default_value::Any`: Default value to set for the given key.

# Returns
- `Nothing`.

# Examples
```julia-repl
julia> settings = Dict("key" => "value")
julia> set_default_value!(settings, "key2", "value2")
julia> settings
Dict("key" => "value", "key2" => "value2")
"""
function set_default_value!(settings::Dict, key::String, default_value::Any)

    dfGlobalSettings = settings["dfGlobalSettings"]

    if !haskey(settings, key)
        settings[key] = default_value
        push!(dfGlobalSettings, ["Global", key, default_value, "default"])
    else
        push!(dfGlobalSettings, ["Global", key, settings[key], "user-file"])
    end
end
