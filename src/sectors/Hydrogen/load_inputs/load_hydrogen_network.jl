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
    load_hydrogen_network(path::AbstractString, hydrogen_settings::Dict, inputs::Dict)

Function for reading input parameters related to the hydrogen transmission network via pipelines.
"""
function load_hydrogen_network(path::AbstractString, hydrogen_settings::Dict, inputs::Dict)

    ## Flags
    NetworkExpansion = hydrogen_settings["NetworkExpansion"]

    ## Number of zones in the network
    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Hydrogen sector inputs dictionary
    hydrogen_inputs = inputs["HydrogenInputs"]

    ## Network zones inputs and Network topology inputs
    path = joinpath(path, hydrogen_settings["NetworkPath"])
    dfPipe = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter pipelines which links zones not modelled and drop those having same start and end
    dfPipe = filter(
        row -> (row.Start_Zone in Zones && row.End_Zone in Zones && row.Start_Zone != row.End_Zone),
        dfPipe,
    )

    ## Filter pipelines which are specified by pipeline types
    if haskey(hydrogen_settings, "PipeSet") && !in("All", hydrogen_settings["PipeSet"])
        ## Exclude some pipelines from dataframe using "!"
        excluded = filter(x -> startswith(x, "!"), hydrogen_settings["PipeSet"])
        dfPipe = filter(row -> !(row.Pipe_Type in chop.(excluded, head = 1, tail = 0)), dfPipe)
        ## Filter some pipelines from dataframe after exclusion
        included = setdiff(hydrogen_settings["PipeSet"], excluded)
        if !isempty(included)
            dfPipe = filter(row -> row.Pipe_Type in included, dfPipe)
        end
    end

    ## Add a new column to the dfPipe dataframe to store the line index
    dfPipe[!, :P_ID] = 1:size(dfPipe, 1)

    ## Number of pipelines in the network
    hydrogen_inputs["P"] = size(collect(skipmissing(dfPipe[!, :P_ID])), 1)
    P = hydrogen_inputs["P"]

    dfPipe[!, :Booster_Stations_Number] =
        floor.(Int64, dfPipe[!, :Pipe_Length_miles] ./ dfPipe[!, :Distance_bw_Booster_miles])

    dfPipe[!, :Max_Storage_Cap] =
        dfPipe[!, :Pipe_Storage_Cap_tonne_per_mile] .* dfPipe[!, :Distance_bw_Booster_miles]

    dfPipe[!, :Min_Storage_Cap] =
        dfPipe[!, :Min_Pipe_Storage_Percentage] .* dfPipe[!, :Max_Storage_Cap]

    ## Calculate AF for each pipeline
    dfPipe[!, :AF] = dfPipe[!, :WACC] ./ (1 .- (1 .+ dfPipe[!, :WACC]) .^ (-dfPipe[!, :Lifetime]))

    ## Store pipeline dataframe for later use in model
    hydrogen_inputs["dfPipe"] = dfPipe

    ## Topology of the pipeline network source-sink matrix
    Pipe_map = zeros(Int64, P, Z)

    for p in 1:P
        z_start = indexin([dfPipe[!, :Start_Zone][p]], Zones)[1]
        z_end = indexin([dfPipe[!, :End_Zone][p]], Zones)[1]
        Pipe_map[p, z_start] = 1
        Pipe_map[p, z_end] = -1
    end

    Pipe_map = DataFrame(Pipe_map, Symbol.(Zones))

    ## Create pipe number column
    Pipe_map[!, :pipe_no] = 1:size(Pipe_map, 1)

    ## Pivot table
    Pipe_map = stack(Pipe_map, Zones)

    ## Remove redundant rows
    Pipe_map = Pipe_map[Pipe_map[!, :value] .!= 0, :]

    ## Rename column
    colnames_pipe_map = ["pipe_no", "Zone", "d"]
    rename!(Pipe_map, Symbol.(colnames_pipe_map))

    hydrogen_inputs["Pipe_map"] = Pipe_map

    ## Expansional pipelines
    if NetworkExpansion == -1
        hydrogen_inputs["NEW_PIPES"] = Inf64[]
    elseif NetworkExpansion == 0
        hydrogen_inputs["NEW_PIPES"] = dfPipe[dfPipe.New_Build .== 1, :P_ID]
    elseif NetworkExpansion == 1
        hydrogen_inputs["NEW_PIPES"] = 1:P
    end
    hydrogen_inputs["NEW_PIPES"] = intersect(
        hydrogen_inputs["NEW_PIPES"],
        union(
            dfPipe[dfPipe.Max_Pipe_Number .== -1, :P_ID],
            intersect(
                dfPipe[dfPipe.Max_Pipe_Number .!= -1, :P_ID],
                dfPipe[dfPipe.Max_Pipe_Number .- dfPipe.Existing_Pipe_Number .> 0, :P_ID],
            ),
        ),
    )

    print_and_log(
        hydrogen_settings,
        "i",
        "Transmission via Pipeline Data Successfully Read from $path",
    )

    inputs["HydrogenInputs"] = hydrogen_inputs

    return inputs
end
