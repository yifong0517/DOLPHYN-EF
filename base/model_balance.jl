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
function model_balance(settings::Dict, inputs::Dict, MESS::Model)

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    if settings["ModelPower"] == 1
        power_inputs = inputs["PowerInputs"]
        ## Power sector balance
        @constraint(
            MESS,
            cPBalance[z in 1:Z, t in 1:T],
            MESS[:ePBalance][z, t] == AffExpr(power_inputs["D"][z, t])
        )
    end

    if settings["ModelHydrogen"] == 1
        hydrogen_inputs = inputs["HydrogenInputs"]
        ## Hydrogen sector balance
        @constraint(
            MESS,
            cHBalance[z in 1:Z, t in 1:T],
            MESS[:eHBalance][z, t] == AffExpr(hydrogen_inputs["D"][z, t])
        )
    end

    if settings["ModelCarbon"] == 1
        carbon_inputs = inputs["CarbonInputs"]
        ## Carbon sector balance
        @constraint(
            MESS,
            cCBalance[z in 1:Z, t in 1:T],
            MESS[:eCBalance][z, t] == AffExpr(carbon_inputs["D"][z, t])
        )
    end

    if settings["ModelSynfuels"] == 1
        synfuels_inputs = inputs["SynfuelsInputs"]
        ## Synfuels sector balance
        @constraint(
            MESS,
            cSBalance[z in 1:Z, t in 1:T],
            MESS[:eSBalance][z, t] == AffExpr(synfuels_inputs["D"][z, t])
        )
    end

    if settings["ModelAmmonia"] == 1
        ammonia_inputs = inputs["AmmoniaInputs"]
        ## Ammonia sector balance
        @constraint(
            MESS,
            cABalance[z in 1:Z, t in 1:T],
            MESS[:eABalance][z, t] == AffExpr(ammonia_inputs["D"][z, t])
        )
    end

    if settings["ModelFoodstuff"] == 1
        foodstuff_inputs = inputs["FoodstuffInputs"]
        foodstuff_settings = settings["FoodstuffSettings"]
        Foods = foodstuff_inputs["Foods"]
        ## Foodstuff sector balance
        if foodstuff_settings["YearlyBalance"] == 1
            @constraint(
                MESS,
                cFBalance[z in 1:Z, fs in eachindex(Foods)],
                sum(MESS[:eFBalance][z, fs, t] for t in 1:T) ==
                AffExpr(foodstuff_inputs["D_Annual"][z, fs])
            )
        else
            @constraint(
                MESS,
                cFBalance[z in 1:Z, fs in eachindex(Foods), t in 1:T],
                MESS[:eFBalance][z, fs, t] == AffExpr(foodstuff_inputs["D"][z, fs, t])
            )
        end
    end

    if settings["ModelBioenergy"] == 1
        bioenergy_inputs = inputs["BioenergyInputs"]
        Residuals = bioenergy_inputs["Residuals"]
        ## Bioenergy sector balance
        @constraint(
            MESS,
            cBBalance[z in 1:Z, rs in eachindex(Residuals), t in 1:T],
            MESS[:eBBalance][z, rs, t] == 0
        )
    end

    return MESS
end
