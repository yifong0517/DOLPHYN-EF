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
function carbon_sniffer(settings::Dict, inputs::Dict, MESS::Model, sniffer::AbstractDict)

    print_and_log(settings, "i", "Start Sniffing Carbon Sector")

    carbon_settings = settings["CarbonSettings"]
    ModelStorage = carbon_settings["ModelStorage"]
    ModelPipelines = carbon_settings["ModelPipelines"]

    ## Carbon sector generation sniffer
    sniffer = carbon_gen_sniffer(settings, inputs, MESS, sniffer)

    if ModelStorage == 1
        ## Carbon sector storage sniffer
        sniffer = carbon_sto_sniffer(settings, inputs, MESS, sniffer)
    end

    if ModelPipelines == 1
        ## Carbon sector transmission sniffer
        sniffer = carbon_tra_sniffer(settings, inputs, MESS, sniffer)
    end

    ## Carbon sector demand sniffer
    sniffer = carbon_demand_sniffer(settings, inputs, MESS, sniffer)

    return sniffer
end


@doc raw"""

"""
function carbon_sniffer(carbon_path::AbstractString, sniffer::OrderedDict)

    if isdir(carbon_path)
        println("Start Sniffing Carbon Sector")
    end

    ## Carbon sector generation sniffer
    gen_capacity = DataFrame(CSV.File(joinpath(carbon_path, "capacities_generation.csv")))
    sniffer["C_Existing_Gen_Cap"] = sum(gen_capacity[!, :StartGenCap])
    sniffer["C_Mapping_Gen_Cap"] = sum(gen_capacity[!, :EndGenCap])

    generation = DataFrame(CSV.File(joinpath(carbon_path, "generation_by_zone.csv")))
    sniffer["C_Actual_Generation"] = first(generation[generation.Zone .== "Total", "Sum"])

    if isfile(joinpath(carbon_path, "capacities_storage.csv")) ||
       isfile(joinpath(carbon_path, "storage_energy.csv")) ||
       isfile(joinpath(carbon_path, "storage_discharge.csv")) ||
       isfile(joinpath(carbon_path, "storage_charge.csv"))
        ## Carbon sector storage sniffer
        sto_capacity = DataFrame(CSV.File(joinpath(carbon_path, "capacities_storage.csv")))
        sniffer["C_Existing_Sto_Ene_Cap"] = sum(sto_capacity[!, :StartStoEneCap])
        sniffer["C_Mapping_Sto_Ene_Cap"] = sum(sto_capacity[!, :EndStoEneCap])
        sniffer["C_Mapping_Sto_Dis_Cap"] = sum(sto_capacity[!, :EndStoDisCap])
        sniffer["C_Mapping_Sto_Cha_Cap"] = sum(sto_capacity[!, :EndStoChaCap])
        sniffer["C_Sto_Duration"] =
            sniffer["C_Mapping_Sto_Dis_Cap"] > 0.0 ?
            round(
                sniffer["C_Mapping_Sto_Ene_Cap"] / sniffer["C_Mapping_Sto_Dis_Cap"];
                sigdigits = 2,
            ) : -1

        sto_dis = DataFrame(CSV.File(joinpath(carbon_path, "storage_discharge.csv")))
        sto_cha = DataFrame(CSV.File(joinpath(carbon_path, "storage_charge.csv")))
        sniffer["C_Sto_Throughout"] =
            sum(sto_dis[sto_dis.Resource .== Symbol.(1:sniffer["TotalTime"]), Not(Resource)]) +
            sum(sto_cha[sto_cha.Resource .== Symbol.(1:sniffer["TotalTime"]), Not(Resource)])
        sniffer["C_Sto_Cycles"] = sniffer["C_Sto_Throughout"] / sniffer["C_Mapping_Sto_Ene_Cap"]
    end

    if isfile(joinpath(carbon_path, "network_expansion.csv")) ||
       isfile(joinpath(carbon_path, "pipeline_flow.csv"))
        ## Carbon sector transmission sniffer
        pipe_capacity = DataFrame(CSV.File(joinpath(carbon_path, "network_expansion.csv")))
        sniffer["C_Existing_Tra_Cap"] = sum(pipe_capacity[!, :Existing_Trans_Capacity])
        sniffer["C_Mapping_Tra_Cap"] = sum(pipe_capacity[!, :Total_Trans_Capacity])
    end

    ## Carbon sector demand sniffer
    demand = DataFrame(CSV.File(joinpath(carbon_path, "demand_by_zone.csv")))
    ademand = DataFrame(CSV.File(joinpath(carbon_path, "demand_additional_by_zone.csv")))

    sniffer["C_Actual_Demand"] = first(demand[demand.Zone .== "Total", :Sum])
    sniffer["C_Additional_Demand"] = first(ademand[ademand.Zone .== "Total", :Sum])

    return sniffer
end
