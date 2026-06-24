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
function consumption(settings::Dict, inputs::Dict, MESS::Model)

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    if settings["ModelPower"] == 1
        power_settings = settings["PowerSettings"]
        QuadricEmission = power_settings["QuadricEmission"]
    else
        QuadricEmission = 0
    end

    ### Expenses for purchasing fuels from markets
    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]
        fuels_costs = inputs["fuels_costs"]
        @expression(
            MESS,
            eObjExpensesFuelsOF[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            fuels_costs[Fuels_Index[f]][t] * MESS[:eFuelsConsumption][f, z, t]
        )
        @expression(
            MESS,
            eObjExpensesFuels[z in 1:Z, t in 1:T],
            sum(MESS[:eObjExpensesFuelsOF][f, z, t] for f in eachindex(Fuels_Index))
        )
        if QuadricEmission == 1
            MESS[:eObjExpenses] += MESS[:eObjExpensesFuels]
        else
            add_to_expression!.(MESS[:eObjExpenses], MESS[:eObjExpensesFuels])
        end
    end

    ### Expenses for purchasing electricity from markets
    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
        electricity_costs = inputs["electricity_costs"]
        @expression(
            MESS,
            eObjExpensesElectricityOF[f in eachindex(Electricity_Index), z in 1:Z, t in 1:T],
            electricity_costs[Electricity_Index[f]][t] * MESS[:eElectricityConsumption][f, z, t]
        )
        @expression(
            MESS,
            eObjExpensesElectricity[z in 1:Z, t in 1:T],
            sum(MESS[:eObjExpensesElectricityOF][f, z, t] for f in eachindex(Electricity_Index))
        )
        add_to_expression!.(MESS[:eObjExpenses], MESS[:eObjExpensesElectricity])
    end

    ### Expenses for purchasing hydrogen from markets
    if !(settings["ModelHydrogen"] == 1)
        Hydrogen_Index = inputs["Hydrogen_Index"]
        hydrogen_costs = inputs["hydrogen_costs"]
        @expression(
            MESS,
            eObjExpensesHydrogenOF[f in eachindex(Hydrogen_Index), z in 1:Z, t in 1:T],
            hydrogen_costs[Hydrogen_Index[f]][t] * MESS[:eHydrogenConsumption][f, z, t]
        )
        @expression(
            MESS,
            eObjExpensesHydrogen[z in 1:Z, t in 1:T],
            sum(MESS[:eObjExpensesHydrogenOF][f, z, t] for f in eachindex(Hydrogen_Index))
        )
        add_to_expression!.(MESS[:eObjExpenses], MESS[:eObjExpensesHydrogen])
    end

    ### Expenses for purchasing carbon from markets
    if !(settings["ModelCarbon"] == 1)
        Carbon_Index = inputs["Carbon_Index"]
        carbon_costs = inputs["carbon_costs"]
        @expression(
            MESS,
            eObjExpensesCarbonOF[f in eachindex(Carbon_Index), z in 1:Z, t in 1:T],
            carbon_costs[Carbon_Index[f]][t] * MESS[:eCarbonConsumption][f, z, t]
        )
        @expression(
            MESS,
            eObjExpensesCarbon[z in 1:Z, t in 1:T],
            sum(MESS[:eObjExpensesCarbonOF][f, z, t] for f in eachindex(Carbon_Index))
        )
        add_to_expression!.(MESS[:eObjExpenses], MESS[:eObjExpensesCarbon])
    end

    ### Expenses for purchasing bioenergy from markets
    if !(settings["ModelBioenergy"] == 1)
        Bioenergy_Index = inputs["Bioenergy_Index"]
        bioenergy_costs = inputs["bioenergy_costs"]
        @expression(
            MESS,
            eObjExpensesBioenergyOF[f in eachindex(Bioenergy_Index), z in 1:Z, t in 1:T],
            bioenergy_costs[Bioenergy_Index[f]][t] * MESS[:eBioenergyConsumption][f, z, t]
        )
        @expression(
            MESS,
            eObjExpensesBioenergy[z in 1:Z, t in 1:T],
            sum(MESS[:eObjExpensesBioenergyOF][f, z, t] for f in eachindex(Bioenergy_Index))
        )
        add_to_expression!.(MESS[:eObjExpenses], MESS[:eObjExpensesBioenergy])
    end

    return MESS
end
