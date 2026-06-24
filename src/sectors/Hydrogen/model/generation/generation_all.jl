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

    print_and_log(settings, "i", "Hydrogen Generation Core Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    hydrogen_settings = settings["HydrogenSettings"]

    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]
        fuels_costs = inputs["fuels_costs"]
    end
    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
        electricity_costs = inputs["electricity_costs"]
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
    hydrogen_inputs = inputs["HydrogenInputs"]
    dfGen = hydrogen_inputs["dfGen"]

    G = hydrogen_inputs["G"]
    ELE = hydrogen_inputs["ELE"]
    THERM = hydrogen_inputs["THERM"]
    SMR = hydrogen_inputs["SMR"]
    CGF = hydrogen_inputs["CGF"]
    BMG = hydrogen_inputs["BMG"]

    COMMIT = hydrogen_inputs["COMMIT"]
    NO_COMMIT = hydrogen_inputs["NO_COMMIT"]
    ResourceType = hydrogen_inputs["GenResourceType"]

    CCS = hydrogen_inputs["CCS"]

    ### Variables ###
    ## Energy injected into the grid by resource "g" at hour "t"
    @variable(MESS, vHGen[g in 1:G, t in 1:T] >= 0)

    if !isempty(COMMIT)
        ## Decision variables for unit commitment
        ## Unit commitment state variable
        @variable(MESS, vHOnline[g in COMMIT, t in 1:T] >= 0)
        ## Unit startup event variable
        @variable(MESS, vHStart[g in COMMIT, t in 1:T] >= 0)
        ## Unit shutdown event variable
        @variable(MESS, vHShut[g in COMMIT, t in 1:T] >= 0)
    end

    ### Expressions ###
    ## Objective Expressions ##
    ## Variable costs of "generation" for resource "g" during hour "t" = variable O&M
    @expression(
        MESS,
        eHObjVarGenOGT[g in 1:G, t in 1:T],
        weights[t] * dfGen[!, :Var_OM_Cost_per_tonne][g] * MESS[:vHGen][g, t]
    )
    @expression(
        MESS,
        eHObjVarGenOG[g in 1:G],
        sum(MESS[:eHObjVarGenOGT][g, t] for t in 1:T; init = 0.0)
    )
    @expression(MESS, eHObjVarGen, sum(MESS[:eHObjVarGenOG][g] for g in 1:G; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eHObj], MESS[:eHObjVarGen])
    ## End Objective Expressions ##

    ## Hydrogen sector generation
    @expression(MESS, eHGeneration[z in 1:Z, t in 1:T], AffExpr(0))

    @expression(
        MESS,
        eHGenOZRT[z in 1:Z, rt in ResourceType],
        sum(
            MESS[:vHGen][g, t] * weights[t] for
            g in dfGen[(dfGen.Zone .== Zones[z]) .& (dfGen.Resource_Type .== rt), :R_ID], t in 1:T;
            init = 0.0,
        )
    )

    @expression(
        MESS,
        eHGenORTT[rt in ResourceType, t in 1:T],
        sum(MESS[:vHGen][g, t] for g in dfGen[dfGen.Resource_Type .== rt, :R_ID]; init = 0.0)
    )

    ## Hydrogen sector emissions
    @expression(
        MESS,
        eHEmissionsOGT[g = 1:G, t = 1:T],
        if g in COMMIT
            (
                dfGen[!, :CO2_tonne_per_tonne][g] * MESS[:vHGen][g, t] +
                dfGen[!, :CO2_tonne_per_Start][g] * MESS[:vHStart][g, t]
            ) * (1 - dfGen[!, :CCS_Percentage][g])
        else
            dfGen[!, :CO2_tonne_per_tonne][g] *
            MESS[:vHGen][g, t] *
            (1 - dfGen[!, :CCS_Percentage][g])
        end
    )

    @expression(
        MESS,
        eHEmissionsByGen[z = 1:Z, t = 1:T],
        sum(eHEmissionsOGT[g, t] for g in dfGen[dfGen.Zone .== Zones[z], :R_ID]; init = 0.0)
    )
    add_to_expression!.(MESS[:eHEmissions], MESS[:eHEmissionsByGen])

    ## Sub zonal generation expressions
    if hydrogen_settings["SubZone"] == 1 && settings["WriteLevel"] >= 4
        SubZones = hydrogen_inputs["SubZones"]
        ## Hydrogen sector sub zonal generation expression
        @expression(MESS, eHGenerationSubZonal[z in SubZones, t in 1:T], AffExpr(0))
        ## Sub zonal emissions from generation expression
        @expression(
            MESS,
            eHEmissionsByGenSubZonal[z in SubZones, t = 1:T],
            sum(eHEmissionsOGT[g, t] for g in dfGen[dfGen.SubZone .== z, :R_ID]; init = 0.0)
        )
    end

    ## Feedstock fuel consumption of "generation" from resource "g" during hour "t"
    if settings["ModelFuels"] == 1
        @expression(
            MESS,
            eHFuelsConsumptionByGen[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vHGen][g, t] * dfGen[!, :Heat_Rate_MMBTU_per_tonne][g] for g in intersect(
                    dfGen[dfGen.Fuel .== Fuels_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                );
                init = 0.0,
            )
        )

        ## Feedstock fuel consumption costs from resource "g" during hour "t"
        @expression(
            MESS,
            eHObjVarFuelOG[g in 1:G],
            if dfGen[!, :Fuel][g] in Fuels_Index
                sum(
                    MESS[:vHGen][g, t] *
                    dfGen[!, :Heat_Rate_MMBTU_per_tonne][g] *
                    fuels_costs[dfGen[!, :Fuel][g]][t] for t in 1:T;
                    init = 0.0,
                )
            else
                0
            end
        )

        ## Add fuel feedstock consumption
        add_to_expression!.(MESS[:eHFuelsConsumption], MESS[:eHFuelsConsumptionByGen])
    end

    if !(settings["ModelPower"] == 1)
        ## Feedstock electricity consumption of "generation" from resource "g" during hour "t"
        @expression(
            MESS,
            eHElectricityConsumptionByGen[f in eachindex(Electricity_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vHGen][g, t] * dfGen[!, :Electricity_Rate_MWh_per_tonne][g] for
                g in intersect(
                    dfGen[dfGen.Electricity .== Electricity_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                );
                init = 0.0,
            )
        )

        ## Add electricity feedstock consumption
        add_to_expression!.(MESS[:eHElectricityConsumption], MESS[:eHElectricityConsumptionByGen])

        ## Feedstock electricity purchasing costs from resource "g" during hour "t"
        @expression(
            MESS,
            eHObjVarElectricityOG[g in 1:G],
            if dfGen[!, :Electricity][g] in Electricity_Index
                sum(
                    MESS[:vHGen][g, t] *
                    dfGen[!, :Electricity_Rate_MWh_per_tonne][g] *
                    electricity_costs[dfGen[!, :Electricity][g]][t] for t in 1:T;
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
            eHCarbonConsumptionByGen[f in eachindex(Carbon_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vHGen][g, t] * dfGen[!, :Carbon_Rate_tonne_per_tonne][g] for g in intersect(
                    dfGen[dfGen.Carbon .== Carbon_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                );
                init = 0.0,
            )
        )

        ## Add carbon feedstock consumption
        add_to_expression!.(MESS[:eHCarbonConsumption], MESS[:eHCarbonConsumptionByGen])
    end

    if !(settings["ModelBioenergy"] == 1)
        ## Feedstock bioenergy consumption of "generation" from resource "g" during hour "t"
        @expression(
            MESS,
            eHBioenergyConsumptionByGen[f in eachindex(Bioenergy_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vHGen][g, t] * dfGen[!, :Bioenergy_Rate_MMBTU_per_tonne][g] for
                g in intersect(
                    dfGen[dfGen.Bioenergy .== Bioenergy_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                );
                init = 0.0,
            )
        )

        ## Add bioenergy feedstock consumption
        add_to_expression!.(MESS[:eHBioenergyConsumption], MESS[:eHBioenergyConsumptionByGen])

        ## Feedstock bioenergy purchasing costs from resource "g" during hour "t" - marginal price not valid
        @expression(
            MESS,
            eHObjVarBioenergyOG[g in 1:G],
            if dfGen[!, :Bioenergy][g] in Bioenergy_Index
                sum(
                    MESS[:vHGen][g, t] *
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
    if hydrogen_settings["ModelFLH"] == 1
        @constraint(
            MESS,
            cHGenFullLoadHours[g in 1:G],
            sum(weights[t] * MESS[:vHGen][g, t] for t in 1:T) <=
            MESS[:eHGenCap][g] * dfGen[!, :Full_Load_Hours][g],
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

    ## Specific generation types - eligiable for unit commitment
    if !isempty(COMMIT)
        MESS = generation_commit(settings, inputs, MESS)
    end

    ## Specific generation types - not eligible for unit commitment
    if !isempty(NO_COMMIT)
        MESS = generation_no_commit(settings, inputs, MESS)
    end

    ## Specific generation types - steam methane reformation resources
    if !isempty(SMR)
        MESS = generation_smr(settings, inputs, MESS)
    end

    ## Specific generation types - coal gasification resources
    if !isempty(CGF)
        MESS = generation_cgf(settings, inputs, MESS)
    end

    ## Specific generation types - biomass gasification resources
    if !isempty(BMG)
        MESS = generation_bmg(settings, inputs, MESS)
    end

    ## Specific generation types - ccs resources
    if !isempty(CCS)
        MESS = generation_ccs(settings, inputs, MESS)
    end

    return MESS
end
