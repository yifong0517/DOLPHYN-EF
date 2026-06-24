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
function synfuels_sniffer(settings::Dict, inputs::Dict, MESS::Model, sniffer::AbstractDict)

    print_and_log(settings, "i", "Start Sniffing Synfuels Sector")

    synfuels_settings = settings["SynfuelsSettings"]
    ModelStorage = synfuels_settings["ModelStorage"]
    ModelPipelines = synfuels_settings["ModelPipelines"]

    ## Synfuels sector generation sniffer
    sniffer = synfuels_gen_sniffer(settings, inputs, MESS, sniffer)

    if ModelStorage == 1
        ## Synfuels sector storage sniffer
        sniffer = synfuels_sto_sniffer(settings, inputs, MESS, sniffer)
    end

    if ModelPipelines == 1
        ## Synfuels sector transmission sniffer
        sniffer = synfuels_tra_sniffer(settings, inputs, MESS, sniffer)
    end

    ## Synfuels sector demand sniffer
    sniffer = synfuels_demand_sniffer(settings, inputs, MESS, sniffer)

    return sniffer
end


@doc raw"""

"""
function synfuels_sniffer(synfuels_path::AbstractString, sniffer::OrderedDict)

    if isdir(synfuels_path)
        println("Start Sniffing Synfuels Sector")
    end

    ## Synfuels sector generation sniffer
    gen_capacity = DataFrame(CSV.File(joinpath(synfuels_path, "capacities_generation.csv")))
    sniffer["S_Existing_Gen_Cap"] = sum(gen_capacity[!, :StartGenCap])
    sniffer["S_Mapping_Gen_Cap"] = sum(gen_capacity[!, :EndGenCap])

    generation = DataFrame(CSV.File(joinpath(synfuels_path, "generation_by_zone.csv")))
    sniffer["S_Actual_Generation"] = first(generation[generation.Zone .== "Total", "Sum"])

    if isfile(joinpath(synfuels_path, "capacities_storage.csv")) ||
       isfile(joinpath(synfuels_path, "storage_energy.csv")) ||
       isfile(joinpath(synfuels_path, "storage_discharge.csv")) ||
       isfile(joinpath(synfuels_path, "storage_charge.csv"))
        ## Synfuels sector storage sniffer
        sto_capacity = DataFrame(CSV.File(joinpath(synfuels_path, "capacities_storage.csv")))
        sniffer["S_Existing_Sto_Ene_Cap"] = sum(sto_capacity[!, :StartStoEneCap])
        sniffer["S_Mapping_Sto_Ene_Cap"] = sum(sto_capacity[!, :EndStoEneCap])
        sniffer["S_Mapping_Sto_Dis_Cap"] = sum(sto_capacity[!, :EndStoDisCap])
        sniffer["S_Mapping_Sto_Cha_Cap"] = sum(sto_capacity[!, :EndStoChaCap])
        sniffer["S_Sto_Duration"] =
            sniffer["S_Mapping_Sto_Dis_Cap"] > 0.0 ?
            round(
                sniffer["S_Mapping_Sto_Ene_Cap"] / sniffer["S_Mapping_Sto_Dis_Cap"];
                sigdigits = 2,
            ) : -1

        sto_dis = DataFrame(CSV.File(joinpath(synfuels_path, "storage_discharge.csv")))
        sto_cha = DataFrame(CSV.File(joinpath(synfuels_path, "storage_charge.csv")))
        sniffer["S_Sto_Throughout"] =
            sum(sto_dis[sto_dis.Resource .== Symbol.(1:sniffer["TotalTime"]), Not(Resource)]) +
            sum(sto_cha[sto_cha.Resource .== Symbol.(1:sniffer["TotalTime"]), Not(Resource)])
        sniffer["S_Sto_Cycles"] = sniffer["S_Sto_Throughout"] / sniffer["S_Mapping_Sto_Ene_Cap"]
    end

    if isfile(joinpath(synfuels_path, "network_expansion.csv")) ||
       isfile(joinpath(synfuels_path, "pipeline_flow.csv"))
        ## Synfuels sector transmission sniffer
        pipe_capacity = DataFrame(CSV.File(joinpath(synfuels_path, "network_expansion.csv")))
        sniffer["S_Existing_Tra_Cap"] = sum(pipe_capacity[!, :Existing_Trans_Capacity])
        sniffer["S_Mapping_Tra_Cap"] = sum(pipe_capacity[!, :Total_Trans_Capacity])
    end

    ## Synfuels sector demand sniffer
    demand = DataFrame(CSV.File(joinpath(synfuels_path, "demand_by_zone.csv")))
    ademand = DataFrame(CSV.File(joinpath(synfuels_path, "demand_additional_by_zone.csv")))

    sniffer["S_Actual_Demand"] = first(demand[demand.Zone .== "Total", :Sum])
    sniffer["S_Additional_Demand"] = first(ademand[ademand.Zone .== "Total", :Sum])

    return sniffer
end
