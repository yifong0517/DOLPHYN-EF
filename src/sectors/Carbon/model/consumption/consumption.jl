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

    print_and_log(settings, "i", "Carbon Consumption Module")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    Fuels_Index = inputs["Fuels_Index"]
    fuels_costs = inputs["fuels_costs"]
    ### Add carbon sector fuel consumption into total fuel consumption
    add_to_expression!.(MESS[:eFuelsConsumption], MESS[:eCFuelsConsumption])
    ### Expenses for purchasing fuels from markets in power sector
    @expression(
        MESS,
        eCObjExpensesFuelsOF[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
        fuels_costs[Fuels_Index[f]][t] * MESS[:eCFuelsConsumption][f, z, t]
    )
    @expression(
        MESS,
        eCObjExpensesFuels[z in 1:Z, t in 1:T],
        sum(MESS[:eCObjExpensesFuelsOF][f, z, t] for f in eachindex(Fuels_Index))
    )
    add_to_expression!.(MESS[:eCObjExpenses], eCObjExpensesFuels)

    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
        electricity_costs = inputs["electricity_costs"]
        ### Add carbon sector electricity consumption into total electricity consumption
        add_to_expression!.(MESS[:eElectricityConsumption], MESS[:eCElectricityConsumption])
        ### Expenses for purchasing electricity from markets in power sector
        @expression(
            MESS,
            eCObjExpensesElectricityOF[f in eachindex(Electricity_Index), z in 1:Z, t in 1:T],
            electricity_costs[Electricity_Index[f]][t] * MESS[:eCElectricityConsumption][f, z, t]
        )
        @expression(
            MESS,
            eCObjExpensesElectricity[z in 1:Z, t in 1:T],
            sum(MESS[:eCObjExpensesElectricityOF][f, z, t] for f in eachindex(Electricity_Index))
        )
        add_to_expression!.(MESS[:eCObjExpenses], MESS[:eCObjExpensesElectricity])
    end

    if !(settings["ModelHydrogen"] == 1)
        Hydrogen_Index = inputs["Hydrogen_Index"]
        hydrogen_costs = inputs["hydrogen_costs"]
        ### Add carbon sector hydrogen consumption into total hydrogen consumption
        add_to_expression!.(MESS[:eHydrogenConsumption], MESS[:eCHydrogenConsumption])
        ### Expenses for purchasing hydrogen from markets in carbon sector
        @expression(
            MESS,
            eCObjExpensesHydrogenOF[f in eachindex(Hydrogen_Index), z in 1:Z, t in 1:T],
            hydrogen_costs[Hydrogen_Index[f]][t] * MESS[:eCHydrogenConsumption][f, z, t]
        )
        @expression(
            MESS,
            eCObjExpensesHydrogen[z in 1:Z, t in 1:T],
            sum(MESS[:eCObjExpensesHydrogenOF][f, z, t] for f in eachindex(Hydrogen_Index))
        )
        add_to_expression!.(MESS[:eCObjExpenses], MESS[:eCObjExpensesHydrogen])
    end

    if !(settings["ModelBioenergy"] == 1)
        Bioenergy_Index = inputs["Bioenergy_Index"]
        bioenergy_costs = inputs["bioenergy_costs"]
        ### Add carbon sector bioenergy consumption into total bioenergy consumption
        add_to_expression!.(MESS[:eBioenergyConsumption], MESS[:eCBioenergyConsumption])
        ### Expenses for purchasing bioenergy from markets in carbon sector
        @expression(
            MESS,
            eCObjExpensesBioenergyOF[f in eachindex(Bioenergy_Index), z in 1:Z, t in 1:T],
            bioenergy_costs[Bioenergy_Index[f]][t] * MESS[:eCBioenergyConsumption][f, z, t]
        )
        @expression(
            MESS,
            eCObjExpensesBioenergy[z in 1:Z, t in 1:T],
            sum(MESS[:eCObjExpensesBioenergyOF][f, z, t] for f in eachindex(Bioenergy_Index))
        )
        add_to_expression!.(MESS[:eCObjExpenses], MESS[:eCObjExpensesBioenergy])
    end

    ## Add expenses for purchasing feedstocks from markets to objective function in carbon sector
    @expression(
        MESS,
        eCObjFeedStockOZ[z in 1:Z],
        sum(MESS[:eCObjExpenses][z, t] for t in 1:T; init = 0.0)
    )
    @expression(MESS, eCObjFeedStock, sum(MESS[:eCObjFeedStockOZ][z] for z in 1:Z; init = 0.0))
    add_to_expression!(MESS[:eCObj], MESS[:eCObjFeedStock])

    return MESS
end
