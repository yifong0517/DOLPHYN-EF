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
function load_foodstuff_settings(settings::Dict)

    ## Read foodstuff sector settings
    print_and_log(settings, "i", "Reading Settings for Foodstuff Sector")

    ## Load foodstuff sector settings from setting file
    foodstuff_settings_path = joinpath(settings["SettingPath"], settings["FoodstuffSettings"])
    foodstuff_settings = YAML.load(open(foodstuff_settings_path))

    ## Store log settings into foodstuff sector settings
    foodstuff_settings["Log"] = settings["Log"]
    ## Store console log settings into foodstuff sector settings
    foodstuff_settings["Silent"] = settings["Silent"]

    ## Override foodstuff sector settings from settings
    if haskey(settings, "Foodstuff")
        foodstuff_settings =
            override_foodstuff_sector_settings(foodstuff_settings, settings["Foodstuff"])
    end

    ## Load foodstuff sector default settings
    foodstuff_settings = load_foodstuff_default_settings(foodstuff_settings)

    ## Store foodstuff sector fuels modeling setting
    foodstuff_settings["ModelFuels"] = settings["ModelFuels"]

    return foodstuff_settings
end
