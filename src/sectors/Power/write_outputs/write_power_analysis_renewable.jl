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
function write_power_analysis_renewable(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 1
        print_and_log(settings, "i", "Writing Power Sector Renewable Analysis")

        save_path = settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        power_inputs = inputs["PowerInputs"]
        HYDRO = power_inputs["HYDRO"]
        VRE = power_inputs["VRE"]
        MUST_RUN = power_inputs["MUST_RUN"]

        ## Zonal generation of renewable
        temp_generation = value.(MESS[:ePGeneration])
        if !isempty(HYDRO)
            temp_hydro = value.(MESS[:ePBalanceHydro])
            temp_available_hydro = value.(MESS[:ePAvailableHydro])
        end
        if !isempty(VRE)
            temp_variable = value.(MESS[:ePBalanceVRE])
            temp_available_variable = value.(MESS[:ePAvailableVRE])
        end
        if !isempty(MUST_RUN)
            temp_must_run = value.(MESS[:ePBalanceMustRun])
        end

        dfRenewable = DataFrame(
            Zone = Zones,
            Generation = round.(vec(sum(temp_generation; dims = 2)); digits = 2),
            Available = zeros(Z),
            Renewable = zeros(Z),
        )

        if !isempty(HYDRO)
            dfRenewable[!, "AvailableHydro"] =
                round.(vec(sum(temp_available_hydro; dims = 2)); digits = 2)
            dfRenewable[!, "Hydro"] = round.(vec(sum(temp_hydro; dims = 2)); digits = 2)
            dfRenewable[!, "Available"] .+= dfRenewable[!, "AvailableHydro"]
            dfRenewable[!, "Renewable"] .+= dfRenewable[!, "Hydro"]
        end
        if !isempty(VRE)
            dfRenewable[!, "AvailableVariable"] =
                round.(vec(sum(temp_available_variable; dims = 2)); digits = 2)
            dfRenewable[!, "Variable"] = round.(vec(sum(temp_variable; dims = 2)); digits = 2)
            dfRenewable[!, "Available"] .+= dfRenewable[!, "AvailableVariable"]
            dfRenewable[!, "Renewable"] .+= dfRenewable[!, "Variable"]
        end
        if !isempty(MUST_RUN)
            dfRenewable[!, "MustRun"] = round.(vec(sum(temp_must_run; dims = 2)); digits = 2)
            dfRenewable[!, "Available"] .+= dfRenewable[!, "MustRun"]
            dfRenewable[!, "Renewable"] .+= dfRenewable[!, "MustRun"]
        end

        dfRenewable[!, "Curtailment"] = dfRenewable[!, "Available"] - dfRenewable[!, "Renewable"]
        dfRenewable[!, "Renewable Penetration"] =
            dfRenewable[!, "Renewable"] ./ dfRenewable[!, "Generation"]
        dfRenewable[!, "Curtailment Rate"] =
            dfRenewable[!, "Curtailment"] ./ dfRenewable[!, "Available"]

        CSV.write(joinpath(save_path, "Analysis", "sector_power_renewable.csv"), dfRenewable)
    end
end
