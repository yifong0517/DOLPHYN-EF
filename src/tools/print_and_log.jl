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
    print_and_log(settings::Dict, level::AbstractString, message::AbstractString)

This function takes a message which is one-piece string in julia and print it in console or
log file using different level logging depending on ```Log``` flag and ```silent``` flag.
"""
function print_and_log(settings::Dict, level::AbstractString, message::AbstractString)

    ## Log flag is determined by LogFile initially in setting file
    Log = settings["Log"]
    Silent = settings["Silent"]

    if Log
        if !(Silent == 1)
            println(message)
        end
        if level == "i"
            @info("$(Dates.format(now(), "yyyy-mm-dd HH:MM:SS")) $message")
        elseif level == "w"
            @warn("$(Dates.format(now(), "yyyy-mm-dd HH:MM:SS")) $message")
        elseif level == "e"
            @error("$(Dates.format(now(), "yyyy-mm-dd HH:MM:SS")) $message")
        else
            println("Wrong Level Input!")
        end
    else
        if !(Silent == 1)
            println(message)
        end
    end
end
