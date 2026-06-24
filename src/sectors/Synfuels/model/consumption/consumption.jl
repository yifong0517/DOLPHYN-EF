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

    print_and_log(settings, "i", "Synfuels Consumption Module")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]
        fuels_costs = inputs["fuels_costs"]
        ### Add synfuels sector fuel consumption to the total fuel consumption
        add_to_expression!.(MESS[:eFuelsConsumption], MESS[:eSFuelsConsumption])
        ### Expenses for purchasing fuels from markets in synfuels sector
        @expression(
            MESS,
            eSObjExpensesFuelsOF[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            fuels_costs[Fuels_Index[f]][t] * MESS[:eSFuelsConsumption][f, z, t]
        )
        @expression(
            MESS,
            eSObjExpensesFuels[z in 1:Z, t in 1:T],
            sum(MESS[:eSObjExpensesFuelsOF][f, z, t] for f in eachindex(Fuels_Index))
        )
        add_to_expression!.(MESS[:eSObjExpenses], MESS[:eSObjExpensesFuels])
    end

    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
        electricity_costs = inputs["electricity_costs"]
        ### Add synfuels sector electricity consumption to the total electricity consumption
        add_to_expression!.(MESS[:eElectricityConsumption], MESS[:eSElectricityConsumption])
        ### Expenses for purchasing electricity from markets in synfuels sector
        @expression(
            MESS,
            eSObjExpensesElectricityOF[f in eachindex(Electricity_Index), z in 1:Z, t in 1:T],
            electricity_costs[Electricity_Index[f]][t] * MESS[:eSElectricityConsumption][f, z, t]
        )
        @expression(
            MESS,
            eSObjExpensesElectricity[z in 1:Z, t in 1:T],
            sum(MESS[:eSObjExpensesElectricityOF][f, z, t] for f in eachindex(Electricity_Index))
        )
        add_to_expression!.(MESS[:eSObjExpenses], MESS[:eSObjExpensesElectricity])
    end

    if !(settings["ModelHydrogen"] == 1)
        Hydrogen_Index = inputs["Hydrogen_Index"]
        hydrogen_costs = inputs["hydrogen_costs"]
        ### Add synfuels sector hydrogen consumption to the total hydrogen consumption
        add_to_expression!.(MESS[:eHydrogenConsumption], MESS[:eSHydrogenConsumption])
        ### Expenses for purchasing hydrogen from markets in synfuels sector
        @expression(
            MESS,
            eSObjExpensesHydrogenOF[f in eachindex(Hydrogen_Index), z in 1:Z, t in 1:T],
            hydrogen_costs[Hydrogen_Index[f]][t] * MESS[:eSHydrogenConsumption][f, z, t]
        )
        @expression(
            MESS,
            eSObjExpensesHydrogen[z in 1:Z, t in 1:T],
            sum(MESS[:eSObjExpensesHydrogenOF][f, z, t] for f in eachindex(Hydrogen_Index))
        )
        add_to_expression!.(MESS[:eSObjExpenses], MESS[:eSObjExpensesHydrogen])
    end

    if !(settings["ModelCarbon"] == 1)
        Carbon_Index = inputs["Carbon_Index"]
        carbon_costs = inputs["carbon_costs"]
        ### Add synfuels sector carbon consumption to the total carbon consumption
        add_to_expression!.(MESS[:eCarbonConsumption], MESS[:eSCarbonConsumption])
        ### Expenses for purchasing carbon from markets in synfuels sector
        @expression(
            MESS,
            eSObjExpensesCarbonOF[f in eachindex(Carbon_Index), z in 1:Z, t in 1:T],
            carbon_costs[Carbon_Index[f]][t] * MESS[:eSCarbonConsumption][f, z, t]
        )
        @expression(
            MESS,
            eSObjExpensesCarbon[z in 1:Z, t in 1:T],
            sum(MESS[:eSObjExpensesCarbonOF][f, z, t] for f in eachindex(Carbon_Index))
        )
        add_to_expression!.(MESS[:eSObjExpenses], MESS[:eSObjExpensesCarbon])
    end

    if !(settings["ModelBioenergy"] == 1)
        Bioenergy_Index = inputs["Bioenergy_Index"]
        bioenergy_costs = inputs["bioenergy_costs"]
        ### Add synfuels sector bioenergy consumption to the total bioenergy consumption
        add_to_expression!.(MESS[:eBioenergyConsumption], MESS[:eSBioenergyConsumption])
        ### Expenses for purchasing bioenergy from markets in synfuels sector
        @expression(
            MESS,
            eSObjExpensesBioenergyOF[f in eachindex(Bioenergy_Index), z in 1:Z, t in 1:T],
            bioenergy_costs[Bioenergy_Index[f]][t] * MESS[:eSBioenergyConsumption][f, z, t]
        )
        @expression(
            MESS,
            eSObjExpensesBioenergy[z in 1:Z, t in 1:T],
            sum(MESS[:eSObjExpensesBioenergyOF][f, z, t] for f in eachindex(Bioenergy_Index))
        )
        add_to_expression!.(MESS[:eSObjExpenses], MESS[:eSObjExpensesBioenergy])
    end

    ## Add expenses for purchasing feedstocks from markets to objective function in synfuels sector
    @expression(
        MESS,
        eSObjFeedStockOZ[z in 1:Z],
        sum(MESS[:eSObjExpenses][z, t] for t in 1:T; init = 0.0)
    )
    @expression(MESS, eSObjFeedStock, sum(MESS[:eSObjFeedStockOZ][z] for z in 1:Z; init = 0.0))
    add_to_expression!(MESS[:eSObj], eSObjFeedStock)

    return MESS
end
