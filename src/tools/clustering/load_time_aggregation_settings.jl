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
function load_time_aggregation_settings(settings::Dict)

    ## Time aggregation settings path
    if settings["TimeAggregationPath"] == "default"
        time_aggregation_settings_path = joinpath(settings["Project"], "default", "Settings")
    elseif settings["TimeAggregationPath"] == "root"
        time_aggregation_settings_path = joinpath(settings["RootPath"], "Settings")
    end

    time_aggregation_settings =
        YAML.load(open(joinpath(time_aggregation_settings_path, "time_aggregation_settings.yml")))
    time_aggregation_settings = load_default_time_aggregation_settings(
        time_aggregation_settings,
        settings["ClusterUserSettings"],
    )

    ## Add clustering setttings into settings
    settings["ClusterSettings"] = time_aggregation_settings

    return settings
end
