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
function consumption_in_power(settings::Dict, inputs::Dict, MESS::Model)

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    ## Feedstock consumption including fuels, electriicty, hydrogen, carbon and bioenergy from markets
    ### Fuels feedstock consumption in power sector
    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]
        @expression(
            MESS,
            ePFuelsConsumption[f in eachindex(Fuels_Index), z in 1:Z, t in 1:T],
            AffExpr(0)
        )
    end

    ### Hydrogen feedstock consumption in power sector
    if !(settings["ModelHydrogen"] == 1)
        Hydrogen_Index = inputs["Hydrogen_Index"]
        @expression(
            MESS,
            ePHydrogenConsumption[f in eachindex(Hydrogen_Index), z in 1:Z, t in 1:T],
            AffExpr(0)
        )
    end

    ### Carbon feedstock consumption in power sector
    if !(settings["ModelCarbon"] == 1)
        Carbon_Index = inputs["Carbon_Index"]
        @expression(
            MESS,
            ePCarbonConsumption[f in eachindex(Carbon_Index), z in 1:Z, t in 1:T],
            AffExpr(0)
        )
    end

    ### Bioenergy feedstock consumption in power sector
    if !(settings["ModelBioenergy"] == 1)
        Bioenergy_Index = inputs["Bioenergy_Index"]
        @expression(
            MESS,
            ePBioenergyConsumption[f in eachindex(Bioenergy_Index), z in 1:Z, t in 1:T],
            AffExpr(0)
        )
    end

    ## Initialize expenses for purchasing feedstocks from markets in power sector
    @expression(MESS, ePObjExpenses[z in 1:Z, t in 1:T], AffExpr(0))

    return MESS
end
