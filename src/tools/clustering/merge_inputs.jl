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
function merge_inputs(settings::Dict, inputs::Dict)

    ## Modeled zones list
    Zones = settings["Zones"]

    ## Construct feature dataframe from sector inputs
    profiles = DataFrame(Time_Index = inputs["Time_Index"])

    ## Merge raw feedstock materials prices
    profiles = merge_feedstock_prices(profiles, inputs)

    ## Obtain power sector inputs
    if settings["ModelPower"] == 1
        power_inputs = inputs["PowerInputs"]
        profiles = merge_power_inputs(profiles, power_inputs, Zones)
    end

    ## Obtain hydrogens sector inputs
    if settings["ModelHydrogen"] == 1
        hydrogen_inputs = inputs["HydrogenInputs"]
        profiles = merge_hydrogen_inputs(profiles, hydrogen_inputs, Zones)
    end

    ## Obtain carbon sector inputs
    if settings["ModelCarbon"] == 1
        carbon_inputs = inputs["CarbonInputs"]
        profiles = merge_carbon_inputs(profiles, carbon_inputs, Zones)
    end

    ## Obtain synfuels sector inputs
    if settings["ModelSynfuels"] == 1
        synfuels_inputs = inputs["SynfuelsInputs"]
        profiles = merge_synfuels_inputs(profiles, synfuels_inputs, Zones)
    end

    ## Obtain ammonia sector inputs
    if settings["ModelAmmonia"] == 1
        ammonia_inputs = inputs["AmmoniaInputs"]
        profiles = merge_ammonia_inputs(profiles, ammonia_inputs, Zones)
    end

    return profiles
end
