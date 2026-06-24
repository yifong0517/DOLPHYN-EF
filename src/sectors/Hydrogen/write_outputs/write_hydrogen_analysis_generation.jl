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
function write_hydrogen_analysis_generation(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 1
        print_and_log(settings, "i", "Writing Hydrogen Sector Generation Analysis")

        save_path = settings["SavePath"]

        hydrogen_settings = settings["HydrogenSettings"]
        ModelStorage = hydrogen_settings["ModelStorage"]

        Zones = inputs["Zones"]

        hydrogen_inputs = inputs["HydrogenInputs"]
        GenResourceType = hydrogen_inputs["GenResourceType"]
        if ModelStorage == 1
            StoResourceType = hydrogen_inputs["StoResourceType"]
        end

        ## Zonal capacity of each resource type
        temp_gen_cap = value.(MESS[:eHGenCapOZRT]).data
        if ModelStorage == 1
            temp_sto_cap = value.(MESS[:eHStoCapOZRT]).data
        end
        dfCapacity = DataFrame(Zone = Zones)

        if ModelStorage == 1
            dfCapacity = hcat(
                dfCapacity,
                DataFrame(round.(hcat(temp_gen_cap, temp_sto_cap); digits = 2), :auto),
            )
        else
            dfCapacity = hcat(dfCapacity, DataFrame(round.(temp_gen_cap; digits = 2), :auto))
        end

        peak_demand = vec(maximum(value.(MESS[:eHDemand]); dims = 2))
        peak_inputs_demand = vec(hydrogen_inputs["D"][argmax(value.(MESS[:eHDemand]); dims = 2)])
        peak_addition_demand =
            vec(value.(MESS[:eHDemandAddition])[argmax(value.(MESS[:eHDemand]); dims = 2)])
        dfCapacity = hcat(
            dfCapacity,
            DataFrame(
                Peak_Demand = round.(peak_demand; digits = 2),
                Peak_Inputs_Demand = round.(peak_inputs_demand; digits = 2),
                Peak_Addition_Demand = round.(peak_addition_demand; digits = 2),
            ),
        )

        if ModelStorage == 1
            names = vcat(
                ["Zones"],
                GenResourceType,
                StoResourceType,
                ["Peak Demand", "Peak Inputs Demand", "Peak Addition Demand"],
            )
        else
            names = vcat(
                ["Zones"],
                GenResourceType,
                ["Peak Demand", "Peak Inputs Demand", "Peak Addition Demand"],
            )
        end
        rename!(dfCapacity, Symbol.(names))

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(dfCapacity, settings["DB"], "HydrogenCapacity")
        end

        ## Global capacity of each resource type
        total = Any["Total"]
        total = hcat(total, round.(sum(temp_gen_cap; dims = 1); digits = 2))
        if ModelStorage == 1
            total = hcat(total, round.(sum(temp_sto_cap; dims = 1); digits = 2))
        end
        total = hcat(total, round.(maximum(sum(value.(MESS[:eHDemand]); dims = 1)); digits = 2))
        total = hcat(total, round.(maximum(sum(hydrogen_inputs["D"]; dims = 1)); digits = 2))
        total =
            hcat(total, round.(maximum(sum(value.(MESS[:eHDemandAddition]); dims = 1)); digits = 2))
        push!(dfCapacity, total)

        ## CSV writing
        CSV.write(joinpath(save_path, "Analysis", "sector_hydrogen_capacity.csv"), dfCapacity)

        ## Zonal generation of each resource type
        temp_generation = value.(MESS[:eHGenOZRT]).data
        if ModelStorage == 1
            temp_discharge = value.(MESS[:eHStoDisOZRT]).data
            temp_loss = value.(MESS[:eHStoEneLossOZRT]).data
        end
        dfGeneration = DataFrame(Zone = Zones)

        if ModelStorage == 1
            dfGeneration = hcat(
                dfGeneration,
                DataFrame(
                    round.(hcat(temp_generation, temp_discharge, temp_loss); digits = 2),
                    :auto,
                ),
            )
        else
            dfGeneration = hcat(dfGeneration, DataFrame(round.(temp_generation; digits = 2), :auto))
        end

        total_demand = vec(sum(value.(MESS[:eHDemand]); dims = 2))
        total_inputs_demand = vec(sum(hydrogen_inputs["D"]; dims = 2))
        total_addition_demand = vec(sum(value.(MESS[:eHDemandAddition]); dims = 2))

        dfGeneration = hcat(
            dfGeneration,
            DataFrame(
                Total_Demand = round.(total_demand; digits = 2),
                Total_Inputs_Demand = round.(total_inputs_demand; digits = 2),
                Total_Addition_Demand = round.(total_addition_demand; digits = 2),
            ),
        )

        if ModelStorage == 1
            names = vcat(
                ["Zones"],
                GenResourceType,
                StoResourceType .* "_Discharge",
                StoResourceType .* "_Loss",
                ["Total Demand", "Total Inputs Demand", "Total Addition Demand"],
            )
        else
            names = vcat(
                ["Zones"],
                GenResourceType,
                ["Total Demand", "Total Inputs Demand", "Total Addition Demand"],
            )
        end
        rename!(dfGeneration, Symbol.(names))

        ## Database writing
        if haskey(settings, "DB")
            SQLite.load!(dfGeneration, settings["DB"], "HydrogenGeneration")
        end

        ## Global generation of each resource type
        total = Any["Total"]
        total = hcat(total, round.(sum(temp_generation; dims = 1); digits = 2))
        if ModelStorage == 1
            total = hcat(total, round.(sum(temp_discharge; dims = 1); digits = 2))
            total = hcat(total, round.(sum(temp_loss; dims = 1); digits = 2))
        end
        total = hcat(total, round.(sum(value.(MESS[:eHDemand])); digits = 2))
        total = hcat(total, round.(sum(hydrogen_inputs["D"]); digits = 2))
        total = hcat(total, round.(sum(value.(MESS[:eHDemandAddition])); digits = 2))
        push!(dfGeneration, total)

        ## CSV writing
        CSV.write(joinpath(save_path, "Analysis", "sector_hydrogen_generation.csv"), dfGeneration)
    end
end
