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

    print_and_log(settings, "i", "Ammonia Consumption Module")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]
        fuels_costs = inputs["fuels_costs"]
        ### Add ammonia sector fuel consumption to the total fuel consumption
        add_to_expression!.(MESS[:eFuelsConsumption], MESS[:eAFuelsConsumption])
        ### Expenses for purchasing fuels from markets in ammonia sector
        @expression(
            MESS,
            eAObjExpensesFuelsOF[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            fuels_costs[Fuels_Index[f]][t] * MESS[:eAFuelsConsumption][f, z, t]
        )
        @expression(
            MESS,
            eAObjExpensesFuels[z in 1:Z, t in 1:T],
            sum(MESS[:eAObjExpensesFuelsOF][f, z, t] for f in eachindex(Fuels_Index))
        )
        add_to_expression!.(MESS[:eAObjExpenses], MESS[:eAObjExpensesFuels])
    end

    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
        electricity_costs = inputs["electricity_costs"]
        ### Add ammonia sector electricity consumption to the total electricity consumption
        add_to_expression!.(MESS[:eElectricityConsumption], MESS[:eAElectricityConsumption])
        ### Expenses for purchasing electricity from markets in ammonia sector
        @expression(
            MESS,
            eAObjExpensesElectricityOF[f in eachindex(Electricity_Index), z in 1:Z, t in 1:T],
            electricity_costs[Electricity_Index[f]][t] * MESS[:eAElectricityConsumption][f, z, t]
        )
        @expression(
            MESS,
            eAObjExpensesElectricity[z in 1:Z, t in 1:T],
            sum(MESS[:eAObjExpensesElectricityOF][f, z, t] for f in eachindex(Electricity_Index))
        )
        add_to_expression!.(MESS[:eAObjExpenses], MESS[:eAObjExpensesElectricity])
    end

    if !(settings["ModelHydrogen"] == 1)
        Hydrogen_Index = inputs["Hydrogen_Index"]
        hydrogen_costs = inputs["hydrogen_costs"]
        ### Add ammonia sector hydrogen consumption to the total hydrogen consumption
        add_to_expression!.(MESS[:eHydrogenConsumption], MESS[:eAHydrogenConsumption])
        ### Expenses for purchasing hydrogen from markets in ammonia sector
        @expression(
            MESS,
            eAObjExpensesHydrogenOF[f in eachindex(Hydrogen_Index), z in 1:Z, t in 1:T],
            hydrogen_costs[Hydrogen_Index[f]][t] * MESS[:eAHydrogenConsumption][f, z, t]
        )
        @expression(
            MESS,
            eAObjExpensesHydrogen[z in 1:Z, t in 1:T],
            sum(MESS[:eAObjExpensesHydrogenOF][f, z, t] for f in eachindex(Hydrogen_Index))
        )
        add_to_expression!.(MESS[:eAObjExpenses], MESS[:eAObjExpensesHydrogen])
    end

    if !(settings["ModelBioenergy"] == 1)
        Bioenergy_Index = inputs["Bioenergy_Index"]
        bioenergy_costs = inputs["bioenergy_costs"]
        ### Add ammonia sector bioenergy consumption to the total bioenergy consumption
        add_to_expression!.(MESS[:eBioenergyConsumption], MESS[:eABioenergyConsumption])
        ### Expenses for purchasing bioenergy from markets in ammonia sector
        @expression(
            MESS,
            eAObjExpensesBioenergyOF[f in eachindex(Bioenergy_Index), z in 1:Z, t in 1:T],
            bioenergy_costs[Bioenergy_Index[f]][t] * MESS[:eABioenergyConsumption][f, z, t]
        )
        @expression(
            MESS,
            eAObjExpensesBioenergy[z in 1:Z, t in 1:T],
            sum(MESS[:eAObjExpensesBioenergyOF][f, z, t] for f in eachindex(Bioenergy_Index))
        )
        add_to_expression!.(MESS[:eAObjExpenses], MESS[:eAObjExpensesBioenergy])
    end

    ## Add expenses for purchasing feedstocks from markets to objective function in ammonia sector
    @expression(
        MESS,
        eAObjFeedStockOZ[z in 1:Z],
        sum(MESS[:eAObjExpenses][z, t] for t in 1:T; init = 0.0)
    )
    @expression(MESS, eAObjFeedStock, sum(MESS[:eAObjFeedStockOZ][z] for z in 1:Z; init = 0.0))
    ## Add term to objective function expression
    add_to_expression!(MESS[:eAObj], eAObjFeedStock)

    return MESS
end
