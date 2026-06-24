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
function ammonia_emission_policy(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Ammonia Sector Emission Policy Module")

    ammonia_settings = settings["AmmoniaSettings"]

    ## Flags
    AllowNse = ammonia_settings["AllowNse"]
    CO2Policy = ammonia_settings["CO2Policy"]

    ## Spatial and temporal index
    Z = inputs["Z"]
    T = inputs["T"]
    Zones = inputs["Zones"]
    weights = inputs["weights"]

    ammonia_inputs = inputs["AmmoniaInputs"]

    dfEmi = ammonia_inputs["dfEmi"]
    if AllowNse == 1
        SEG = ammonia_inputs["SEG"]
    end

    ## Ammonia sector emission policies
    if in(1, CO2Policy)
        ## Mass-based: Emissions constraint in absolute emissions limit (tonnes)
        @constraint(
            MESS,
            cAEmissionPolicyMass[z in 1:Z],
            sum(weights[t] * MESS[:eAEmissions][z, t] for t in 1:T) / 1E6 <=
            dfEmi[!, :Emission_Max_Mtons][z]
        )
    end
    if in(2, CO2Policy)
        ## Load + Rate-based: Emissions constraint in terms of rate (tonnes/tonne)
        if AllowNse == 1
            @constraint(
                MESS,
                cAEmissionPolicyRateLoad[z in 1:Z],
                sum(weights[t] * MESS[:eAEmissions][z, t] for t in 1:T) <=
                dfEmi[!, :Emission_Max_Tons_tonne][z] * sum(
                    weights[t] * (
                        ammonia_inputs["D"][z, t] + MESS[:eCDemandAddition][z, t] -
                        sum(MESS[:vADNse][s, z, t] for s in 1:SEG)
                    ) for t in 1:T
                )
            )
        else
            @constraint(
                MESS,
                cAEmissionPolicyRateLoad[z in 1:Z],
                sum(weights[t] * MESS[:eAEmissions][z, t] for t in 1:T) <=
                dfEmi[!, :Emission_Max_Tons_tonne][z] * sum(
                    weights[t] * (ammonia_inputs["D"][z, t] + MESS[:eCDemandAddition][z, t]) for
                    t in 1:T
                )
            )
        end
    end
    if in(3, CO2Policy)
        ## Generation + Rate-based: Emissions constraint in terms of rate (tonnes/tonne)
        @constraint(
            MESS,
            cAEmissionPolicyRateGen[z in 1:Z],
            sum(weights[t] * MESS[:eAEmissions][z, t] for t in 1:T) <= sum(
                dfEmi[!, :Emission_Max_Tons_tonne][z] * weights[t] * MESS[:eAGeneration][z, t] for
                t in 1:T
            )
        )
    end
    if in(4, CO2Policy)
        ## Price based: Emissions penalty in terms of price (USD/tonne)
        @expression(
            MESS,
            eAObjVarEmissionOZ[z in 1:Z],
            sum(weights[t] * MESS[:eAEmissions][z, t] for t in 1:T) *
            dfEmi[!, :Emission_Price_tonne][z]
        )
        @expression(MESS, eAObjVarEmission, sum(eAObjVarEmissionOZ[z] for z in 1:Z))
        ## Add term to objective function expression
        add_to_expression!(MESS[:eAObj], MESS[:eAObjVarEmission])
    end

    return MESS
end
