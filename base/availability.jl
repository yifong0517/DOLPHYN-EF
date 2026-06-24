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
function availability(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Base Feedstock Availability Module")

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]

    ## Fuels availability
    if settings["ModelFuels"] == 1
        Fuels_Index = inputs["Fuels_Index"]
        Fuels_Availability = inputs["Fuels_Availability"]
        @constraint(
            MESS,
            cFuelAvailability[f in eachindex(Fuels_Index), t in 1:T],
            sum(MESS[:eFuelsConsumption][f, z, t] for z in 1:Z) <=
            Fuels_Availability[Fuels_Index[f]][t]
        )
    end

    ## Electricity availability
    if !(settings["ModelPower"] == 1)
        Electricity_Index = inputs["Electricity_Index"]
        Electricity_Availability = inputs["Electricity_Availability"]
        @constraint(
            MESS,
            cElectricityAvailability[f in eachindex(Electricity_Index), t in 1:T],
            sum(MESS[:eElectricityConsumption][f, z, t] for z in 1:Z) <=
            Electricity_Availability[Electricity_Index[f]][t]
        )
    end

    ## Hydrogen availability
    if !(settings["ModelHydrogen"] == 1)
        Hydrogen_Index = inputs["Hydrogen_Index"]
        Hydrogen_Availability = inputs["Hydrogen_Availability"]
        @constraint(
            MESS,
            cHydrogenAvailability[f in eachindex(Hydrogen_Index), t in 1:T],
            sum(MESS[:eHydrogenConsumption][f, z, t] for z in 1:Z) <=
            Hydrogen_Availability[Hydrogen_Index[f]][t]
        )
    end

    ## Carbon availability
    if !(settings["ModelCarbon"] == 1)
        Carbon_Index = inputs["Carbon_Index"]
        Carbon_Availability = inputs["Carbon_Availability"]
        @constraint(
            MESS,
            cCarbonAvailability[f in eachindex(Carbon_Index), t in 1:T],
            sum(MESS[:eCarbonConsumption][f, z, t] for z in 1:Z) <=
            Carbon_Availability[Carbon_Index[f]][t]
        )
    end

    ## Bioenergy availability
    if !(settings["ModelBioenergy"] == 1)
        Bioenergy_Index = inputs["Bioenergy_Index"]
        Bioenergy_Availability = inputs["Bioenergy_Availability"]
        @constraint(
            MESS,
            cBioenergyAvailability[f in eachindex(Bioenergy_Index), t in 1:T],
            sum(MESS[:eBioenergyConsumption][f, z, t] for z in 1:Z) <=
            Bioenergy_Availability[Bioenergy_Index[f]][t]
        )
    end

    return MESS
end
