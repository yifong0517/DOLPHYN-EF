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
	capture_all(settings::Dict, inputs::Dict, MESS::Model)

"""
function capture_all(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Carbon Capture Direct Air Core Module")

    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    carbon_settings = settings["CarbonSettings"]

    ## Fuels costs from markets
    fuels_costs = inputs["fuels_costs"]

    Fuels_Index = inputs["Fuels_Index"]
    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
        electricity_costs = inputs["electricity_costs"]
    end
    if !(settings["ModelHydrogen"] == 1)
        Hydrogen_Index = inputs["Hydrogen_Index"]
        hydrogen_costs = inputs["hydrogen_costs"]
    end
    if !(settings["ModelBioenergy"] == 1)
        Bioenergy_Index = inputs["Bioenergy_Index"]
        bioenergy_costs = inputs["bioenergy_costs"]
    end

    ## Get generators' data from dataframe
    carbon_inputs = inputs["CarbonInputs"]
    dfGen = carbon_inputs["dfGen"]

    G = carbon_inputs["G"]
    THERM = carbon_inputs["THERM"]
    COMMIT = carbon_inputs["COMMIT"]
    NO_COMMIT = carbon_inputs["NO_COMMIT"]
    ResourceType = carbon_inputs["GenResourceType"]

    ### Variables ###
    ## Captured carbon injected into the grid by resource "g" at hour "t"
    @variable(MESS, vCCap[g in 1:G, t in 1:T] >= 0)

    if !isempty(COMMIT)
        ## Decision variables for unit commitment
        ## Unit commitment state variable
        @variable(MESS, vCOnline[g in COMMIT, t in 1:T] >= 0)
        ## Unit startup event variable
        @variable(MESS, vCStart[g in COMMIT, t in 1:T] >= 0)
        ## Unit shutdown event variable
        @variable(MESS, vCShut[g in COMMIT, t in 1:T] >= 0)
    end

    ### Expressions ###
    ## Objective Expressions ##
    ## Variable costs of "capture" for resource "g" during hour "t" = variable O&M
    @expression(
        MESS,
        eCObjVarCapOGT[g in 1:G, t in 1:T],
        weights[t] * dfGen[!, :Var_OM_Cost_per_tonne][g] * MESS[:vCCap][g, t]
    )
    @expression(
        MESS,
        eCObjVarCapOG[g in 1:G],
        sum(MESS[:eCObjVarCapOGT][g, t] for t in 1:T; init = 0.0)
    )
    @expression(MESS, eCObjVarCap, sum(MESS[:eCObjVarCapOG][g] for g in 1:G; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eCObj], MESS[:eCObjVarCap])
    ## End Objective Expressions ##

    ## Carbon sector capture from direct air
    @expression(MESS, eCCaptureDirectAir[z in 1:Z, t in 1:T], AffExpr(0))

    @expression(
        MESS,
        eCCaptureOZRT[z in 1:Z, rt in ResourceType],
        sum(
            MESS[:vCCap][g, t] * weights[t] for
            g in dfGen[(dfGen.Zone .== Zones[z]) .& (dfGen.Resource_Type .== rt), :R_ID], t in 1:T;
            init = 0.0,
        )
    )

    @expression(
        MESS,
        eCCaptureORTT[rt in ResourceType, t in 1:T],
        sum(MESS[:vCCap][g, t] for g in dfGen[dfGen.Resource_Type .== rt, :R_ID]; init = 0.0)
    )
    ## Carbon sector emissions
    @expression(
        MESS,
        eCEmissionsOGT[g = 1:G, t = 1:T],
        if g in COMMIT
            dfGen[!, :CO2_tonne_per_tonne][g] * MESS[:vCCap][g, t] +
            dfGen[!, :CO2_tonne_per_Start][g] * MESS[:vCStart][g, t]
        else
            dfGen[!, :CO2_tonne_per_tonne][g] * MESS[:vCCap][g, t]
        end
    )

    @expression(
        MESS,
        eCEmissionsByCap[z = 1:Z, t = 1:T],
        sum(eCEmissionsOGT[g, t] for g in dfGen[dfGen.Zone .== Zones[z], :R_ID]; init = 0.0)
    )
    add_to_expression!.(MESS[:eCEmissions], MESS[:eCEmissionsByCap])

    ## Sub zonal capture expressions
    if carbon_settings["SubZone"] == 1
        SubZones = carbon_inputs["SubZones"]
        ## Carbon sector sub zonal capture expression
        @expression(MESS, eCCaptureSubZonal[z in SubZones, t in 1:T], AffExpr(0))
        ## Sub zonal emissions from capture expression
        @expression(
            MESS,
            eCEmissionsSubZonalByCap[z in SubZones, t = 1:T],
            sum(eCEmissionsByCap[g, t] for g in dfGen[dfGen.SubZone .== z, :R_ID]; init = 0.0)
        )
    end

    ## Feedstock fuel consumption of "capture" from resource "g" during hour "t"
    @expression(
        MESS,
        eCFuelsConsumptionByCap[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
        sum(
            MESS[:vCCap][g, t] * dfGen[!, :Heat_Rate_MMBTU_per_tonne][g] for g in intersect(
                dfGen[dfGen.Fuel .== Fuels_Index[f], :R_ID],
                dfGen[dfGen.Zone .== Zones[z], :R_ID],
            );
            init = 0.0,
        )
    )

    ## Feedstock fuel consumption costs from resource "g" during hour "t"
    @expression(
        MESS,
        eCObjVarFuelOG[g in 1:G],
        if dfGen[!, :Fuel][g] in Fuels_Index
            sum(
                MESS[:vCCap][g, t] *
                dfGen[!, :Heat_Rate_MMBTU_per_tonne][g] *
                fuels_costs[dfGen[!, :Fuel][g]][t] for t in 1:T;
                init = 0.0,
            )
        else
            0
        end
    )

    ## Add fuel feedstock consumption
    add_to_expression!.(MESS[:eCFuelsConsumption], MESS[:eCFuelsConsumptionByCap])

    ##TODO: When direct air capture could be differentiated into electricity-powered
    ## hydrogen-powered and bioenergy-powered, these expressions should be updated in
    ## seperate capture type scripts
    if !(settings["ModelPower"] == 1)
        ## Feedstock electricity consumption of "capture" from resource "g" during hour "t"
        @expression(
            MESS,
            eCElectricityConsumptionByCap[f in eachindex(Electricity_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vCCap][g, t] * dfGen[!, :Electricity_Rate_MWh_per_tonne][g] for
                g in intersect(
                    dfGen[dfGen.Electricity .== Electricity_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                );
                init = 0.0,
            )
        )

        ## Add electricity feedstock consumption
        add_to_expression!.(MESS[:eCElectricityConsumption], MESS[:eCElectricityConsumptionByCap])

        ## Feedstock electricity purchasing costs from resource "g" during hour "t"
        @expression(
            MESS,
            eCObjVarElectricityOG[g in 1:G],
            if dfGen[!, :Electricity][g] in Electricity_Index
                sum(
                    MESS[:vCCap][g, t] *
                    dfGen[!, :Electricity_Rate_MWh_per_tonne][g] *
                    electricity_costs[dfGen[!, :Electricity][g]][t] for t in 1:T;
                    init = 0.0,
                )
            else
                0
            end
        )
    else
        ## Electricity consumption of "capture" from resource "g" during hour "t"
        @expression(
            MESS,
            ePBalanceCCap[z in 1:Z, t in 1:T],
            sum(
                MESS[:vCCap][g, t] * dfGen[!, :Electricity_Rate_MWh_per_tonne][g] for
                g in dfGen[dfGen.Zone .== Zones[z], :R_ID];
                init = 0.0,
            )
        )

        ## Add power balance
        add_to_expression!.(MESS[:ePBalance], -MESS[:ePBalanceCCap])
        add_to_expression!.(MESS[:ePDemandAddition], MESS[:ePBalanceCCap])
    end

    if !(settings["ModelHydrogen"] == 1)
        ## Feedstock hydrogen consumption of "capture" from resource "g" during hour "t"
        @expression(
            MESS,
            eCHydrogenConsumptionByCap[f in eachindex(Hydrogen_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vCCap][g, t] * dfGen[!, :Hydrogen_Rate_tonne_per_tonne][g] for g in intersect(
                    dfGen[dfGen.Hydrogen .== Hydrogen_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                );
                init = 0.0,
            )
        )

        ## Add hydrogen feedstock consumption
        add_to_expression!.(MESS[:eCHydrogenConsumption], MESS[:eCHydrogenConsumptionByCap])

        ## Feedstock hydrogen purchasing costs from resource "g" during hour "t"
        @expression(
            MESS,
            eCObjVarHydrogenOG[g in 1:G],
            if dfGen[!, :Hydrogen][g] in Hydrogen_Index
                sum(
                    MESS[:vCCap][g, t] *
                    dfGen[!, :Hydrogen_Rate_tonne_per_tonne][g] *
                    hydrogen_costs[dfGen[!, :Hydrogen][g]][t] for t in 1:T;
                    init = 0.0,
                )
            else
                0
            end
        )
    else
        ## Hydrogen consumption of "capture" from resource "g" during hour "t"
        @expression(
            MESS,
            eHBalanceSCap[z in 1:Z, t in 1:T],
            sum(
                MESS[:vCCap][g, t] * dfGen[!, :Hydrogen_Rate_tonne_per_tonne][g] for
                g in dfGen[dfGen.Zone .== Zones[z], :R_ID];
                init = 0.0,
            )
        )

        ## Add power balance
        add_to_expression!.(MESS[:eHBalance], -MESS[:eHBalanceSCap])
        add_to_expression!.(MESS[:eHDemandAddition], MESS[:eHBalanceSCap])
    end

    if !(settings["ModelBioenergy"] == 1)
        ## Feedstock bioenergy consumption of "capture" from resource "g" during hour "t"
        @expression(
            MESS,
            eCBioenergyConsumptionByCap[f in eachindex(Bioenergy_Index), z in 1:Z, t in 1:T],
            sum(
                MESS[:vCCap][g, t] * dfGen[!, :Bioenergy_Rate_MMBTU_per_tonne][g] for
                g in intersect(
                    dfGen[dfGen.Bioenergy .== Bioenergy_Index[f], :R_ID],
                    dfGen[dfGen.Zone .== Zones[z], :R_ID],
                );
                init = 0.0,
            )
        )

        ## Add bioenergy feedstock consumption
        add_to_expression!.(MESS[:eCBioenergyConsumption], MESS[:eCBioenergyConsumptionByCap])

        ## Feedstock bioenergy purchasing costs from resource "g" during hour "t" - marginal price not valid
        @expression(
            MESS,
            eCObjVarBioenergyOG[g in 1:G],
            if dfGen[!, :Bioenergy][g] in Bioenergy_Index
                sum(
                    MESS[:vCCap][g, t] *
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
    if carbon_settings["ModelFLH"] == 1
        @constraint(
            MESS,
            cCGenFullLoadHours[g in 1:G],
            sum(weights[t] * MESS[:vCCap][g, t] for t in 1:T) <=
            MESS[:eCCaptureCap][g] * dfGen[!, :FullLoadHours][g],
        )
    end
    ### End Constraints ###

    ## Specific capture types - thermal resources
    if !isempty(THERM)
        MESS = capture_thermal(settings, inputs, MESS)
    end

    ## Specific capture types - eligiable for unit commitment
    if !isempty(COMMIT)
        MESS = capture_commit(settings, inputs, MESS)
    end

    ## Specific capture types - not eligible for unit commitment
    if !isempty(NO_COMMIT)
        MESS = capture_no_commit(settings, inputs, MESS)
    end

    return MESS
end
