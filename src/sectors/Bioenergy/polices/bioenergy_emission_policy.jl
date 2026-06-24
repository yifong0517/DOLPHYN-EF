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
function bioenergy_emission_policy(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Bioenergy Sector Emission Policy Module")

    bioenergy_settings = settings["BioenergySettings"]

    ## Flags
    CO2Policy = bioenergy_settings["CO2Policy"]

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    bioenergy_inputs = inputs["BioenergyInputs"]

    dfEmi = bioenergy_inputs["dfEmi"]

    ## Bioenergy sector emission policies
    if in(1, CO2Policy)
        ## Mass-based: Emissions constraint in absolute emissions limit (tonnes)
        @constraint(
            MESS,
            cBEmissionPolicyMass[z in 1:Z],
            sum(weights[t] * MESS[:eBEmissions][z, t] for t in 1:T) <=
            dfEmi[!, :Emission_Max_Mtons][z]
        )
    end
    if in(2, CO2Policy)
        bioenergy_inputs = inputs["BioenergyInputs"]
        Residuals = bioenergy_inputs["Residuals"]
        ## Load + Rate-based: Emissions constraint in terms of rate (tonnes/tonne)
        @constraint(
            MESS,
            cBEmissionPolicyRateLoad[z in 1:Z],
            sum(weights[t] * MESS[:eBEmissions][z, t] for t in 1:T) <=
            dfEmi[!, :Emission_Max_Tons_tonne][z] * sum(
                weights[t] * sum(
                    MESS[:eBDemand][z, rs, t] + MESS[:eBDemandAddition][z, rs, t] for
                    rs in eachindex(Residuals)
                ) for t in 1:T
            )
        )
    end
    if in(3, CO2Policy)
        bioenergy_inputs = inputs["BioenergyInputs"]
        Residuals = bioenergy_inputs["Residuals"]
        ## Generation + Rate-based: Emissions constraint in terms of rate (tonnes/tonne)
        @constraint(
            MESS,
            cBEmissionPolicyRateGen[z in 1:Z],
            sum(weights[t] * MESS[:eBEmissions][z, t] for t in 1:T) <= sum(
                dfEmi[!, :Emission_Max_Tons_tonne][z] *
                weights[t] *
                sum(MESS[:eBResiduals][z, rs, t] for rs in eachindex(Residuals)) for t in 1:T
            )
        )
    end
    if in(4, CO2Policy)
        ## Price based: Emissions penalty in terms of price (USD/tonne)
        @expression(
            MESS,
            eBObjVarEmissionOZ[z in 1:Z],
            sum(weights[t] * MESS[:eBEmissions][z, t] for t in 1:T) *
            dfEmi[!, :Emission_Price_tonne][z]
        )
        @expression(MESS, eBObjVarEmission, sum(eBObjVarEmissionOZ[z] for z in 1:Z))
        ## Add term to objective function expression
        add_to_expression!(MESS[:eBObj], MESS[:eBObjVarEmission])
    end

    return MESS
end
