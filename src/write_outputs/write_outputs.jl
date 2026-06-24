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
function write_outputs(settings::Dict, inputs::Dict, MESS::Model)

    status = termination_status(MESS)

    if settings["Write"] == 1
        save_path = settings["SavePath"]

        print_and_log(settings, "i", "Writing Outputs to $save_path")

        ## Check whether the model is solved
        if !(status in [MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.ALMOST_LOCALLY_SOLVED])
            ## Infeasible status sets
            if status in [
                MOI.INFEASIBLE,
                MOI.DUAL_INFEASIBLE,
                MOI.LOCALLY_INFEASIBLE,
                MOI.INFEASIBLE_OR_UNBOUNDED,
                MOI.ALMOST_INFEASIBLE,
                MOI.ALMOST_DUAL_INFEASIBLE,
            ]
                print_and_log(settings, "w", "Model is Infeasible with Type of $status")
                ## Limit status sets
            elseif status in [
                MOI.ITERATION_LIMIT,
                MOI.TIME_LIMIT,
                MOI.NODE_LIMIT,
                MOI.SOLUTION_LIMIT,
                MOI.MEMORY_LIMIT,
                MOI.OBJECTIVE_LIMIT,
                MOI.NORM_LIMIT,
            ]
                print_and_log(settings, "w", "Model is Limited with Type of $status")
                ## Invalid status sets
            elseif status in [MOI.NUMERICAL_ERROR, MOI.INVALID_MODEL, MOI.INVALID_OPTION]
                print_and_log(settings, "w", "Model is Invalid with Type of $status")
                ## Interrupted solving process
            elseif status == MOI.INTERRUPTED
                print_and_log(settings, "w", "Model Solving Process is Interrupted")
                ## Other error typs
            elseif status in [MOI.OTHER_ERROR, MOI.OTHER_LIMIT]
                print_and_log(
                    settings,
                    "w",
                    "Model Solving Fails for Unknown Reasons. Please Report.",
                )
            end
            ## Soft landing for solving process
            return status
        end

        ## Write settings
        write_settings(settings)

        ## Write fuels consumption
        if settings["ModelFuels"] == 1
            write_fuels_consumption(settings, inputs, MESS)
        end

        ## Write electricity consumption
        if !(settings["ModelPower"] == 1)
            write_electricity_consumption(settings, inputs, MESS)
        end

        ## Write hydrogen consumption
        if !(settings["ModelHydrogen"] == 1)
            write_hydrogen_consumption(settings, inputs, MESS)
        end

        ## Write carbon consumption
        if !(settings["ModelCarbon"] == 1)
            write_carbon_consumption(settings, inputs, MESS)
        end

        ## Write bioenergy consumption
        if !(settings["ModelBioenergy"] == 1)
            write_bioenergy_consumption(settings, inputs, MESS)
        end

        ## Write expenses for purchasing feedstocks from markets
        write_expenses(settings, inputs, MESS)

        ## Write emissions
        write_emissions(settings, inputs, MESS)

        ## Write emissions composition
        write_emissions_composition(settings, inputs, MESS)

        ## Write captured carbon
        write_captured_carbon(settings, inputs, MESS)

        ## Write captured carbon disposal costs
        if settings["ModelCarbon"] == 0 &&
           haskey(settings, "CO2Disposal") &&
           settings["CO2Disposal"] >= 1
            write_captured_carbon_disposal_costs(settings, inputs, MESS)
        end

        if settings["WriteAnalysis"] == 1
            ## Create analysis folder
            if !isdir(joinpath(settings["SavePath"], "Analysis"))
                mkdir(joinpath(settings["SavePath"], "Analysis"))
            end
            ## Write sectorial results balance analysis
            write_sector_analysis_balance(settings, inputs, MESS)

            ## Write sectorial results generation analysis
            write_sector_analysis_generation(settings, inputs, MESS)
        end

        ## Write power sector outputs
        if settings["ModelPower"] == 1
            power_settings = settings["PowerSettings"]
            power_save_path = joinpath(save_path, "Power")
            power_settings["SavePath"] = power_save_path
            settings["PowerSettings"] = power_settings
            write_power_outputs(settings, inputs, MESS)
        end

        ## Write hydrogen sector outputs
        if settings["ModelHydrogen"] == 1
            hydrogen_settings = settings["HydrogenSettings"]
            hydrogen_save_path = joinpath(save_path, "Hydrogen")
            hydrogen_settings["SavePath"] = hydrogen_save_path
            settings["HydrogenSettings"] = hydrogen_settings
            write_hydrogen_outputs(settings, inputs, MESS)
        end

        ## Write Carbon sector outputs
        if settings["ModelCarbon"] == 1
            carbon_settings = settings["CarbonSettings"]
            carbon_save_path = joinpath(save_path, "Carbon")
            carbon_settings["SavePath"] = carbon_save_path
            settings["CarbonSettings"] = carbon_settings
            write_carbon_outputs(settings, inputs, MESS)
        end

        ## Write synfuels sector outputs
        if settings["ModelSynfuels"] == 1
            synfuels_settings = settings["SynfuelsSettings"]
            synfuels_save_path = joinpath(save_path, "Synfuels")
            synfuels_settings["SavePath"] = synfuels_save_path
            settings["SynfuelsSettings"] = synfuels_settings
            write_synfuels_outputs(settings, inputs, MESS)
        end

        ## Write ammonia sector outputs
        if settings["ModelAmmonia"] == 1
            ammonia_settings = settings["AmmoniaSettings"]
            ammonia_save_path = joinpath(save_path, "Ammonia")
            ammonia_settings["SavePath"] = ammonia_save_path
            settings["AmmoniaSettings"] = ammonia_settings
            write_ammonia_outputs(settings, inputs, MESS)
        end

        ## Write foodstuff sector outputs
        if settings["ModelFoodstuff"] == 1
            foodstuff_settings = settings["FoodstuffSettings"]
            foodstuff_save_path = joinpath(save_path, "Foodstuff")
            foodstuff_settings["SavePath"] = foodstuff_save_path
            settings["FoodstuffSettings"] = foodstuff_settings
            write_foodstuff_outputs(settings, inputs, MESS)
        end

        ## Write bioenergy sector outputs
        if settings["ModelBioenergy"] == 1
            bioenergy_settings = settings["BioenergySettings"]
            bioenergy_save_path = joinpath(save_path, "Bioenergy")
            bioenergy_settings["SavePath"] = bioenergy_save_path
            settings["BioenergySettings"] = bioenergy_settings
            write_bioenergy_outputs(settings, inputs, MESS)
        end

        ## Write sniffer
        if settings["SnifferFile"] != ""
            sniffer = dynamic_sniffers(settings, inputs, MESS)
            write_sniffer(joinpath(settings["SavePath"], settings["SnifferFile"]), sniffer)
        end

        print_and_log(settings, "i", "Writing Outputs to $save_path is Done")
    else
        ## Add garbege collection safe point
        GC.safepoint()
        sleep(2)
        print_and_log(settings, "w", "Writing Outputs is Disabled")
    end

    if status in [MOI.OPTIMAL, MOI.LOCALLY_SOLVED, MOI.ALMOST_LOCALLY_SOLVED]
        return value(MESS[:eObj])
    else
        return NaN64
    end
end
