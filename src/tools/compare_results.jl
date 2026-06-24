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
    compare_results(path1::AbstractString, path2::AbstractString, output_filename::AbstractString="summary.txt")

This function compares the contents of two directories and returns a summary file of the differences
"""
function compare_results(
    path1::AbstractString,
    path2::AbstractString,
    output_filename::AbstractString = "summary.txt",
)
    ## Check that the paths are valid
    if !isdir(path1) || !isdir(path2) || path1 == path2
        println("One or Both of the Paths Doesn't Exist or They are the Same")
    else
        lines_to_write, identical_structure, identical_contents = compare_dir(path1, path2)
        if identical_structure
            println("Structure of $path1 and $path2 is Identical")
        end
        if identical_contents
            println("Contents of $path1 and $path2 is Identical")
        end
        if !identical_structure || !identical_contents
            print_comparison(lines_to_write, output_filename)
        end
    end
end

@doc raw"""
    print_comparison(path1::AbstractString, path2::AbstractString, output_filename::AbstractString="summary.txt")

Takes a string array of differences between two directories and prints them to a file
"""
function print_comparison(
    lines_to_write::Array{Any, 1},
    output_filename::AbstractString = "summary.txt",
)
    ## Create summary file in append mode
    summary_file = open(output_filename, "a")
    write(summary_file, join(lines_to_write))
    close(summary_file)
end

@doc raw"""
    compare_dir(path1::AbstractString, path2::AbstractString)

Compares the contents of two directories and returns a string array of the differences
"""
function compare_dir(path1::AbstractString, path2::AbstractString, inset::String = "")

    ## Excluded file extensions for results comparison
    excluded_exts = [".log", ".lp", ".txt", ".db", ".sqlite", ".sqlite3", "db3", ".s3db", ".sl3"]
    excluded_files = ["settings.csv", "sniffer.csv"]
    excluded = [excluded_exts; excluded_files]

    ## Get the list of files in each directory
    files1 = filter(x -> !any(occursin.(excluded, x)), readdir(path1))
    files2 = filter(x -> !any(occursin.(excluded, x)), readdir(path2))
    dirname1 = split(path1, "\\")[end]
    dirname2 = split(path2, "\\")[end]

    ## Flag denoting whether the structure and contents are identical
    identical_structure = true
    identical_contents = true

    ## Get the list of files that are in both directories
    common_files = intersect(files1, files2)

    ## Get the list of files that are in only one directory
    only1 = setdiff(files1, common_files)
    only2 = setdiff(files2, common_files)

    ## Create a summary file
    lines_to_write = []
    push!(lines_to_write, "$(inset)Comparing the following directories:\n")
    push!(lines_to_write, "$(inset)--- $dirname1 ---\n")
    push!(lines_to_write, "$(inset)--- $dirname2 ---\n")
    push!(lines_to_write, "\n")

    ## Write the summary file
    if length(only1) > 0
        push!(lines_to_write, "$(inset)Files in $dirname1 but not in $dirname2:\n")
        push!(lines_to_write, join([inset, join(only1, "\n$inset")]))
        push!(lines_to_write, "\n")
        identical_structure = false
    end
    if length(only2) > 0
        push!(lines_to_write, "$(inset)Files in $dirname2 but not in $dirname1:\n")
        push!(lines_to_write, join([inset, join(only2, "\n$inset")]))
        push!(lines_to_write, "\n")
        identical_structure = false
    end
    if length(only1) == 0 && length(only2) == 0
        push!(
            lines_to_write,
            "$(inset)Both directories contain the same files and subdirectories\n",
        )
    end
    push!(lines_to_write, "\n")

    common_files_matching = []
    common_files_diff = []
    subdirs = []

    ## Compare the files by byte comparison
    if length(common_files) > 0
        push!(lines_to_write, join([inset, "Files in both $dirname1 and $dirname2:\n"]))
        for file in common_files
            if isfile(joinpath(path1, file)) || isfile(joinpath(path2, file))
                if filecmp(joinpath(path1, file), joinpath(path2, file))
                    push!(common_files_matching, file)
                else
                    push!(common_files_diff, file)
                end
            elseif isdir(joinpath(path1, file)) || isdir(joinpath(path2, file))
                push!(subdirs, file)
            end
        end
        push!(lines_to_write, "\n")
        if length(common_files_matching) > 0
            push!(lines_to_write, join([inset, "Matching result files: \n"]))
            push!(lines_to_write, join([inset, join(common_files_matching, "\n$inset")]))
        else
            push!(lines_to_write, join([inset, "No matching result files"]))
        end
        push!(lines_to_write, "\n")
        push!(lines_to_write, "\n")
        if length(common_files_diff) > 0
            push!(lines_to_write, join([inset, "Mismatched result files: \n"]))
            push!(lines_to_write, join([inset, join(common_files_diff, "\n$inset")]))
            identical_contents = false
        else
            push!(lines_to_write, join([inset, "No mismatched result files"]))
        end
        push!(lines_to_write, "\n")

        if length(subdirs) > 0
            push!(lines_to_write, "\n")
            push!(lines_to_write, join([inset, "Sub-directories"]))
            push!(lines_to_write, "\n")
            for subdir in subdirs
                lines_to_write = [
                    lines_to_write
                    first(
                        compare_dir(
                            joinpath(path1, subdir),
                            joinpath(path2, subdir),
                            join([inset, "  "]),
                        ),
                    )
                ]
            end
            push!(lines_to_write, "\n")
        end
    end
    return lines_to_write, identical_structure, identical_contents
end

@doc raw"""
    filecmp_byte(path1::AbstractString, path2::AbstractString)

Compare two files on a byte-wise basis and return a boolean indicating whether they are identical.
"""
function filecmp_byte(path1::AbstractString, path2::AbstractString)
    stat1, stat2 = stat(path1), stat(path2)
    #? Or should it throw if a file doesn't exist?
    if !(isfile(stat1) && isfile(stat2)) || filesize(stat1) != filesize(stat2)
        return false
    end
    stat1 == stat2 && return true
    open(path1, "r") do file1
        open(path2, "r") do file2
            buf1 = Vector{UInt8}(undef, 32768)
            buf2 = similar(buf1)
            while !eof(file1) && !eof(file2)
                n1 = readbytes!(file1, buf1)
                n2 = readbytes!(file2, buf2)
                n1 != n2 && return false
                0 != Base._memcmp(buf1, buf2, n1) && return false
            end
            return eof(file1) == eof(file2)
        end
    end
end

@doc raw"""
    filecmp_str(path1::AbstractString, path2::AbstractString)

Compares two files at the given paths and returns a boolean indicating whether they are identical.
"""
function filecmp_str(path1::AbstractString, path2::AbstractString)
    open(path1, "r") do file1
        open(path2, "r") do file2
            while !eof(file1) && !eof(file2)
                line1 = readline(file1)
                line2 = readline(file2)
                if line1 != line2
                    return false
                end
            end
            return eof(file1) == eof(file2)
        end
    end
end

@doc raw"""
    filecmp(path1::AbstractString, path2::AbstractString)

Compares two paths and returns a boolean indicating whether they are identical.
"""
function filecmp(path1::AbstractString, path2::AbstractString)
    ## First do quick (but slightly temperamental) byte comparison
    ## If that fails, do a line-by-line comparison
    if filecmp_byte(path1, path2)
        return true
    else
        if filecmp_str(path1, path2)
            return true
        else
            return false
        end
    end
end
