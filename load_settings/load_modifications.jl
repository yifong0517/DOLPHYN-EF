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
    load_modifications(modifications_path::AbstractString)

This function loads the modifications from the given path and organizes them into dictionaries in sequence.
"""
function load_modifications(
    modifications_path::AbstractString,
    modifications_range::Union{UnitRange{Int64}, StepRange{Int64, Int64}, AbstractString} = "",
)

    ## Ensure the path is absolute path
    path = expanduser(modifications_path)

    ## Read in modifications as DataFrame
    df = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Add sub case column
    df = transform(df, eachindex => :SubCase)

    ## Filter modifications using case number or status filter
    if modifications_range != ""
        if typeof(modifications_range) in [UnitRange{Int64}, StepRange{Int64, Int64}]
            df = filter(:SubCase => x -> in(x, modifications_range), df)
        elseif typeof(modifications_range) == AbstractString && in("Status", names(df))
            df = filter(:Status => x -> contains(x, modifications_range), df)
        end
    end

    ## Construct modifications list of modification dict from dataframe
    modifications = [Dict(names(df) .=> values(row)) for row in eachrow(df)]

    return modifications
end
