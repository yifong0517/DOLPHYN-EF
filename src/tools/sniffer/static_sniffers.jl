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
function static_sniffers(path::AbstractString)

    if isdir(path)
        println("Initializing Static Sniffers for Results Recording and Analysis")
        sniffer = OrderedDict{Any, Any}()
    else
        println("Results Path Does Not Exist, Abort Recording and Analysis")
        return nothing
    end

    ## Basic temporal and spatial information and settings
    if isfile(joinpath(path, "settings.csv"))
        settings = DataFrame(CSV.File(joinpath(path, "settings.csv")))
        sniffer["TotalTime"] = first(settings[settings.Key .== "TotalTime", :Value])
        sniffer["TimeMode"] = first(settings[settings.Key .== "TimeMode", :Value])
        sniffer["Period"] = first(settings[settings.Key .== "Period", :Value])
        sniffer["TimeStep"] = "hour"
        sniffer["TotalZone"] = first(settings[settings.Key .== "TotalZone", :Value])
        sniffer["ModelMode"] = first(settings[settings.Key .== "ModelMode", :Value])
        sniffer["ModelPower"] = first(settings[settings.Key .== "ModelPower", :Value])
        sniffer["ModelHydrogen"] = first(settings[settings.Key .== "ModelHydrogen", :Value])
        sniffer["ModelCarbon"] = first(settings[settings.Key .== "ModelCarbon", :Value])
        sniffer["ModelSynfuels"] = first(settings[settings.Key .== "ModelSynfuels", :Value])
        sniffer["ModelAmmonia"] = first(settings[settings.Key .== "ModelAmmonia", :Value])
        sniffer["ModelBioenergy"] = first(settings[settings.Key .== "ModelBioenergy", :Value])
        sniffer["ModelFoodstuff"] = first(settings[settings.Key .== "ModelFoodstuff", :Value])
        sniffer["Solver"] = first(settings[settings.Key .== "Solver", :Value])
        sniffer["SavePath"] = first(settings[settings.Key .== "SavePath", :Value])
    end

    ## Power sector sniffer
    if haskey(sniffer, "ModelPower") && sniffer["ModelPower"] == 1
        sniffer = power_sniffer(joinpath(path, "Power"), sniffer)
    end

    ## Hydrogen sector sniffer
    if haskey(sniffer, "ModelHydrogen") && sniffer["ModelHydrogen"] == 1
        sniffer = hydrogen_sniffer(joinpath(path, "Hydrogen"), sniffer)
    end

    ## Carbon sector sniffer
    if haskey(sniffer, "ModelCarbon") && sniffer["ModelCarbon"] == 1
        sniffer = carbon_sniffer(joinpath(path, "Carbon"), sniffer)
    end

    ## Synfuels sector sniffer
    if haskey(sniffer, "ModelSynfuels") && sniffer["ModelSynfuels"] == 1
        sniffer = synfuels_sniffer(joinpath(path, "Synfuels"), sniffer)
    end

    ## Ammonia sector sniffer
    if haskey(sniffer, "ModelAmmonia") && sniffer["ModelAmmonia"] == 1
        sniffer = ammonia_sniffer(joinpath(path, "Ammonia"), sniffer)
    end

    ## Bioenergy sector sniffer

    ## Foodstuff sector sniffer

    return sniffer
end
