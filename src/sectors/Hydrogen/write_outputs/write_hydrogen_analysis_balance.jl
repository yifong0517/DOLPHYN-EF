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
function write_hydrogen_analysis_balance(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 1
        print_and_log(settings, "i", "Writing Hydrogen Sector Balance Analysis")

        save_path = settings["SavePath"]

        hydrogen_settings = settings["HydrogenSettings"]
        ModelStorage = hydrogen_settings["ModelStorage"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]

        hydrogen_inputs = inputs["HydrogenInputs"]
        GenResourceType = hydrogen_inputs["GenResourceType"]
        if ModelStorage == 1
            StoResourceType = hydrogen_inputs["StoResourceType"]
        end

        temp_gen_bal = transpose(value.(MESS[:eHGenORTT]).data)
        if ModelStorage == 1
            temp_sto_dis = transpose(value.(MESS[:eHStoDisORTT]).data)
            temp_sto_cha = transpose(value.(MESS[:eHStoChaORTT]).data)
        end
        temp_demand = vec(sum(hydrogen_inputs["D"]; dims = 1))
        temp_demand_addition = vec(sum(value.(MESS[:eHDemandAddition]); dims = 1))
        ## Temporal balance of each resource type
        dfBalance = DataFrame(Time = 1:T)

        ## Temporal balance of discharge
        dfBalance = hcat(dfBalance, DataFrame(round.(temp_gen_bal; digits = 2), :auto))
        rename!(dfBalance, ["Time"; GenResourceType])
        if ModelStorage == 1
            dfBalance = hcat(dfBalance, DataFrame(round.(temp_sto_dis; digits = 2), :auto))
            rename!(dfBalance, ["Time"; GenResourceType; StoResourceType .* " Discharge"])
        end

        ## Temporal balance of demand
        dfBalance = hcat(dfBalance, DataFrame(Demand = round.(temp_demand; digits = 2)))
        dfBalance =
            hcat(dfBalance, DataFrame(AdditionalDemand = round.(temp_demand_addition; digits = 2)))

        ## Temporal balance of charge
        if ModelStorage == 1
            dfBalance = hcat(dfBalance, DataFrame(round.(temp_sto_cha; digits = 2), :auto))
            rename!(
                dfBalance,
                [
                    "Time"
                    GenResourceType
                    StoResourceType .* " Discharge"
                    "Demand"
                    "AdditionalDemand"
                    StoResourceType .* " Charge"
                ],
            )
        end

        CSV.write(joinpath(save_path, "Analysis", "sector_hydrogen_balance.csv"), dfBalance)
    end
end
