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
function pipeline_investment(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Carbon Transmission Pipeline Investment Module")

    Z = inputs["Z"]
    T = inputs["T"]

    ## Get carbon sector settings
    carbon_settings = settings["CarbonSettings"]
    IncludeExistingNetwork = carbon_settings["IncludeExistingNetwork"]

    carbon_settings = settings["CarbonSettings"]
    carbon_inputs = inputs["CarbonInputs"]

    dfPipe = carbon_inputs["dfPipe"]
    NEW_PIPES = carbon_inputs["NEW_PIPES"]

    ## Number of pipe lines
    L = carbon_inputs["L"]

    ### Variables ###
    @variable(MESS, vCNewPipeCap[p in NEW_PIPES] >= 0)

    ### Expressions ###
    ## Calculate the number of new pipes
    @expression(
        MESS,
        eCPipeCap[p in 1:L],
        begin
            if p in NEW_PIPES
                vCNewPipeCap[p] + dfPipe[!, :Existing_Pipe_Number][p]
            else
                dfPipe[!, :Existing_Pipe_Number][p]
            end
        end
    )

    ## Objective Expressions ##
    ## Annuitized investment costs for new built pipeline capacity
    @expression(
        MESS,
        eCObjNetworkExpansionOP[p in NEW_PIPES],
        vCNewPipeCap[p] *
        dfPipe[!, :Pipe_Inv_Cost_per_mile][p] *
        dfPipe[!, :AF][p] *
        dfPipe[!, :Pipe_Length_miles][p]
    )
    @expression(
        MESS,
        eCObjNetworkExpansion,
        sum(MESS[:eCObjNetworkExpansionOP][p] for p in NEW_PIPES)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eCObj], MESS[:eCObjNetworkExpansion])

    ## Annuitized investment costs for existing capacity
    if IncludeExistingNetwork == 1
        @expression(
            MESS,
            eCObjNetworkExistingOP[p in 1:L],
            AffExpr(
                dfPipe[!, :Existing_Pipe_Number][p] *
                dfPipe[!, :Pipe_Inv_Cost_per_mile][p] *
                dfPipe[!, :AF][p] *
                dfPipe[!, :Pipe_Length_miles][p],
            )
        )
        @expression(MESS, eCObjNetworkExisting, sum(MESS[:eCObjNetworkExistingOP][p] for p in 1:L))
        ## Add term to objective function expression
        add_to_expression!(MESS[:eCObj], MESS[:eCObjNetworkExisting])
    end

    ## Annuitized investment costs for new built compression capacity
    @expression(
        MESS,
        eCObjFixPipeComp,
        sum(
            vCNewPipeCap[p] *
            dfPipe[!, :Max_Flow_tonne_per_hr][p] *
            (
                dfPipe[!, :Pipe_Comp_Capex][p] +
                dfPipe[!, :Booster_Capex_per_tonne_p_hr_yr][p] *
                dfPipe[!, :Booster_Stations_Number][p]
            ) for p in NEW_PIPES;
            init = 0.0,
        )
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eCObj], MESS[:eCObjFixPipeComp])
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Integer constraints
    if carbon_settings["PipeInteger"] == 1
        for p in NEW_PIPES
            set_integer.(MESS[:vCNewPipeCap][p])
        end
    end

    ## Maximum number of pipelines
    @constraint(
        MESS,
        cCPipeMaxNumber[p in 1:L],
        MESS[:eCPipeCap][p] <= dfPipe[!, :Max_Pipe_Number][p]
    )
    ### End Constraints ###

    return MESS
end
