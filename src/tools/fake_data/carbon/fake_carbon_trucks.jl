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
    fake_carbon_trucks(path::AbstractString, zones::Integer, trucks::AbstractVector{String})

This function fakes carbon trucks data from nowhere.
"""
function fake_carbon_trucks(path::AbstractString, zones::Integer, trucks::AbstractVector{String})
    ## Generate zone list
    Zones = string.(1:zones)

    truck_types = length(trucks)

    ## Trucks parameters
    df_trucks = DataFrame(Truck_Type = trucks, Existing_Number = zeros(truck_types))

    for z in Zones
        df_trucks[!, Symbol("Existing_Comp_Cap_tonne_$z")] = zeros(truck_types)
    end

    df_parameters = DataFrame(
        Inv_Cost_Truck_per_unit = rand(truck_types) .* 1200000,
        Truck_Lifetime = ceil.(round.(rand(truck_types) .* 15)),
        Truck_WACC = ones(truck_types) .* 0.07,
        Fixed_OM_Cost_Truck_Percentage = round.(rand(truck_types) ./ 4, sigdigits = 2),
        Trailer_Number = ones(Int64, truck_types),
        Inv_Cost_Trailer_per_number = rand(truck_types) .* 100000,
        Trailer_Lifetime = ceil.(round.(rand(truck_types) .* 15)),
        Trailer_WACC = ones(truck_types) .* 0.07,
        Fixed_OM_Cost_Trailer_Percentage = round.(rand(truck_types) ./ 4, sigdigits = 2),
        Cap_tonne_per_trailer = rand(truck_types) .* 5,
        Inv_Cost_Comp_per_tonne_per_hr = rand(truck_types) .* 40000000,
        Comp_Lifetime = ceil.(round.(rand(truck_types) .* 15)),
        Comp_WACC = ones(truck_types) .* 0.07,
        Fixed_OM_Cost_Comp_Percentage = zeros(Int64, truck_types),
        Truck_Comp_Energy_MWh_per_tonne = rand(truck_types) .* 15,
        Truck_Comp_Unit_Opex_per_tonne = rand(truck_types) .* 10,
        Max_Comp_Cap_tonne = repeat([-1], truck_types),
        Min_Comp_Cap_tonne = zeros(truck_types),
        Empty_Weight_tonne_per_unit = repeat([10], truck_types),
        Var_OM_Cost_Full_per_mile = rand(truck_types) .* 5,
        Var_OM_Cost_Empty_per_mile = rand(truck_types) .* 5,
        Loss_Percentage_per_mile = rand(truck_types) ./ 100,
        Unloading_Time = ones(Int64, truck_types),
        Loading_Time = ones(Int64, truck_types),
        Avg_Truck_Speed_mile_per_hour = rand(truck_types) .* 40,
        Fuel = repeat(["natural_gas"], truck_types),
        Fuel_MMBTU_per_mile = rand(truck_types) .* 5,
        Electricity = repeat(["None"], truck_types),
        Electricity_MWh_per_mile = zeros(truck_types),
        Hydrogen = repeat(["None"], truck_types),
        H2_tonne_per_mile = zeros(truck_types),
    )

    ## Merge truck parameters into truck dataframe
    df_trucks = hcat(df_trucks, df_parameters)

    ## Write truck parameters dataframe into csv file
    CSV.write(joinpath(path, "Trucks.csv"), df_trucks)
end
