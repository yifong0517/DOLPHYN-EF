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
	generation_all(settings::Dict, inputs::Dict, MESS::Model)

"""
function generation_all(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Generation Core Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    ## Feedstock index lists
    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]
        fuels_costs = inputs["fuels_costs"]
    end
    if !(settings["ModelHydrogen"] == 1)
        Hydrogen_Index = inputs["Hydrogen_Index"]
        hydrogen_costs = inputs["hydrogen_costs"]
    end
    if !(settings["ModelCarbon"] == 1)
        Carbon_Index = inputs["Carbon_Index"]
        carbon_costs = inputs["carbon_costs"]
    end
    if !(settings["ModelBioenergy"] == 1)
        Bioenergy_Index = inputs["Bioenergy_Index"]
        bioenergy_costs = inputs["bioenergy_costs"]
    end

    ## Get power sector settings
    power_settings = settings["PowerSettings"]
    QuadricEmission = power_settings["QuadricEmission"]
    CapReserve = power_settings["CapReserve"]
    PReserve = power_settings["PReserve"]

    ## Get generators' data from dataframe
    power_inputs = inputs["PowerInputs"]
    dfGen = power_inputs["dfGen"]

    G = power_inputs["G"]
    VRE = power_inputs["VRE"]
    HYDRO = power_inputs["HYDRO"] ## Hydroelectric generators
    CFG = power_inputs["CFG"]  ## Coal fired generators
    GFG = power_inputs["GFG"]  ## Natural gas fired generators
    OFG = power_inputs["OFG"]  ## Oil fired generators
    HFG = power_inputs["HFG"]  ## Hydrogen fired generators
    NFG = power_inputs["NFG"]  ## Nuclear fired generators
    BFG = power_inputs["BFG"]  ## Biomass fired generators

    THERM = power_inputs["THERM"]
    COMMIT = power_inputs["COMMIT"]
    NO_COMMIT = power_inputs["NO_COMMIT"]
    MUST_RUN = power_inputs["MUST_RUN"]
    ResourceType = power_inputs["GenResourceType"]

    CCS = power_inputs["CCS"]

    ### Variables ###
    ## Energy injected into the grid by resource "g" at hour "t"
    @variable(MESS, vPGen[g in 1:G, t in 1:T] >= 0)

    if !isempty(COMMIT)
        ## Decision variables for unit commitment
        ## Unit commitment state variable
        @variable(MESS, vPOnline[g in COMMIT, t in 1:T] >= 0)
        ## Unit startup event variable
        @variable(MESS, vPStart[g in COMMIT, t in 1:T] >= 0)
        ## Unit shutdown event variable
        @variable(MESS, vPShut[g in COMMIT, t in 1:T] >= 0)
    end

    ## Decision variables for primary reserve
    if PReserve == 1
        GEN_PRSV = power_inputs["GEN_PRSV"]
        @variable(MESS, vPGenPRSV[g in GEN_PRSV, t in 1:T] >= 0)
    end

    ### Expressions ###
    ## Objective Expressions ##
    ## Variable costs of "generation" for resource "g" during hour "t" = variable O&M
    @expression(
        MESS,
        ePObjVarGenOGT[g in 1:G, t in 1:T],
        weights[t] * dfGen[!, :Var_OM_Cost_per_MWh][g] * MESS[:vPGen][g, t]
    )
    @expression(
        MESS,
        ePObjVarGenOG[g in 1:G],
        sum(MESS[:ePObjVarGenOGT][g, t] for t in 1:T; init = 0.0)
    )
    @expression(MESS, ePObjVarGen, sum(MESS[:ePObjVarGenOG][g] for g in 1:G; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:ePObj], MESS[:ePObjVarGen])
    ## End Objective Expressions ##

    ## Power sector generation
    @expression(MESS, ePGeneration[z in 1:Z, t in 1:T], AffExpr(0))

    @expression(
        MESS,
        ePGenOZRT[z in 1:Z, rt in ResourceType],
        sum(
            MESS[:vPGen][g, t] * weights[t] for
            g in dfGen[(dfGen.Zone .== Zones[z]) .& (dfGen.Resource_Type .== rt), :R_ID], t in 1:T;
            init = 0.0,
        )
    )

    @expression(
        MESS,
        ePGenORTT[rt in ResourceType, t in 1:T],
        sum(MESS[:vPGen][g, t] for g in dfGen[dfGen.Resource_Type .== rt, :R_ID]; init = 0.0)
    )

    ## Power sector generation capacity reserve
    if CapReserve >= 1
        @expression(MESS, ePGenCapacityReserve[p in 1:CapReserve, z in 1:Z, t in 1:T], AffExpr(0))
    end

    ## Power sector generation primary reserve
    if PReserve == 1
        GEN_PRSV = power_inputs["GEN_PRSV"]
        ## Reserve costs of "generation" for resource "g" during hour "t"
        @expression(
            MESS,
            ePObjVarReserveGenOGT[g in GEN_PRSV, t in 1:T],
            weights[t] * dfGen[!, :PRSV_Cost][g] * MESS[:vPGenPRSV][g, t]
        )

        ## Add total variable discharging cost contribution to the objective function
        @expression(
            MESS,
            ePObjVarReserveGenOG[g in 1:G],
            sum(weights[t] * MESS[:ePObjVarReserveGenOGT][g, t] for t in 1:T; init = 0.0)
        )
        @expression(
            MESS,
            ePObjVarReserveGen,
            sum(MESS[:ePObjVarReserveGenOG][g] for g in 1:G; init = 0.0)
        )
        add_to_expression!(MESS[:ePObj], MESS[:ePObjVarReserveGen])

        @expression(MESS, ePGenPrimaryReserve[z in 1:Z, t in 1:T], AffExpr(0))
    end

    ## Power sector emissions from generation
    if QuadricEmission == 1
        @expression(
            MESS,
            ePEmissionsOGT[g = 1:G, t = 1:T],
            if g in COMMIT
                (
                    dfGen[!, :CO2_tonne_per_Square_MWh][g] * MESS[:vPGen][g, t]^2 +
                    dfGen[!, :CO2_tonne_per_MWh][g] * MESS[:vPGen][g, t] +
                    dfGen[!, :CO2_tonne_No_Load][g] +
                    dfGen[!, :CO2_tonne_per_Start][g] * MESS[:vPStart][g, t]
                ) * (1 - dfGen[!, :CCS_Percentage][g])
            else
                (
                    dfGen[!, :CO2_tonne_per_Square_MWh][g] * MESS[:vPGen][g, t]^2 +
                    dfGen[!, :CO2_tonne_per_MWh][g] * MESS[:vPGen][g, t] +
                    dfGen[!, :CO2_tonne_No_Load][g]
                ) * (1 - dfGen[!, :CCS_Percentage][g])
            end
        )

        @expression(
            MESS,
            ePEmissionsByGen[z = 1:Z, t = 1:T],
            sum(ePEmissionsOGT[g, t] for g in dfGen[dfGen.Zone .== Zones[z], :R_ID]; init = 0.0)
        )
        MESS[:ePEmissions] += MESS[:ePEmissionsByGen]
    else
        @expression(
            MESS,
            ePEmissionsOGT[g = 1:G, t = 1:T],
            if g in COMMIT
                (
                    dfGen[!, :CO2_tonne_per_MWh][g] * MESS[:vPGen][g, t] +
                    dfGen[!, :CO2_tonne_No_Load][g] +
                    dfGen[!, :CO2_tonne_per_Start][g] * MESS[:vPStart][g, t]
                ) * (1 - dfGen[!, :CCS_Percentage][g])
            else
                (
                    dfGen[!, :CO2_tonne_per_MWh][g] * MESS[:vPGen][g, t] +
                    dfGen[!, :CO2_tonne_No_Load][g]
                ) * (1 - dfGen[!, :CCS_Percentage][g])
            end
        )

        @expression(
            MESS,
            ePEmissionsByGen[z = 1:Z, t = 1:T],
            sum(ePEmissionsOGT[g, t] for g in dfGen[dfGen.Zone .== Zones[z], :R_ID]; init = 0.0)
        )
        add_to_expression!.(MESS[:ePEmissions], MESS[:ePEmissionsByGen])
    end

    ## Sub zonal generation expressions
    if power_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = power_inputs["SubZones"]
        ## Power sector sub zonal generation expression
        @expression(MESS, ePGenerationSubZonal[z in SubZones, t in 1:T], AffExpr(0))
        ## Sub zonal emissions from generation expression
        @expression(
            MESS,
            ePEmissionsByGenSubZonal[z in SubZones, t = 1:T],
            sum(ePEmissionsOGT[g, t] for g in dfGen[dfGen.SubZone .== z, :R_ID]; init = 0.0)
        )
    end

    ## Feedstock fuel consumption of "generation" from resource "g" during hour "t"
    if settings["ModelFuels"] == 1
        if QuadricEmission == 1
            @expression(
                MESS,
                ePFuelsConsumptionByGen[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
                sum(
                    dfGen[!, :Heat_Rate_MMBTU_per_Square_MWh][g] * MESS[:vPGen][g, t]^2 +
                    dfGen[!, :Heat_Rate_MMBTU_per_MWh][g] * MESS[:vPGen][g, t] +
                    dfGen[!, :Heat_Rate_MMBTU_No_Load][g] for g in intersect(
                        dfGen[dfGen.Fuel .== Fuels_Index[f], :R_ID],
                        dfGen[dfGen.Zone .== Zones[z], :R_ID],
                    );
                    init = 0.0,
                )
            )
        else
            @expression(
                MESS,
                ePFuelsConsumptionByGen[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
                sum(
                    dfGen[!, :Heat_Rate_MMBTU_per_MWh][g] * MESS[:vPGen][g, t] +
                    dfGen[!, :Heat_Rate_MMBTU_No_Load][g] for g in intersect(
                        dfGen[dfGen.Fuel .== Fuels_Index[f], :R_ID],
                        dfGen[dfGen.Zone .== Zones[z], :R_ID],
                    );
                    init = 0.0,
                )
            )
        end

        ## Feedstock fuel consumption costs from resource "g" during hour "t"
        @expression(
            MESS,
            ePObjVarFuelOG[g in 1:G],
            if dfGen[!, :Fuel][g] in Fuels_Index
                sum(
                    MESS[:vPGen][g, t] *
                    dfGen[!, :Heat_Rate_MMBTU_per_MWh][g] *
                    fuels_costs[dfGen[!, :Fuel][g]][t] for t in 1:T;
                    init = 0.0,
                )
            else
                0
            end
        )

        ## Add fuel feedstock consumption
        if QuadricEmission == 1
            MESS[:ePFuelsConsumption] += MESS[:ePFuelsConsumptionByGen]
        else
            add_to_expression!.(MESS[:ePFuelsConsumption], MESS[:ePFuelsConsumptionByGen])
        end
    end

    #* This expression could be used to model self-consumption of power generator plants and
    #* in this situation it should be a percentage indicating the share of electricity being
    #* used as self-consumption and the rest being injected into the grid. Note that this
    #* expression has not being written into balance dataframe yet.
    @expression(
        MESS,
        ePGenSelfConsumption[g in 1:G, t in 1:T],
        MESS[:vPGen][g, t] * dfGen[!, :Electricity_Rate_MWh_per_MWh][g]
    )

    @expression(
        MESS,
        ePBalanceSelfConsumption[z in 1:Z, t in 1:T],
        sum(
            MESS[:ePGenSelfConsumption][g, t] for g in dfGen[dfGen.Zone .== Zones[z], :R_ID];
            init = 0.0,
        )
    )
    add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceSelfConsumption])

    if !(settings["ModelHydrogen"] == 1)
        ## Feedstock hydrogen consumption of "generation" from resource "g" during hour "t"
        @expression(
            MESS,
            ePHydrogenConsumptionByGen[f in eachindex(Hydrogen_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vPGen][g, t] * dfGen[!, :Hydrogen_Rate_tonne_per_MWh][g] for g in intersect(
                    dfGen[dfGen.Hydrogen .== Hydrogen_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                );
                init = 0.0,
            )
        )

        ## Add hydrogen feedstock consumption
        add_to_expression!.(MESS[:ePHydrogenConsumption], MESS[:ePHydrogenConsumptionByGen])

        ## Feedstock hydrogen purchasing costs from resource "g" during hour "t"
        @expression(
            MESS,
            ePObjVarHydrogenOG[g in 1:G],
            if dfGen[!, :Hydrogen][g] in Hydrogen_Index
                sum(
                    MESS[:vPGen][g, t] *
                    dfGen[!, :Hydrogen_Rate_tonne_per_MWh][g] *
                    hydrogen_costs[dfGen[!, :Hydrogen][g]][t] for t in 1:T;
                    init = 0.0,
                )
            else
                0
            end
        )
    end

    if !(settings["ModelCarbon"] == 1)
        ## Feedstock carbon consumption of "generation" from resource "g" during hour "t"
        @expression(
            MESS,
            ePCarbonConsumptionByGen[f in eachindex(Carbon_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vPGen][g, t] * dfGen[!, :Carbon_Rate_tonne_per_MWh][g] for g in intersect(
                    dfGen[dfGen.Carbon .== Carbon_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                );
                init = 0.0,
            )
        )

        ## Add carbon feedstock consumption
        add_to_expression!.(MESS[:ePCarbonConsumption], MESS[:ePCarbonConsumptionByGen])
    end

    if !(settings["ModelBioenergy"] == 1)
        ## Feedstock bioenergy consumption of "generation" from resource "g" during hour "t"
        @expression(
            MESS,
            ePBioenergyConsumptionByGen[f in eachindex(Bioenergy_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vPGen][g, t] * dfGen[!, :Bioenergy_Rate_MMBTU_per_MWh][g] for g in intersect(
                    dfGen[dfGen.Bioenergy .== Bioenergy_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                );
                init = 0.0,
            )
        )

        ## Add bioenergy feedstock consumption
        add_to_expression!.(MESS[:ePBioenergyConsumption], MESS[:ePBioenergyConsumptionByGen])

        ## Feedstock bioenergy purchasing costs from resource "g" during hour "t" - marginal price not valid
        @expression(
            MESS,
            ePObjVarBioenergyOG[g in 1:G],
            if dfGen[!, :Bioenergy][g] in Bioenergy_Index
                sum(
                    MESS[:vPGen][g, t] *
                    dfGen[!, :Bioenergy_Rate_MMBTU_per_MWh][g] *
                    bioenergy_costs[dfGen[!, :Bioenergy][g]][t] for t in 1:T;
                    init = 0.0,
                )
            else
                0
            end
        )
    end
    ### End Expressions ###

    ## Specific generation types - VRE
    if !isempty(VRE)
        MESS = generation_vre(settings, inputs, MESS)
    end

    ## Specific generation types - HYDRO
    if !isempty(HYDRO)
        MESS = generation_hydro(settings, inputs, MESS)
    end

    ## Specific generation types - thermal resources
    if !isempty(THERM)
        MESS = generation_thermal(settings, inputs, MESS)
    end

    ## Specific generation types - eligiable for unit commitment (mainly thermal)
    if !isempty(COMMIT)
        MESS = generation_commit(settings, inputs, MESS)
    end

    ## Specific generation types - not eligible for unit commitment (mainly thermal)
    if !isempty(NO_COMMIT)
        MESS = generation_no_commit(settings, inputs, MESS)
    end

    ## Specific generation types - must run resources
    if !isempty(MUST_RUN)
        MESS = generation_must_run(settings, inputs, MESS)
    end

    ## Specific generation types - coal fired generators (thermal)
    if !isempty(CFG)
        MESS = generation_cfg(settings, inputs, MESS)
    end

    ## Specific generation types - natural gas fired generators (thermal)
    if !isempty(GFG)
        MESS = generation_gfg(settings, inputs, MESS)
    end

    ## Specific generation types - oil fired generators (thermal)
    if !isempty(OFG)
        MESS = generation_ofg(settings, inputs, MESS)
    end

    ## Specific generation types - hydrogen fired generators (thermal)
    if !isempty(HFG)
        MESS = generation_hfg(settings, inputs, MESS)
    end

    ## Specific generation types - nuclear generators (thermal)
    if !isempty(NFG)
        MESS = generation_nfg(settings, inputs, MESS)
    end

    ## Specific generation types - biomass fired generators (thermal)
    if !isempty(BFG)
        MESS = generation_bfg(settings, inputs, MESS)
    end

    ## Specific generation types - ccs resources (thermal)
    if !isempty(CCS)
        MESS = generation_ccs(settings, inputs, MESS)
    end

    return MESS
end
