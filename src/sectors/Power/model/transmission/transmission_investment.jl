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
function transmission_investment(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Transmission Investment Module")

    Z = inputs["Z"]
    T = inputs["T"]

    ## Get power sector settings
    power_settings = settings["PowerSettings"]
    IncludeExistingNetwork = power_settings["IncludeExistingNetwork"]

    power_inputs = inputs["PowerInputs"]

    ## Number of transmission lines
    L = power_inputs["L"]
    dfLine = power_inputs["dfLine"]

    ## Network lines and zones that are expandable have non-negative maximum reinforcement inputs
    NEW_LINES = power_inputs["NEW_LINES"]
    ## Transmission network capacity reinforcements per line
    @variable(MESS, vPNewLineCap[l in NEW_LINES] >= 0)

    ### Expressions ###
    ## Transmission power flow and loss related expressions:
    ## Total availabile maximum transmission capacity is the sum of existing maximum transmission capacity plus new transmission capacity
    @expression(
        MESS,
        ePLineCap[l in 1:L],
        if l in NEW_LINES
            dfLine[!, :Existing_Line_Cap_MW][l] + MESS[:vPNewLineCap][l]
        else
            dfLine[!, :Existing_Line_Cap_MW][l]
        end
    )

    ## Objective Expressions ##
    ## Fixed investment costs of new installed lines
    @expression(
        MESS,
        ePObjNetworkExpOL[l in NEW_LINES],
        dfLine[!, :Line_Inv_Cost_per_MW][l] * dfLine[!, :AF][l] * MESS[:vPNewLineCap][l]
    )
    @expression(
        MESS,
        ePObjNetworkExpansion,
        sum(MESS[:ePObjNetworkExpOL][l] for l in NEW_LINES; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:ePObj], MESS[:ePObjNetworkExpansion])

    ## Fixed investment costs for existing capacity
    if IncludeExistingNetwork > 0
        @expression(
            MESS,
            ePObjNetworkExistingOL[l in 1:L],
            AffExpr(
                dfLine[!, :Line_Inv_Cost_per_MW][l] *
                dfLine[!, :AF][l] *
                dfLine[!, :Existing_Line_Cap_MW][l] / IncludeExistingNetwork,
            )
        )
        @expression(
            MESS,
            ePObjNetworkExisting,
            sum(MESS[:ePObjNetworkExistingOL][l] for l in 1:L; init = 0.0),
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:ePObj], MESS[:ePObjNetworkExisting])
    end
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Allow expansion of transmission capacity for lines eligible for reinforcement
    ## Transmission network related power flow and capacity constraints
    ## Constrain maximum line capacity reinforcement for lines eligible for expansion
    if !isempty(intersect(NEW_LINES, dfLine[dfLine.Max_Line_Cap_MW .> 0, :L_ID]))
        @constraint(
            MESS,
            cPLineMaxCap[l in intersect(NEW_LINES, dfLine[dfLine.Max_Line_Cap_MW .> 0, :L_ID])],
            MESS[:ePLineCap][l] <= dfLine[!, :Max_Line_Cap_MW][l]
        )
    end
    ### End Constraints ###

    return MESS
end
