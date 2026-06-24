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
function stack_profiles(profiles::DataFrame, settings::Dict)

    cluster_settings = settings["ClusterSettings"]

    TimestepsPerRepPeriod = cluster_settings["TimestepsPerRepPeriod"]

    ## Change Time_Index column to Group column
    rename!(profiles, :Time_Index => :Group)

    NumDataPoints = settings["TotalTime"] ÷ TimestepsPerRepPeriod

    ## Group col identifies the subperiod ID of each hour (e.g., all hours in week 2 have Group=2 if using TimestepsPerRepPeriod=168)
    profiles[:, :Group] .= (profiles[:, :Group] .- 1) .÷ TimestepsPerRepPeriod .+ 1

    ## Construct features dataframe
    features = [
        stack(profiles[isequal.(profiles.Group, w), :], names(profiles)[2:end])[!, :value] for
        w in 1:NumDataPoints
    ]

    features = DataFrame(Dict(Symbol.(1:NumDataPoints) .=> features))

    return features
end
