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
function modify_sector_data(settings::Dict, inputs::Dict)

    modification = settings["Modification"]

    print_and_log(settings, "i", "Modifying Sector Data According to User's Modification")

    ## Check each sector to decide whether to change its data
    ## Change power sector inputs
    if settings["ModelPower"] == 1
        inputs, modification = modify_power_inputs(settings, inputs, modification)
    end

    ## Change hydrogen sector inputs
    if settings["ModelHydrogen"] == 1
        inputs, modification = modify_hydrogen_inputs(settings, inputs, modification)
    end

    ## Change carbon sector inputs
    if settings["ModelCarbon"] == 1
        inputs, modification = modify_carbon_inputs(settings, inputs, modification)
    end

    ## Change synfuels sector inputs
    if settings["ModelSynfuels"] == 1
        inputs, modification = modify_synfuels_inputs(settings, inputs, modification)
    end

    ## Change bioenergy sector inputs
    if settings["ModelBioenergy"] == 1
        inputs, modification = modify_bioenergy_inputs(settings, inputs, modification)
    end

    settings["Modification"] = modification

    return settings, inputs
end
