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
    fake_carbon_pipelines(path::AbstractString, zones::Integer)

This function fakes a imaginary carbon pipelines from nowhere.
"""
function fake_carbon_pipelines(path::AbstractString, zones::Integer)

    ## Compute factorial number
    lines = binomial(zones, 2)

    ## Generate zone list
    Zones = string.(1:zones)

    ## Lines parameters
    df_lines = DataFrame(
        Max_Pipe_Number = repeat([20], lines),
        Existing_Pipe_Number = zeros(lines),
        Max_Flow_tonne_per_hr = rand(lines) .* 200,
        Pipe_Inv_Cost_per_mile = rand(lines) .* 25000,
        Lifetime = ceil.(rand(lines) .* 30) .+ 6,
        WACC = ones(lines) .* 0.07,
        Pipe_Length_miles = rand(lines) .* 200,
        Pipe_Storage_Cap_tonne_per_mile = rand(lines) .* 5,
        Min_Pipe_Storage_Percentage = rand(lines),
        Distance_bw_Booster_miles = rand(lines) .* 100,
        Booster_Capex_per_tonne_p_hr_yr = rand(lines) .* 50000,
        Booster_Comp_Energy_MWh_per_tonne = rand(lines),
        Pipe_Comp_Capex = rand(lines) .* 50000,
        Electricity = repeat(["Electricity_solar_1"], lines),
        Pipe_Comp_Energy = rand(lines) .* 5,
    )

    ## Lines map
    df_lines_map = DataFrame(Start_Zone = String[], End_Zone = String[])
    lines_map = collect(Combinatorics.combinations(Zones, 2))
    for l in 1:lines
        push!(df_lines_map, lines_map[l])
    end

    ## Merge lines map into lines parameter dataframe
    df_lines = hcat(df_lines, df_lines_map)

    ## Write lines parameters dataframe into csv file
    CSV.write(joinpath(path, "Netwrok.csv"), df_lines)
end
