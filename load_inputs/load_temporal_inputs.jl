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
function load_temporal_inputs(settings::Dict, inputs::Dict)

    print_and_log(settings, "i", "Loading Multi Energy System Temporal Inputs")

    ## Parse temporal modeling mode and total time length
    TimeMode = settings["TimeMode"]
    inputs["TimeMode"] = TimeMode

    ## Dictionary storing messages for different time modes
    TimeModeMessages = Dict(
        "FTBM" => "Full Time Benchmark",
        "PTFE" => "Part Time Feature Extration",
        "APTTA-1" => "Auto Part Time Time Aggregation in Full Time Length",
        "APTTA-2" => "Auto Part Time Time Aggregation in Reduced Time Length",
        "MPTTA-1" => "Manual Part Time Time Aggregation with Given Weights File in Full Time Length",
        "MPTTA-2" => "Manual Part Time Time Aggregation with Given Weights File in Reduced Time Length",
        "MPTTA-3" => "Manual Part Time Time Aggregation with Given Periods Index",
    )

    print_and_log(settings, "i", "TimeMode: $TimeMode. $(TimeModeMessages[TimeMode]).")

    ## Parse total time length
    TotalTime = settings["TotalTime"]
    inputs["TotalTime"] = TotalTime

    ## Parse temporal modeling index and set
    inputs = load_time_index(settings, inputs)

    print_and_log(settings, "i", "Temporal Modeling Set: $(inputs["Time_Index"])")

    print_and_log(settings, "i", "Temporal Modeling Index 1-$(inputs["T"])")

    return inputs
end
