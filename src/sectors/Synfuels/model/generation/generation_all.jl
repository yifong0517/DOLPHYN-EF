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

    print_and_log(settings, "i", "Synfuels Generation Core Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    synfuels_settings = settings["SynfuelsSettings"]

    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]
        fuels_costs = inputs["fuels_costs"]
    end
    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
        electricity_costs = inputs["electricity_costs"]
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

    ## Get generators' data from dataframe
    synfuels_inputs = inputs["SynfuelsInputs"]
    dfGen = synfuels_inputs["dfGen"]

    G = synfuels_inputs["G"]
    THERM = synfuels_inputs["THERM"]
    ELE = synfuels_inputs["ELE"]
    CLG = synfuels_inputs["CLG"]
    GLG = synfuels_inputs["GLG"]
    BLG = synfuels_inputs["BLG"]

    COMMIT = synfuels_inputs["COMMIT"]
    NO_COMMIT = synfuels_inputs["NO_COMMIT"]
    ResourceType = synfuels_inputs["GenResourceType"]

    CCS = synfuels_inputs["CCS"]

    ### Variables ###
    ## Energy injected into the grid by resource "g" at hour "t"
    @variable(MESS, vSGen[g in 1:G, t in 1:T] >= 0)

    if !isempty(COMMIT)
        ## Decision variables for unit commitment
        ## Unit commitment state variable
        @variable(MESS, vSOnline[g in COMMIT, t in 1:T] >= 0)
        ## Unit startup event variable
        @variable(MESS, vSStart[g in COMMIT, t in 1:T] >= 0)
        ## Unit shutdown event variable
        @variable(MESS, vSShut[g in COMMIT, t in 1:T] >= 0)
    end

    ### Expressions ###
    ## Objective Expressions ##
    ## Variable costs of "generation" for resource "g" during hour "t" = variable O&M
    @expression(
        MESS,
        eSObjVarGenOGT[g in 1:G, t in 1:T],
        weights[t] * dfGen[!, :Var_OM_Cost_per_tonne][g] * MESS[:vSGen][g, t]
    )
    @expression(MESS, eSObjVarGenOG[g in 1:G], sum(eSObjVarGenOGT[g, t] for t in 1:T; init = 0.0))
    @expression(MESS, eSObjVarGen, sum(eSObjVarGenOG[g] for g in 1:G; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eSObj], MESS[:eSObjVarGen])
    ## End Objective Expressions ##

    ## Synfuels generation expression & emission expressions ##
    ## Synfuels sector generation
    @expression(MESS, eSGeneration[z in 1:Z, t in 1:T], AffExpr(0))

    @expression(
        MESS,
        eSGenOZRT[z in 1:Z, rt in ResourceType],
        sum(
            MESS[:vSGen][g, t] * weights[t] for
            g in dfGen[(dfGen.Zone .== Zones[z]) .& (dfGen.Resource_Type .== rt), :R_ID], t in 1:T;
            init = 0.0,
        )
    )

    @expression(
        MESS,
        eSGenORTT[rt in ResourceType, t in 1:T],
        sum(MESS[:vSGen][g, t] for g in dfGen[dfGen.Resource_Type .== rt, :R_ID]; init = 0.0)
    )
    ## Synfuels sector emissions
    @expression(
        MESS,
        eSEmissionsOGT[g = 1:G, t = 1:T],
        if g in COMMIT
            (
                dfGen[!, :CO2_tonne_per_tonne][g] * MESS[:vSGen][g, t] +
                dfGen[!, :CO2_tonne_per_Start][g] * MESS[:vSStart][g, t]
            ) * (1 - dfGen[!, :CCS_Percentage][g])
        else
            dfGen[!, :CO2_tonne_per_tonne][g] *
            MESS[:vSGen][g, t] *
            (1 - dfGen[!, :CCS_Percentage][g])
        end
    )

    @expression(
        MESS,
        eSEmissionsByGen[z = 1:Z, t = 1:T],
        sum(eSEmissionsOGT[g, t] for g in dfGen[dfGen.Zone .== Zones[z], :R_ID]; init = 0.0)
    )
    add_to_expression!.(MESS[:eSEmissions], MESS[:eSEmissionsByGen])

    ## Sub zonal generation expressions
    if synfuels_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = synfuels_inputs["SubZones"]
        ## Synfuels sector sub zonal generation expression
        @expression(MESS, eSGenerationSubZonal[z in SubZones, t in 1:T], AffExpr(0))
        ## Sub zonal emissions from generation expression
        @expression(
            MESS,
            eSEmissionsSubZonalByGen[z in SubZones, t = 1:T],
            sum(eSEmissionsOGT[g, t] for g in dfGen[dfGen.SubZone .== z, :R_ID]; init = 0.0)
        )
    end

    ## Feedstock fuel consumption of "generation" from resource "g" during hour "t"
    if settings["ModelFuels"] == 1
        @expression(
            MESS,
            eSFuelsConsumptionByGen[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vSGen][g, t] * dfGen[!, :Heat_Rate_MMBTU_per_tonne][g] for g in intersect(
                    dfGen[dfGen.Fuel .== Fuels_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                );
                init = 0.0,
            )
        )

        ## Feedstock fuel consumption costs from resource "g" during hour "t"
        @expression(
            MESS,
            eSObjVarFuelOG[g in 1:G],
            if dfGen[!, :Fuel][g] in Fuels_Index
                sum(
                    MESS[:vSGen][g, t] *
                    dfGen[!, :Heat_Rate_MMBTU_per_tonne][g] *
                    fuels_costs[dfGen[!, :Fuel][g]][t] for t in 1:T;
                    init = 0.0,
                )
            else
                0
            end
        )

        ## Add fuel feedstock consumption
        add_to_expression!.(MESS[:eSFuelsConsumption], MESS[:eSFuelsConsumptionByGen])
    end

    if !(settings["ModelPower"] == 1)
        ## Feedstock electricity consumption of "generation" from resource "g" during hour "t"
        @expression(
            MESS,
            eSElectricityConsumptionByGen[f in eachindex(Electricity_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vSGen][g, t] * dfGen[!, :Electricity_Rate_MWh_per_tonne][g] for
                g in intersect(
                    dfGen[dfGen.Electricity .== Electricity_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                );
                init = 0.0,
            )
        )

        ## Add electricity feedstock consumption
        add_to_expression!.(MESS[:eSElectricityConsumption], MESS[:eSElectricityConsumptionByGen])

        ## Feedstock electricity purchasing costs from resource "g" during hour "t"
        @expression(
            MESS,
            eSObjVarElectricityOG[g in 1:G],
            if dfGen[!, :Electricity][g] in Electricity_Index
                sum(
                    MESS[:vSGen][g, t] *
                    dfGen[!, :Electricity_Rate_MWh_per_tonne][g] *
                    electricity_costs[dfGen[!, :Electricity][g]][t] for t in 1:T;
                    init = 0.0,
                )
            else
                0
            end
        )
    else
        ## Electricity consumption of "generation" from resource "g" during hour "t"
        @expression(
            MESS,
            ePBalanceSGen[z in 1:Z, t in 1:T],
            sum(
                MESS[:vSGen][g, t] * dfGen[!, :Electricity_Rate_MWh_per_tonne][g] for
                g in dfGen[dfGen.Zone .== Zones[z], :R_ID];
                init = 0.0,
            )
        )

        ## Add electricity consumption
        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceSGen])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceSGen])
    end

    if !(settings["ModelHydrogen"] == 1)
        ## Feedstock Hydrogen consumption of "generation" from resource "g" during hour "t"
        @expression(
            MESS,
            eSHydrogenConsumptionByGen[f in eachindex(Hydrogen_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vSGen][g, t] * dfGen[!, :Hydrogen_Rate_tonne_per_tonne][g] for g in intersect(
                    dfGen[dfGen.Hydrogen .== Hydrogen_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                );
                init = 0.0,
            )
        )

        ## Add synfuels feedstock consumption
        add_to_expression!.(MESS[:eSHydrogenConsumption], MESS[:eSHydrogenConsumptionByGen])

        ## Feedstock hydrogen purchasing costs from resource "g" during hour "t"
        @expression(
            MESS,
            eSObjVarHydrogenOG[g in 1:G],
            if dfGen[!, :Hydrogen][g] in Hydrogen_Index
                sum(
                    MESS[:vSGen][g, t] *
                    dfGen[!, :Hydrogen_Rate_tonne_per_tonne][g] *
                    hydrogen_costs[dfGen[!, :Hydrogen][g]][t] for t in 1:T;
                    init = 0.0,
                )
            else
                0
            end
        )
    else
        ## Hydrogen consumption of "generation" from resource "g" during hour "t"
        @expression(
            MESS,
            eHBalanceSGen[z in 1:Z, t in 1:T],
            sum(
                MESS[:vSGen][g, t] * dfGen[!, :Hydrogen_Rate_tonne_per_tonne][g] for
                g in dfGen[dfGen.Zone .== Zones[z], :R_ID];
                init = 0.0,
            )
        )

        ## Add synfuels feedstock consumption
        add_to_expression!.(MESS[:eHBalance], -MESS[:eHBalanceSGen])
        add_to_expression!.(MESS[:eHDemandAddition], MESS[:eHBalanceSGen])
    end

    if !(settings["ModelCarbon"] == 1)
        ## Feedstock carbon consumption of "generation" from resource "g" during hour "t"
        @expression(
            MESS,
            eSCarbonConsumptionByGen[f in eachindex(Carbon_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vSGen][g, t] * dfGen[!, :Carbon_Rate_tonne_per_tonne][g] for g in intersect(
                    dfGen[dfGen.Carbon .== Carbon_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                );
                init = 0.0,
            )
        )

        ## Add carbon feedstock consumption
        add_to_expression!.(MESS[:eSCarbonConsumption], MESS[:eSCarbonConsumptionByGen])

        ## Feedstock carbon purchasing costs from resource "g" during hour "t"
        @expression(
            MESS,
            eSObjVarCarbonOG[g in 1:G],
            if dfGen[!, :Carbon][g] in Carbon_Index
                sum(
                    MESS[:vSGen][g, t] *
                    dfGen[!, :Carbon_Rate_tonne_per_tonne][g] *
                    carbon_costs[dfGen[!, :Carbon][g]][t] for t in 1:T;
                    init = 0.0,
                )
            else
                0
            end
        )
    else
        ## Carbon consumption of "generation" from resource "g" during hour "t"
        @expression(
            MESS,
            eCBalanceSGen[z in 1:Z, t in 1:T],
            sum(
                MESS[:vSGen][g, t] * dfGen[!, :Carbon_Rate_tonne_per_tonne][g] for
                g in dfGen[dfGen.Zone .== Zones[z], :R_ID];
                init = 0.0,
            )
        )

        ## Add carbon feedstock consumption
        add_to_expression!.(MESS[:eCBalance], -MESS[:eCBalanceSGen])
        add_to_expression!.(MESS[:eCDemandAddition], MESS[:eCBalanceSGen])
    end

    if !(settings["ModelBioenergy"] == 1)
        ## Feedstock bioenergy consumption of "generation" from resource "g" during hour "t"
        @expression(
            MESS,
            eSBioenergyConsumptionByGen[f in eachindex(Bioenergy_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vSGen][g, t] * dfGen[!, :Bioenergy_Rate_MMBTU_per_tonne][g] for
                g in intersect(
                    dfGen[dfGen.Bioenergy .== Bioenergy_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                );
                init = 0.0,
            )
        )

        ## Add bioenergy feedstock consumption
        add_to_expression!.(MESS[:eSBioenergyConsumption], MESS[:eSBioenergyConsumptionByGen])

        ## Feedstock bioenergy purchasing costs from resource "g" during hour "t" - marginal price not valid
        @expression(
            MESS,
            eSObjVarBioenergyOG[g in 1:G],
            if dfGen[!, :Bioenergy][g] in Bioenergy_Index
                sum(
                    MESS[:vSGen][g, t] *
                    dfGen[!, :Bioenergy_Rate_MMBTU_per_tonne][g] *
                    bioenergy_costs[dfGen[!, :Bioenergy][g]][t] for t in 1:T;
                    init = 0.0,
                )
            else
                0
            end
        )
    end
    ### End Expressions ###

    ### Constraints ###
    ## Full load hours
    if synfuels_settings["ModelFLH"] == 1
        @constraint(
            MESS,
            cSGenFullLoadHours[g in 1:G],
            sum(weights[t] * MESS[:vSGen][g, t] for t in 1:T) <=
            MESS[:eSGenCap][g] * dfGen[!, :Full_Load_Hours][g],
        )
    end
    ### End Constraints ###

    ## Specific generation types - electrolyser
    if !isempty(ELE)
        MESS = generation_ele(settings, inputs, MESS)
    end

    ## Specific generation types - thermal resources
    if !isempty(THERM)
        MESS = generation_thermal(settings, inputs, MESS)
    end

    ## Specific generation types - eligible for unit commitment
    if !isempty(COMMIT)
        MESS = generation_commit(settings, inputs, MESS)
    end

    ## Specific generation types - not eligible for unit commitment
    if !isempty(NO_COMMIT)
        MESS = generation_no_commit(settings, inputs, MESS)
    end

    ## Specific generation types - coal liquefaction resources
    if !isempty(CLG)
        MESS = generation_clg(settings, inputs, MESS)
    end

    ## Specific generation types - natural gas liquefaction resources
    if !isempty(GLG)
        MESS = generation_glg(settings, inputs, MESS)
    end

    ## Specific generation types - biomass liquefaction resources
    if !isempty(BLG)
        MESS = generation_blg(settings, inputs, MESS)
    end

    ## Specific generation types - ccs resources
    if !isempty(CCS)
        MESS = generation_ccs(settings, inputs, MESS)
    end

    return MESS
end
