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
    load_power_network(path::AbstractString, power_settings::Dict, inputs::Dict)

Function for reading input parameters related to the electricity transmission network.
"""
function load_power_network(path::AbstractString, power_settings::Dict, inputs::Dict)

    ## Flags
    NetworkExpansion = power_settings["NetworkExpansion"]
    LineLossSegments = power_settings["LineLossSegments"]

    ## Number of zones in the network
    Z = inputs["Z"]
    Zones = inputs["Zones"]

    ## Power sector inputs dictionary
    power_inputs = inputs["PowerInputs"]

    ## Network zones inputs and Network topology inputs
    path = joinpath(path, power_settings["NetworkPath"])
    dfLine = DataFrame(CSV.File(path, header = true), copycols = true)

    ## Filter lines which links zones not modelled and drop those having same start and end
    dfLine = filter(
        row -> ((
            row.Start_Zone in Zones && row.End_Zone in Zones && row.Start_Zone != row.End_Zone
        )),
        dfLine,
    )

    ## Filter lines which are specified by line types
    if haskey(power_settings, "LineSet") && !in("All", power_settings["LineSet"])
        ## Exclude some lines from dataframe using "!"
        excluded = filter(x -> startswith(x, "!"), power_settings["LineSet"])
        dfLine = filter(row -> !(row.Line_Type in chop.(excluded, head = 1, tail = 0)), dfLine)
        ## Filter some lines from dataframe after exclusion
        included = setdiff(power_settings["LineSet"], excluded)
        if !isempty(included)
            dfLine = filter(row -> row.Line_Type in included, dfLine)
        end
    end

    ## Add a new column to the dfLine dataframe to store the line index
    dfLine[!, :L_ID] = 1:size(dfLine, 1)

    ## Calculate AF for each line
    dfLine[!, :AF] = dfLine[!, :WACC] ./ (1 .- (1 .+ dfLine[!, :WACC]) .^ (-dfLine[!, :Lifetime]))

    ## Number of lines in the network
    power_inputs["L"] = size(collect(skipmissing(dfLine[!, :L_ID])), 1)
    L = power_inputs["L"]

    ## Topology of the network source-sink matrix
    Network_map = zeros(L, Z)

    for l in 1:L
        z_start = indexin([dfLine[!, :Start_Zone][l]], Zones)[1]
        z_end = indexin([dfLine[!, :End_Zone][l]], Zones)[1]
        Network_map[l, z_start] = 1
        Network_map[l, z_end] = -1
    end

    power_inputs["Network_map"] = Network_map

    ## Maximum possible flow after reinforcement for use in linear segments of piecewise approximation
    dfLine[!, :Trans_Max_Possible] = zeros(Float64, L)

    if NetworkExpansion == -1
        power_inputs["NEW_LINES"] = Int64[]
        dfLine[!, :Line_Max_Reinforcement_MW] .= 0
    elseif NetworkExpansion == 0
        power_inputs["NEW_LINES"] = intersect(
            dfLine[dfLine.New_Build .== 1, :L_ID],
            dfLine[dfLine.Line_Max_Reinforcement_MW .> 0, :L_ID],
        )
    elseif NetworkExpansion == 1
        power_inputs["NEW_LINES"] =
            intersect(1:L, dfLine[dfLine.Line_Max_Reinforcement_MW .> 0, :L_ID])
    end
    power_inputs["NEW_LINES"] = intersect(
        power_inputs["NEW_LINES"],
        union(
            dfLine[dfLine.Max_Line_Cap_MW .== -1, :L_ID],
            intersect(
                dfLine[dfLine.Max_Line_Cap_MW .!= -1, :L_ID],
                dfLine[dfLine.Max_Line_Cap_MW .- dfLine.Existing_Line_Cap_MW .> 0, :L_ID],
            ),
        ),
    )

    for l in 1:L
        if dfLine[!, :Line_Max_Reinforcement_MW][l] > 0
            dfLine[!, :Trans_Max_Possible][l] =
                dfLine[!, :Max_Line_Cap_MW][l] + dfLine[!, :Line_Max_Reinforcement_MW][l]
        else
            dfLine[!, :Trans_Max_Possible][l] = dfLine[!, :Max_Line_Cap_MW][l]
        end
    end

    ## Transmission line (between zone) loss coefficient (resistance/voltage^2)
    dfLine[!, :Trans_Loss_Coef] = zeros(Float64, L)
    for l in 1:L
        ## For cases with only one segment
        if LineLossSegments == 1
            dfLine[!, :Trans_Loss_Coef][l] = dfLine[!, :Line_Loss_Percentage][l]
        elseif LineLossSegments >= 2
            dfLine[!, :Trans_Loss_Coef][l] =
                (dfLine[!, :Line_Resistance_ohms][l] / 10^6) /
                (dfLine[!, :Line_Voltage_kV][l] / 10^3)^2 # 1/MW
        end
    end

    ## DC OPF coefficient
    if power_settings["DCPowerFlow"] == 1
        dfLine[!, :DC_OPF_coeff] =
            dfLine[!, :Line_Voltage_kV] .^ 2 ./ dfLine[!, :Line_Resistance_ohms]
    end

    ## Store DataFrame of line input data for use in model
    power_inputs["dfLine"] = dfLine

    ## Sets and indices for transmission losses and expansion
    power_inputs["TRANS_LOSS_SEGS"] = LineLossSegments # Number of segments used in piecewise linear approximations quadratic loss functions
    power_inputs["LOSS_LINES"] = dfLine[dfLine.Trans_Loss_Coef .!= 0, :L_ID] # Lines for which loss coefficients apply (are non-zero);

    print_and_log(power_settings, "i", "Transmission Line Data Successfully Read from $path")

    inputs["PowerInputs"] = power_inputs

    return inputs
end
