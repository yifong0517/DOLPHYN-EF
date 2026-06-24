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
function generate_save_path(
    modifications::DataFrame,
    uncertainty::AbstractDict{Any, Any},
    delimiter::AbstractString,
)

    ## Parse uncertainty sources
    uncertainty_sources = collect(keys(uncertainty))

    ## Abbreviate uncertainty sources
    abbr = Dict(
        uncertainty_sources .=> [
            join(first.(split(uncertainty_source, delimiter)), delimiter) for
            uncertainty_source in uncertainty_sources
        ],
    )

    ## Combine uncertainty sources with delimiter to generate save paths
    save_path = [
        string(
            "Results",
            delimiter,
            join(
                reduce(vcat, [[abbr[name], round(row[name]; digits = 2)] for name in names(row)]),
                delimiter,
            ),
        ) for row in eachrow(modifications[!, Symbol.(uncertainty_sources)])
    ]

    ## Add save path column to modifications
    insertcols!(modifications, 1, :SavePath => save_path)

    return modifications
end
