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
function load_time_index(settings::Dict, inputs::Dict)

    ## Parse TimeMode
    TimeMode = settings["TimeMode"]

    ## Save path
    save_path = settings["SavePath"]

    if TimeMode == "FTBM"
        inputs["Time_Index"] = 1:settings["TotalTime"]
        inputs["T"] = settings["TotalTime"]
        inputs["Period"] = inputs["T"]
        ## Before shifted 1 time index
        inputs["BS1T"] = hours_before(inputs["Period"], inputs["Time_Index"], 1)
        inputs["START_SUBPERIODS"] = 1:inputs["Period"]:inputs["T"]
        inputs["INTERIOR_SUBPERIODS"] = setdiff(1:inputs["T"], inputs["START_SUBPERIODS"])
        inputs["weights"] = ones(inputs["T"])
    elseif TimeMode == "PTFE" || TimeMode == "APTTA-1" || TimeMode == "APTTA-2"
        inputs["Time_Index"] = 1:settings["TotalTime"]
        inputs["T"] = settings["TotalTime"]
        inputs["Period"] = settings["Period"]
        if inputs["T"] % inputs["Period"] != 0
            print_and_log(
                settings,
                "w",
                "Total time length must be a multiple of period! Trucating the last period.",
            )
            inputs["T"] = inputs["T"] - inputs["T"] % inputs["Period"]
            inputs["Time_Index"] = inputs["Time_Index"][1:inputs["T"]]
        end

        pre_inputs = load_time_series(settings, inputs)
        PeriodMap = cluster(settings, pre_inputs)
        if TimeMode == "APTTA-1"
            inputs["Time_Index"] = reduce(
                vcat,
                [
                    ((i - 1) * inputs["Period"] + 1):(i * inputs["Period"]) for
                    i in PeriodMap.Rep_Period
                ],
            )
            inputs["weights"] = ones(inputs["T"])
        elseif TimeMode == "APTTA-2"
            inputs["Time_Index"] = reduce(
                vcat,
                [
                    ((i - 1) * inputs["Period"] + 1):(i * inputs["Period"]) for
                    i in sort(unique(PeriodMap.Rep_Period))
                ],
            )
            inputs["T"] = length(inputs["Time_Index"])
            periods_count = counter(PeriodMap.Rep_Period)
            inputs["weights"] = reduce(
                vcat,
                repeat([periods_count[i]], inputs["Period"]) for
                i in sort(unique(PeriodMap.Rep_Period))
            )
        end

        inputs["START_SUBPERIODS"] = 1:inputs["Period"]:inputs["T"]
        inputs["INTERIOR_SUBPERIODS"] = setdiff(1:inputs["T"], inputs["START_SUBPERIODS"])

        CSV.write(joinpath(save_path, "PeriodMap.csv"), PeriodMap)
    elseif TimeMode == "MPTTA-1" || TimeMode == "MPTTA-2"
        inputs["Period"] = settings["Period"]

        root_path = settings["RootPath"]
        time_weights_path = joinpath(root_path, settings["TimeWeight"])
        ## Check if file exists. Using weights when file exists, otherwise using uniform weights
        if isfile(time_weights_path)
            PeriodMap = DataFrame(CSV.File(time_weights_path))
            if TimeMode == "MPTTA-1"
                inputs["Time_Index"] = reduce(
                    vcat,
                    [
                        ((i - 1) * inputs["Period"] + 1):(i * inputs["Period"]) for
                        i in PeriodMap.Rep_Period
                    ],
                )
                inputs["T"] = length(inputs["Time_Index"])
                inputs["weights"] = ones(inputs["T"])
            elseif TimeMode == "MPTTA-2"
                inputs["Time_Index"] = reduce(
                    vcat,
                    [
                        ((i - 1) * inputs["Period"] + 1):(i * inputs["Period"]) for
                        i in sort(unique(PeriodMap.Rep_Period))
                    ],
                )
                inputs["T"] = length(inputs["Time_Index"])
                periods_count = counter(PeriodMap.Rep_Period)
                inputs["weights"] = reduce(
                    vcat,
                    repeat([periods_count[i]], inputs["Period"]) for
                    i in sort(unique(PeriodMap.Rep_Period))
                )
            end
            inputs["START_SUBPERIODS"] = 1:inputs["Period"]:inputs["T"]
            inputs["INTERIOR_SUBPERIODS"] = setdiff(1:inputs["T"], inputs["START_SUBPERIODS"])
        else
            print_and_log(
                settings,
                "w",
                "Time weights file does not exist. Using TimeMode MPTTA-3.",
            )
            TimeMode = "MPTTA-3"
        end

        if TimeMode == "MPTTA-3"
            inputs["Period"] = settings["Period"]
            inputs["TotalTime"] = settings["TotalTime"]
            inputs["T"] = inputs["Period"] * length(settings["PeriodIndex"])
            inputs["Time_Index"] = reduce(
                vcat,
                [
                    ((p - 1) * inputs["Period"] + 1):(p * inputs["Period"]) for
                    p in settings["PeriodIndex"]
                ],
            )
            inputs["START_SUBPERIODS"] = 1:inputs["Period"]:inputs["T"]
            inputs["INTERIOR_SUBPERIODS"] = setdiff(1:inputs["T"], inputs["START_SUBPERIODS"])
            inputs["weights"] = ones(inputs["T"]) .* (inputs["TotalTime"] / inputs["Period"])
        end
    else
        print_and_log(
            settings,
            "e",
            "TimeMode $TimeMode not supported! Using one of 'FTBM', 'PTFE', 'APTTA-1', 'APTTA-2', 'MPTTA-1', 'MPTTA-2' or 'MPTTA-3'.",
        )
    end

    return inputs
end
