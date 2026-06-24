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

    print_and_log(settings, "i", "Power Consumption Module")

    power_setting = settings["PowerSettings"]
    QuadricEmission = power_setting["QuadricEmission"]

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]
        fuels_costs = inputs["fuels_costs"]

        ### Add power sector fuel consumption to total fuel consumption
        if QuadricEmission == 1
            MESS[:eFuelsConsumption] += MESS[:ePFuelsConsumption]
        else
            add_to_expression!.(MESS[:eFuelsConsumption], MESS[:ePFuelsConsumption])
        end
        ### Expenses for purchasing fuels from markets in power sector
        @expression(
            MESS,
            ePObjExpensesFuelsOF[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            fuels_costs[Fuels_Index[f]][t] * MESS[:ePFuelsConsumption][f, z, t]
        )
        @expression(
            MESS,
            ePObjExpensesFuels[z in 1:Z, t in 1:T],
            sum(MESS[:ePObjExpensesFuelsOF][f, z, t] for f in eachindex(Fuels_Index))
        )
        if QuadricEmission == 1
            MESS[:ePObjExpenses] += MESS[:ePObjExpensesFuels]
        else
            add_to_expression!.(MESS[:ePObjExpenses], MESS[:ePObjExpensesFuels])
        end
    end

    if !(settings["ModelHydrogen"] == 1)
        Hydrogen_Index = inputs["Hydrogen_Index"]
        hydrogen_costs = inputs["hydrogen_costs"]
        ### Add power sector hydrogen consumption to total hydrogen consumption
        add_to_expression!.(MESS[:eHydrogenConsumption], MESS[:ePHydrogenConsumption])
        ### Expenses for purchasing hydrogen from markets in power sector
        @expression(
            MESS,
            ePObjExpensesHydrogenOF[f in eachindex(Hydrogen_Index), z in 1:Z, t in 1:T],
            hydrogen_costs[Hydrogen_Index[f]][t] * MESS[:ePHydrogenConsumption][f, z, t]
        )
        @expression(
            MESS,
            ePObjExpensesHydrogen[z in 1:Z, t in 1:T],
            sum(MESS[:ePObjExpensesHydrogenOF][f, z, t] for f in eachindex(Hydrogen_Index))
        )
        add_to_expression!.(MESS[:ePObjExpenses], MESS[:ePObjExpensesHydrogen])
    end

    if !(settings["ModelCarbon"] == 1)
        Carbon_Index = inputs["Carbon_Index"]
        carbon_costs = inputs["carbon_costs"]
        ### Add power sector carbon consumption to total carbon consumption
        add_to_expression!.(MESS[:eCarbonConsumption], MESS[:ePCarbonConsumption])
        ### Expenses for purchasing carbon from markets in power sector
        @expression(
            MESS,
            ePObjExpensesCarbonOF[f in eachindex(Carbon_Index), z in 1:Z, t in 1:T],
            carbon_costs[Carbon_Index[f]][t] * MESS[:ePCarbonConsumption][f, z, t]
        )
        @expression(
            MESS,
            ePObjExpensesCarbon[z in 1:Z, t in 1:T],
            sum(MESS[:ePObjExpensesCarbonOF][f, z, t] for f in eachindex(Carbon_Index))
        )
        add_to_expression!.(MESS[:ePObjExpenses], MESS[:ePObjExpensesCarbon])
    end

    if !(settings["ModelBioenergy"] == 1)
        Bioenergy_Index = inputs["Bioenergy_Index"]
        bioenergy_costs = inputs["bioenergy_costs"]
        ### Add power sector bioenergy consumption to total bioenergy consumption
        add_to_expression!.(MESS[:eBioenergyConsumption], MESS[:ePBioenergyConsumption])
        ### Expenses for purchasing bioenergy from markets in power sector
        @expression(
            MESS,
            ePObjExpensesBioenergyOF[f in eachindex(Bioenergy_Index), z in 1:Z, t in 1:T],
            bioenergy_costs[Bioenergy_Index[f]][t] * MESS[:ePBioenergyConsumption][f, z, t]
        )
        @expression(
            MESS,
            ePObjExpensesBioenergy[z in 1:Z, t in 1:T],
            sum(MESS[:ePObjExpensesBioenergyOF][f, z, t] for f in eachindex(Bioenergy_Index))
        )
        add_to_expression!.(MESS[:ePObjExpenses], MESS[:ePObjExpensesBioenergy])
    end

    ## Add expenses for purchasing feedstocks from markets to objective function in power sector
    @expression(
        MESS,
        ePObjFeedStockOZ[z in 1:Z],
        sum(MESS[:ePObjExpenses][z, t] for t in 1:T; init = 0.0)
    )
    @expression(MESS, ePObjFeedStock, sum(MESS[:ePObjFeedStockOZ][z] for z in 1:Z; init = 0.0))
    if QuadricEmission == 1
        MESS[:ePObj] += MESS[:ePObjFeedStock]
    else
        add_to_expression!.(MESS[:ePObj], MESS[:ePObjFeedStock])
    end

    return MESS
end
