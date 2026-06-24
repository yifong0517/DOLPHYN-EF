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
function modify_settings(settings::Dict, modification::Dict)

    dfGlobalSettings = settings["dfGlobalSettings"]

    ## Modification keys
    mkeys = collect(keys(modification))

    ## Global settings include global model settings, solver settings and clustering settings
    global_setting_keys = [
        "RootPath",
        "SavePath",
        "TimeMode",
        "TotalTime",
        "ModelMode",
        "ModelFuels",
        "ModelPower",
        "ModelHydrogen",
        "ModelCarbon",
        "ModelSynfuels",
        "ModelAmmonia",
        "ModelBioenergy",
        "ModelFoodstuff",
        "DirectModel",
        "ObjScale",
        "Solver",
        "ResourceAvailability",
        "MaxEmissionMts",
        "CO2Disposal",
        "Write",
        "OverWrite",
        "WriteLevel",
        "WriteAnalysis",
        "ModelFile",
        "SnifferFile",
        "DBFile",
        "LogFile",
        "Silent",
        "MGA",
        "MGASlack",
        "MGAIteration",
    ]
    ## Resource setting keys
    resource_setting_keys = [
        "FuelPath",
        "FuelsAvailabilityPath",
        "ElectricityPath",
        "ElectricityAvailabilityPath",
        "HydrogenPath",
        "HydrogenAvailabilityPath",
        "CarbonPath",
        "CarbonAvailabilityPath",
        "BioenergyPath",
        "BioenergyAvailabilityPath",
    ]
    ## Solver setting keys
    solver_setting_keys = [
        "TimeLimit",
        "MipGap",
        "CrossOver",
        "Method",
        "BarConvTol",
        "BarHomogeneous",
        "BarIterLimit",
        "Threads",
    ]
    ## Time aggregation setting keys
    time_aggregation_setting_keys = [
        "TimestepsPerRepPeriod",
        "ClusterMethod",
        "ScalingMethod",
        "IterativelyAddPeriods",
        "MaxPeriods",
        "MinPeriods",
        "IterateMethod",
        "Threshold",
        "nIters",
    ]

    ## Update user-defined global settings into run-time settings
    for (key, value) in modification
        if key == "RootPath"
            settings[key] = abspath(joinpath(settings["Project"], value))
            delete!(modification, key)
        elseif key == "Zones"
            if value != "All"
                settings[key] = String.([value])
            end
            delete!(modification, key)
        elseif key == "CO2Policy"
            if typeof(value) == Int64
                settings[key] = [value]
            elseif typeof(value) <: AbstractString
                settings[key] = parse.(Int64, split(value, "+"))
            end
            delete!(modification, key)
        elseif key in global_setting_keys
            settings[key] = value
            delete!(modification, key)
        elseif key in resource_setting_keys
            settings["ResourceUserSettings"][key] = value
            delete!(modification, key)
        elseif key in solver_setting_keys
            settings["SolverUserSettings"][key] = value
            delete!(modification, key)
        elseif settings["TimeMode"] in ["PTFE", "APTTA-1", "APTTA-2"] &&
               key in time_aggregation_setting_keys
            settings["ClusterUserSettings"][key] = value
            delete!(modification, key)
        end
    end

    ## Update settings origination dataframe
    dfGlobalSettings = transform(
        dfGlobalSettings,
        [:Key, :Value, :Origin] =>
            ByRow(
                (k, v, o) -> (
                    Value = k in intersect(mkeys, global_setting_keys) ? settings[k] : v,
                    Origin = k in intersect(mkeys, global_setting_keys) ? "user-modi" : o,
                ),
            ) => AsTable,
    )

    settings["dfGlobalSettings"] = dfGlobalSettings

    ## Record save path into solver settings
    settings["SolverUserSettings"]["SavePath"] = settings["SavePath"]

    ## Store modification dict into settings for data modification
    settings["Modification"] = modification

    return settings
end
