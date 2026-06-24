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
function load_default_time_aggregation_settings(
    time_aggregation_settings::Dict,
    time_aggregation_user_settings::Dict,
)

    ## Time aggregation settings origination dataframe
    dfTimeAggregationSettings =
        DataFrame(Scope = String[], Key = String[], Value = Any[], Origin = String[])
    time_aggregation_settings["dfTimeAggregationSettings"] = dfTimeAggregationSettings
    mkeys = collect(keys(time_aggregation_user_settings))

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

    ## Number of timesteps per representative period
    set_default_value!(time_aggregation_settings, "TimestepsPerRepPeriod", 168)
    ## Clustering method, "kmeans" or "kmedoids"
    set_default_value!(time_aggregation_settings, "ClusterMethod", "kmeans")
    ## Scaling method, "N" for normalize or "S" for standardize
    set_default_value!(time_aggregation_settings, "ScalingMethod", "S")
    ## Flag whether to iteratively add periods
    set_default_value!(time_aggregation_settings, "IterativelyAddPeriods", 1)
    ## Maximum number of periods
    set_default_value!(time_aggregation_settings, "MaxPeriods", 10)
    ## Minimum number of periods
    set_default_value!(time_aggregation_settings, "MinPeriods", 1)
    ## Iteration method, "cluster" or "extreme"
    set_default_value!(time_aggregation_settings, "IterateMethod", "cluster")
    ## Threshold for iterative period addition
    set_default_value!(time_aggregation_settings, "Threshold", 0.05)
    ## Number of iterations for each clustering
    set_default_value!(time_aggregation_settings, "nIters", 100)

    dfTimeAggregationSettings = time_aggregation_settings["dfTimeAggregationSettings"]
    dfTimeAggregationSettings = transform(
        dfTimeAggregationSettings,
        [:Key, :Value, :Origin] =>
            ByRow(
                (k, v, o) -> (
                    Value = k in intersect(mkeys, time_aggregation_setting_keys) ?
                            settings["ClusterUserSettings"][k] : v,
                    Origin = k in intersect(mkeys, time_aggregation_setting_keys) ? "user-modi" : o,
                ),
            ) => AsTable,
    )

    time_aggregation_settings["dfTimeAggregationSettings"] = dfTimeAggregationSettings

    return time_aggregation_settings
end

@doc raw"""

"""
function set_default_value!(time_aggregation_settings::Dict, key::String, default_value::Any)

    dfTimeAggregationSettings = time_aggregation_settings["dfTimeAggregationSettings"]

    if !haskey(time_aggregation_settings, key)
        time_aggregation_settings[key] = default_value
        push!(dfTimeAggregationSettings, ["TimeAggregation", key, default_value, "default"])
    else
        push!(
            dfTimeAggregationSettings,
            ["TimeAggregation", key, time_aggregation_settings[key], "user-file"],
        )
    end
end
