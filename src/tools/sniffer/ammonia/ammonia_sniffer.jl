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
function ammonia_sniffer(settings::Dict, inputs::Dict, MESS::Model, sniffer::AbstractDict)

    print_and_log(settings, "i", "Start Sniffing Ammonia Sector")

    ammonia_settings = settings["AmmoniaSettings"]
    ModelStorage = ammonia_settings["ModelStorage"]

    ## Ammonia sector generation sniffer
    sniffer = ammonia_gen_sniffer(settings, inputs, MESS, sniffer)

    if ModelStorage == 1
        ## Ammonia sector storage sniffer
        sniffer = ammonia_sto_sniffer(settings, inputs, MESS, sniffer)
    end

    ## Ammonia sector demand sniffer
    sniffer = ammonia_demand_sniffer(settings, inputs, MESS, sniffer)

    return sniffer
end


@doc raw"""

"""
function ammonia_sniffer(ammonia_path::AbstractString, sniffer::OrderedDict)

    if isdir(ammonia_path)
        println("Start Sniffing Ammonia Sector")
    end

    ## Ammonia sector generation sniffer
    gen_capacity = DataFrame(CSV.File(joinpath(ammonia_path, "capacities_generation.csv")))
    sniffer["A_Existing_Gen_Cap"] = sum(gen_capacity[!, :StartGenCap])
    sniffer["A_Mapping_Gen_Cap"] = sum(gen_capacity[!, :EndGenCap])

    generation = DataFrame(CSV.File(joinpath(ammonia_path, "generation_by_zone.csv")))
    sniffer["A_Actual_Generation"] = first(generation[generation.Zone .== "Total", "Sum"])

    if isfile(joinpath(ammonia_path, "capacities_storage.csv")) ||
       isfile(joinpath(ammonia_path, "storage_energy.csv")) ||
       isfile(joinpath(ammonia_path, "storage_discharge.csv")) ||
       isfile(joinpath(ammonia_path, "storage_charge.csv"))
        ## Ammonia sector storage sniffer
        sto_capacity = DataFrame(CSV.File(joinpath(ammonia_path, "capacities_storage.csv")))
        sniffer["A_Existing_Sto_Ene_Cap"] = sum(sto_capacity[!, :StartStoEneCap])
        sniffer["A_Mapping_Sto_Ene_Cap"] = sum(sto_capacity[!, :EndStoEneCap])
        sniffer["A_Mapping_Sto_Dis_Cap"] = sum(sto_capacity[!, :EndStoDisCap])
        sniffer["A_Mapping_Sto_Cha_Cap"] = sum(sto_capacity[!, :EndStoChaCap])
        sniffer["A_Sto_Duration"] =
            sniffer["A_Mapping_Sto_Dis_Cap"] > 0.0 ?
            round(
                sniffer["A_Mapping_Sto_Ene_Cap"] / sniffer["A_Mapping_Sto_Dis_Cap"];
                sigdigits = 2,
            ) : -1

        sto_dis = DataFrame(CSV.File(joinpath(ammonia_path, "storage_discharge.csv")))
        sto_cha = DataFrame(CSV.File(joinpath(ammonia_path, "storage_charge.csv")))
        sniffer["A_Sto_Throughout"] =
            sum(sto_dis[sto_dis.Resource .== Symbol.(1:sniffer["TotalTime"]), Not(Resource)]) +
            sum(sto_cha[sto_cha.Resource .== Symbol.(1:sniffer["TotalTime"]), Not(Resource)])
        sniffer["A_Sto_Cycles"] = sniffer["A_Sto_Throughout"] / sniffer["A_Mapping_Sto_Ene_Cap"]
    end

    ## Ammonia sector demand sniffer
    demand = DataFrame(CSV.File(joinpath(ammonia_path, "demand_by_zone.csv")))
    ademand = DataFrame(CSV.File(joinpath(ammonia_path, "demand_additional_by_zone.csv")))

    sniffer["A_Actual_Demand"] = first(demand[demand.Zone .== "Total", :Sum])
    sniffer["A_Additional_Demand"] = first(ademand[ademand.Zone .== "Total", :Sum])

    return sniffer
end
