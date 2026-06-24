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
function consumption_in_synfuels(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Synfuels Feedstock Consumption Module")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    ## Feedstock consumption including fuels, electriicty, hydrogen, carbon and bioenergy from markets
    ### Fuels feedstock consumption in synfuels sector
    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]
        @expression(
            MESS,
            eSFuelsConsumption[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            AffExpr(0)
        )
    end

    ### Electricity consumption in synfuels sector
    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
        @expression(
            MESS,
            eSElectricityConsumption[f in eachindex(Electricity_Index), z in 1:Z, t in 1:T],
            AffExpr(0)
        )
    end

    ### Hydrogen feedstock consumption in synfuels sector
    if !(settings["ModelHydrogen"] == 1)
        Hydrogen_Index = inputs["Hydrogen_Index"]
        @expression(
            MESS,
            eSHydrogenConsumption[f in eachindex(Hydrogen_Index), z in 1:Z, t in 1:T],
            AffExpr(0)
        )
    end

    ### Carbon feedstock consumption in synfuels sector
    if !(settings["ModelCarbon"] == 1)
        Carbon_Index = inputs["Carbon_Index"]
        @expression(
            MESS,
            eSCarbonConsumption[f in eachindex(Carbon_Index), z in 1:Z, t in 1:T],
            AffExpr(0)
        )
    end

    ### Bioenergy feedstock consumption in synfuels sector
    if !(settings["ModelBioenergy"] == 1)
        Bioenergy_Index = inputs["Bioenergy_Index"]
        @expression(
            MESS,
            eSBioenergyConsumption[f in eachindex(Bioenergy_Index), z in 1:Z, t in 1:T],
            AffExpr(0)
        )
    end

    ## Initialize expenses for purchasing feedstocks from markets in synfuels sector
    @expression(MESS, eSObjExpenses[z in 1:Z, t in 1:T], AffExpr(0))

    return MESS
end
