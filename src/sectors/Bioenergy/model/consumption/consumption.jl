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

    print_and_log(settings, "i", "Bioenergy Consumption Module")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]
        fuels_costs = inputs["fuels_costs"]
        ### Add bioenergy sector fuel consumption to the total fuel consumption
        add_to_expression!.(MESS[:eFuelsConsumption], MESS[:eBFuelsConsumption])
        ### Expenses for purchasing fuels from markets in bioenergy sector
        @expression(
            MESS,
            eBObjExpensesFuelsOF[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            fuels_costs[Fuels_Index[f]][t] * MESS[:eBFuelsConsumption][f, z, t]
        )
        @expression(
            MESS,
            eBObjExpensesFuels[z in 1:Z, t in 1:T],
            sum(MESS[:eBObjExpensesFuelsOF][f, z, t] for f in eachindex(Fuels_Index))
        )
        add_to_expression!.(MESS[:eBObjExpenses], MESS[:eBObjExpensesFuels])
    end

    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
        electricity_costs = inputs["electricity_costs"]
        ### Add bioenergy sector electricity consumption to the total electricity consumption
        add_to_expression!.(MESS[:eElectricityConsumption], MESS[:eBElectricityConsumption])
        ### Expenses for purchasing electricity from markets in bioenergy sector
        @expression(
            MESS,
            eBObjExpensesElectricityOF[f in eachindex(Electricity_Index), z in 1:Z, t in 1:T],
            electricity_costs[Electricity_Index[f]][t] * MESS[:eBElectricityConsumption][f, z, t]
        )
        @expression(
            MESS,
            eBObjExpensesElectricity[z in 1:Z, t in 1:T],
            sum(MESS[:eBObjExpensesElectricityOF][f, z, t] for f in eachindex(Electricity_Index))
        )
        add_to_expression!.(MESS[:eBObjExpenses], MESS[:eBObjExpensesElectricity])
    end

    if !(settings["ModelHydrogen"] == 1)
        Hydrogen_Index = inputs["Hydrogen_Index"]
        hydrogen_costs = inputs["hydrogen_costs"]
        ### Add bioenergy sector hydrogen consumption to the total hydrogen consumption
        add_to_expression!.(MESS[:eHydrogenConsumption], MESS[:eBHydrogenConsumption])
        ### Expenses for purchasing hydrogen from markets in bioenergy sector
        @expression(
            MESS,
            eBObjExpensesHydrogenOF[f in eachindex(Hydrogen_Index), z in 1:Z, t in 1:T],
            hydrogen_costs[Hydrogen_Index[f]][t] * MESS[:eBHydrogenConsumption][f, z, t]
        )
        @expression(
            MESS,
            eBObjExpensesHydrogen[z in 1:Z, t in 1:T],
            sum(MESS[:eBObjExpensesHydrogenOF][f, z, t] for f in eachindex(Hydrogen_Index))
        )
        add_to_expression!.(MESS[:eBObjExpenses], MESS[:eBObjExpensesHydrogen])
    end

    if settings["ModelPower"] == 1
        ## Get power sector generators' data from dataframe
        power_inputs = inputs["PowerInputs"]
        BFG = power_inputs["BFG"]
        if !isempty(BFG)
            consumption_bfg(settings, inputs, MESS)
        end
    end

    if settings["ModelHydrogen"] == 1
        ## Get hydrogen sector generators' data from dataframe
        hydrogen_inputs = inputs["HydrogenInputs"]
        BMG = hydrogen_inputs["BMG"]
        if !isempty(BMG)
            consumption_bmg(settings, inputs, MESS)
        end
    end

    if settings["ModelSynfuels"] == 1
        ## Get synfuels sector generators' data from dataframe
        synfuels_inputs = inputs["SynfuelsInputs"]
        BLG = synfuels_inputs["BLG"]
        if !isempty(BLG)
            consumption_blg(settings, inputs, MESS)
        end
    end

    ## Add expenses for purchasing feedstocks from markets to objective function in bioenergy sector
    @expression(
        MESS,
        eBObjFeedStockOZ[z in 1:Z],
        sum(MESS[:eBObjExpenses][z, t] for t in 1:T; init = 0.0)
    )
    @expression(MESS, eBObjFeedStock, sum(MESS[:eBObjFeedStockOZ][z] for z in 1:Z; init = 0.0))
    add_to_expression!(MESS[:eBObj], eBObjFeedStock)

    return MESS
end
