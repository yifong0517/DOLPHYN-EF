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
function power_sniffer(settings::Dict, inputs::Dict, MESS::Model, sniffer::AbstractDict)

    print_and_log(settings, "i", "Start Sniffing Power Sector")

    power_settings = settings["PowerSettings"]
    ModelStorage = power_settings["ModelStorage"]
    ModelTransmission = power_settings["ModelTransmission"]

    ## Power sector generation sniffer
    sniffer = power_gen_sniffer(settings, inputs, MESS, sniffer)

    if ModelStorage == 1
        ## Power sector storage sniffer
        sniffer = power_sto_sniffer(settings, inputs, MESS, sniffer)
    end

    if ModelTransmission == 1
        ## Power sector transmission sniffer
        sniffer = power_tra_sniffer(settings, inputs, MESS, sniffer)
    end

    ## Power sector demand sniffer
    sniffer = power_demand_sniffer(settings, inputs, MESS, sniffer)

    return sniffer
end


@doc raw"""

"""
function power_sniffer(power_path::AbstractString, sniffer::OrderedDict)

    if isdir(power_path)
        println("Start Sniffing Power Sector")
    end

    ## Power sector generation sniffer
    gen_capacity = DataFrame(CSV.File(joinpath(power_path, "capacities_generation.csv")))
    sniffer["P_Existing_Gen_Cap"] = sum(gen_capacity[!, :StartGenCap])
    sniffer["P_Mapping_Gen_Cap"] = sum(gen_capacity[!, :EndGenCap])

    generation = DataFrame(CSV.File(joinpath(power_path, "generation_by_zone.csv")))
    sniffer["P_Actual_Generation"] = first(generation[generation.Zone .== "Total", "Sum"])

    if isfile(joinpath(power_path, "capacities_storage.csv")) ||
       isfile(joinpath(power_path, "storage_energy.csv")) ||
       isfile(joinpath(power_path, "storage_discharge.csv")) ||
       isfile(joinpath(power_path, "storage_charge.csv"))
        ## Power sector storage sniffer
        sto_capacity = DataFrame(CSV.File(joinpath(power_path, "capacities_storage.csv")))
        sniffer["P_Existing_Sto_Ene_Cap"] = sum(sto_capacity[!, :StartStoEneCap])
        sniffer["P_Mapping_Sto_Ene_Cap"] = sum(sto_capacity[!, :EndStoEneCap])
        sniffer["P_Mapping_Sto_Dis_Cap"] = sum(sto_capacity[!, :EndStoDisCap])
        sniffer["P_Mapping_Sto_Cha_Cap"] = sum(sto_capacity[!, :EndStoChaCap])
        sniffer["P_Sto_Duration"] =
            sniffer["P_Mapping_Sto_Dis_Cap"] > 0.0 ?
            round(
                sniffer["P_Mapping_Sto_Ene_Cap"] / sniffer["P_Mapping_Sto_Dis_Cap"];
                sigdigits = 2,
            ) : -1

        sto_dis = DataFrame(CSV.File(joinpath(power_path, "storage_discharge.csv")))
        sto_cha = DataFrame(CSV.File(joinpath(power_path, "storage_charge.csv")))
        sniffer["P_Sto_Throughout"] =
            sum(sto_dis[sto_dis.Resource .== Symbol.(1:sniffer["TotalTime"]), Not(Resource)]) +
            sum(sto_cha[sto_cha.Resource .== Symbol.(1:sniffer["TotalTime"]), Not(Resource)])
        sniffer["P_Sto_Cycles"] = sniffer["P_Sto_Throughout"] / sniffer["P_Mapping_Sto_Ene_Cap"]
    end

    if isfile(joinpath(power_path, "network_expansion.csv")) ||
       isfile(joinpath(power_path, "flow_by_line.csv"))
        ## Power sector transmission sniffer
        line_capacity = DataFrame(CSV.File(joinpath(power_path, "network_expansion.csv")))
        sniffer["P_Existing_Tra_Cap"] = sum(line_capacity[!, :Start_Trans_Capacity])
        sniffer["P_Mapping_Tra_Cap"] = sum(line_capacity[!, :End_Trans_Capacity])
        transmission = DataFrame(CSV.File(joinpath(power_path, "flow_by_line.csv")))
        sniffer["P_Transmission"] = first(transmission[transmission.LineName .== "Total", :Sum])
    end

    ## Power sector demand sniffer
    demand = DataFrame(CSV.File(joinpath(power_path, "demand_by_zone.csv")))
    ademand = DataFrame(CSV.File(joinpath(power_path, "demand_additional_by_zone.csv")))

    sniffer["P_Actual_Demand"] = first(demand[demand.Zone .== "Total", :Sum])
    sniffer["P_Additional_Demand"] = first(ademand[ademand.Zone .== "Total", :Sum])

    return sniffer
end
