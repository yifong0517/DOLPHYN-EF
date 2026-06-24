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
function normalize_profiles(profiles::DataFrame, settings::Dict)

    cluster_settings = settings["ClusterSettings"]

    ScalingMethod = cluster_settings["ScalingMethod"]

    # Normalize/standardize data based on user-provided method
    if ScalingMethod == "N"
        normProfiles = [
            StatsBase.transform(
                fit(UnitRangeTransform, profiles[!, c]; dims = 1, unit = true),
                profiles[!, c],
            ) for c in names(profiles)[2:end]
        ]
    elseif ScalingMethod == "S"
        normProfiles = [
            StatsBase.transform(
                fit(ZScoreTransform, profiles[!, c]; dims = 1, center = true, scale = true),
                profiles[!, c],
            ) for c in names(profiles)[2:end]
        ]
    else
        print_and_log(
            settings,
            "e",
            "Invalid ScalingMethod: Use N for Normalization or S for Standardization.",
        )
        print_and_log(settings, "i", "Continuing Using 0->1 Normalization...")
        normProfiles = [
            StatsBase.transform(
                fit(UnitRangeTransform, profiles[!, c]; dims = 1, unit = true),
                profiles[!, c],
            ) for c in names(profiles)[2:end]
        ]
    end

    ## Construct normalized profiles dataframe
    normProfiles = hcat(
        DataFrame(Dict(:Time_Index => profiles.Time_Index)),
        DataFrame(Dict(names(profiles)[2:end] .=> normProfiles)),
    )

    return normProfiles
end
