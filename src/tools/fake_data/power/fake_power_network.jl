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
    fake_power_network(path::AbstractString, zones::Integer)

This function fakes an imaginary power network from nowhere.
"""
function fake_power_network(path::AbstractString, zones::Integer)

    ## Compute factorial number
    lines = binomial(zones, 2)

    ## Generate zone list
    Zones = string.(1:zones)

    ## Lines parameters
    df_lines = DataFrame(
        Path_Name = 1:lines,
        Existing_Line_Cap_MW = zeros(lines),
        New_Build = ones(lines),
        Max_Line_Cap_MW = round.(rand(lines) .* 1000),
        Line_Inv_Cost_per_MW = rand(lines) .* 10000,
        Lifetime = round.(rand(lines) .* 20) .+ 5,
        WACC = ones(lines) .* 0.07,
        Distance_miles = rand(lines) .* 100,
        Line_Max_Reinforcement_MW = round.(rand(lines) .* 1000),
        Line_Loss_Percentage = rand(lines) ./ 100,
        Line_Reinforcement_Cost_per_MWyr = rand(lines) .* 10000,
    )

    ## Lines map
    df_lines_map = DataFrame(Start_Zone = String[], End_Zone = String[])
    lines_map = collect(Combinatorics.combinations(Zones, 2))
    for l in 1:lines
        push!(df_lines_map, lines_map[l])
    end

    ## Merge lines map into lines parameter dataframe
    df_lines = hcat(df_lines, df_lines_map)

    ## Construct static line parameter dataframe
    df_lines_static = DataFrame(
        Line_Voltage_kV = repeat([230], lines),
        Line_Resistance_ohms = repeat([1.234], lines),
        Line_X_ohms = repeat([1.234], lines),
        Line_R_ohms = repeat([1.234], lines),
        Thetha_max = repeat([1.5], lines),
        Peak_Withdrawal_Hours = repeat(["All"], lines),
        Peak_Injection_Hours = repeat(["all"], lines),
    )

    ## Merge static line parameters dataframe into lines parameters dataframe
    df_lines = hcat(df_lines, df_lines_static)

    ## Write lines parameters dataframe into csv file
    CSV.write(joinpath(path, "Network.csv"), df_lines)
end
