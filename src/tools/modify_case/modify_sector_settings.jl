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
function modify_sector_settings(settings::Dict)

    modification = settings["Modification"]

    print_and_log(settings, "i", "Modifying Sector Settings According to User's Modification")

    ## Check each sector to decide whether to change its settings
    ## Change power sector settings
    if settings["ModelPower"] == 1
        settings = modify_power_settings(settings, modification)
    end

    ## Change hydrogen sector settings
    if settings["ModelHydrogen"] == 1
        settings = modify_hydrogen_settings(settings, modification)
    end

    ## Change carbon sector settings
    if settings["ModelCarbon"] == 1
        settings = modify_carbon_settings(settings, modification)
    end

    ## Change synfuels sector settings
    if settings["ModelSynfuels"] == 1
        settings = modify_synfuels_settings(settings, modification)
    end

    ## Change ammonia sector settings
    if settings["ModelAmmonia"] == 1
        settings = modify_ammonia_settings(settings, modification)
    end

    ## Change foodstuff sector settings
    if settings["ModelFoodstuff"] == 1
        settings = modify_foodstuff_settings(settings, modification)
    end

    ## Change bioenergy sector settings
    if settings["ModelBioenergy"] == 1
        settings = modify_bioenergy_settings(settings, modification)
    end

    return settings
end
