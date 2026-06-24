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
function showtime(settings::Dict, to::TimerOutput)

    print_and_log(settings, "i", "Recording Time Usage into Log File")

    ## Get time usage from TimerOutput
    time_usage = TimerOutputs.todict(to)

    total_time_seconds = time_usage["total_time_ns"] / 1e9
    if total_time_seconds <= 60
        print_and_log(
            settings,
            "i",
            "Total Time Usage: $(round(total_time_seconds,sigdigits=2)) second(s)",
        )
    else
        total_time_seconds = Dates.Second(ceil(total_time_seconds))
        print_and_log(settings, "i", "Total Time Usage: $(Humanize.timedelta(total_time_seconds))")
    end

    total_allocation_bytes = time_usage["total_allocated_bytes"]
    print_and_log(
        settings,
        "i",
        "Total Allocation: $(Humanize.datasize(total_allocation_bytes, style=:gnu, format="%.2f"))",
    )

    ## Present time usage in console
    show(to)
    println("\n")
end


@doc raw"""

"""
function showtime(to::TimerOutput)

    ## Get time usage from TimerOutput
    time_usage = TimerOutputs.todict(to)

    total_time_seconds = time_usage["total_time_ns"] / 1e9
    if total_time_seconds <= 60
        println("Total Time Usage: $(round(total_time_seconds,sigdigits=2)) second(s)")
    else
        total_time_seconds = Dates.Second(ceil(total_time_seconds))
        println("Total Time Usage: $(Humanize.timedelta(total_time_seconds))")
    end

    total_allocation_bytes = time_usage["total_allocated_bytes"]
    println(
        "Total Allocation: $(Humanize.datasize(total_allocation_bytes, style=:gnu, format="%.2f"))",
    )

    ## Present time usage in console
    show(to)
    println("\n")
end
