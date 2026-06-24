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

    print_and_log(settings, "i", "Foodstuff Sector Consumption Module")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    ## Feedstock consumption including fuels, electriicty from markets
    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]
        fuels_costs = inputs["fuels_costs"]
        ### Add foodstuff sector fuel consumption to total fuel consumption
        add_to_expression!.(MESS[:eFuelsConsumption], MESS[:eFFuelsConsumption])
        ### Expenses for purchasing fuels from markets in foodstuff sector
        @expression(
            MESS,
            eFObjExpensesFuelsOF[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            fuels_costs[Fuels_Index[f]][t] * MESS[:eFFuelsConsumption][f, z, t]
        )
        @expression(
            MESS,
            eFObjExpensesFuels[z in 1:Z, t in 1:T],
            sum(MESS[:eFObjExpensesFuelsOF][f, z, t] for f in eachindex(Fuels_Index))
        )
        add_to_expression!.(MESS[:eFObjExpenses], MESS[:eFObjExpensesFuels])
    end

    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
        electricity_costs = inputs["electricity_costs"]
        ### Add foodstuff sector electricity consumption to total electricity consumption
        add_to_expression!.(MESS[:eElectricityConsumption], MESS[:eFElectricityConsumption])
        ### Expenses for purchasing electricity from markets in foodstuff sector
        @expression(
            MESS,
            eFObjExpensesElectricityOF[f in eachindex(Electricity_Index), z in 1:Z, t in 1:T],
            electricity_costs[Electricity_Index[f]][t] * MESS[:eFElectricityConsumption][f, z, t]
        )
        @expression(
            MESS,
            eFObjExpensesElectricity[z in 1:Z, t in 1:T],
            sum(MESS[:eFObjExpensesElectricityOF][f, z, t] for f in eachindex(Electricity_Index))
        )
        add_to_expression!.(MESS[:eFObjExpenses], MESS[:eFObjExpensesElectricity])
    end

    if !(settings["ModelHydrogen"] == 1)
        Hydrogen_Index = inputs["Hydrogen_Index"]
        hydrogen_costs = inputs["hydrogen_costs"]
        ### Add foodstuff sector hydrogen consumption to total hydrogen consumption
        add_to_expression!.(MESS[:eHydrogenConsumption], MESS[:eFHydrogenConsumption])
        ### Expenses for purchasing hydrogen from markets in foodstuff sector
        @expression(
            MESS,
            eFObjExpensesHydrogenOF[f in eachindex(Hydrogen_Index), z in 1:Z, t in 1:T],
            hydrogen_costs[Hydrogen_Index[f]][t] * MESS[:eFHydrogenConsumption][f, z, t]
        )
        @expression(
            MESS,
            eFObjExpensesHydrogen[z in 1:Z, t in 1:T],
            sum(MESS[:eFObjExpensesHydrogenOF][f, z, t] for f in eachindex(Hydrogen_Index))
        )
        add_to_expression!.(MESS[:eFObjExpenses], MESS[:eFObjExpensesHydrogen])
    end

    if !(settings["ModelCarbon"] == 1)
        Carbon_Index = inputs["Carbon_Index"]
        carbon_costs = inputs["carbon_costs"]
        ### Add foodstuff sector carbon consumption to total carbon consumption
        add_to_expression!.(MESS[:eCarbonConsumption], MESS[:eFCarbonConsumption])
        ### Expenses for purchasing carbon from markets in foodstuff sector
        @expression(
            MESS,
            eFObjExpensesCarbonOF[f in eachindex(Carbon_Index), z in 1:Z, t in 1:T],
            carbon_costs[Carbon_Index[f]][t] * MESS[:eFCarbonConsumption][f, z, t]
        )
        @expression(
            MESS,
            eFObjExpensesCarbon[z in 1:Z, t in 1:T],
            sum(MESS[:eFObjExpensesCarbonOF][f, z, t] for f in eachindex(Carbon_Index))
        )
        add_to_expression!.(MESS[:eFObjExpenses], MESS[:eFObjExpensesCarbon])
    end

    ## Add expenses for purchasing feedstocks from markets to objective function in power sector
    @expression(
        MESS,
        eFObjFeedStockOZ[z in 1:Z],
        sum(MESS[:eFObjExpenses][z, t] for t in 1:T; init = 0.0)
    )
    @expression(MESS, eFObjFeedStock, sum(MESS[:eFObjFeedStockOZ][z] for z in 1:Z; init = 0.0))
    add_to_expression!(MESS[:eFObj], eFObjFeedStock)

    return MESS
end
