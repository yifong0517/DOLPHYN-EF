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

    print_and_log(settings, "i", "Synfuels Transmission Pipeline Investment Module")

    Z = inputs["Z"]
    T = inputs["T"]

    ## Get synfuels sector settings
    synfuels_settings = settings["SynfuelsSettings"]
    IncludeExistingNetwork = synfuels_settings["IncludeExistingNetwork"]

    synfuels_inputs = inputs["SynfuelsInputs"]

    dfPipe = synfuels_inputs["dfPipe"]
    NEW_PIPES = synfuels_inputs["NEW_PIPES"]

    ## Number of pipe lines
    P = synfuels_inputs["P"]

    ### Variables ###
    @variable(MESS, vSNewPipeCap[p in NEW_PIPES] >= 0)

    ### Expressions ###
    ## Calculate the number of new pipes
    @expression(
        MESS,
        eSPipeCap[p = 1:P],
        begin
            if p in NEW_PIPES
                MESS[:vSNewPipeCap][p] + dfPipe[!, :Existing_Pipe_Number][p]
            else
                dfPipe[!, :Existing_Pipe_Number][p]
            end
        end
    )

    ## Objective Expressions ##
    ## Annuitized investment costs for new built capacity
    @expression(
        MESS,
        eSObjNetworkExpansionOP[p in NEW_PIPES],
        MESS[:vSNewPipeCap][p] *
        dfPipe[!, :Pipe_Inv_Cost_per_mile][p] *
        dfPipe[!, :AF][p] *
        dfPipe[!, :Pipe_Length_miles][p]
    )
    @expression(
        MESS,
        eSObjNetworkExpansion,
        sum(MESS[:eSObjNetworkExpansionOP][p] for p in NEW_PIPES; init = 0.0),
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eSObj], MESS[:eSObjNetworkExpansion])

    ## Annuitized investment costs for existing capacity
    if IncludeExistingNetwork == 1
        @expression(
            MESS,
            eSObjNetworkExistingOP[p in 1:P],
            AffExpr(
                dfPipe[!, :Existing_Pipe_Number][p] *
                dfPipe[!, :Pipe_Inv_Cost_per_mile][p] *
                dfPipe[!, :AF][p] *
                dfPipe[!, :Pipe_Length_miles][p],
            )
        )
        @expression(
            MESS,
            eSObjNetworkExisting,
            sum(MESS[:eSObjNetworkExistingOP][p] for p in 1:P; init = 0.0),
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:eSObj], MESS[:eSObjNetworkExisting])
    end

    ## Annuitized investment costs for new built compression capacity
    @expression(
        MESS,
        eSObjFixPipeComp,
        sum(
            MESS[:vSNewPipeCap][p] *
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
    add_to_expression!(MESS[:eSObj], MESS[:eSObjFixPipeComp])
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Integer constraints
    if synfuels_settings["PipeInteger"] == 1
        for p in NEW_PIPES
            set_integer.(MESS[:vSNewPipeCap][p])
        end
    end

    ## Maximum number of pipelines
    @constraint(
        MESS,
        cSPipeMaxNumber[p in 1:P],
        MESS[:eSPipeCap][p] <= dfPipe[!, :Max_Pipe_Number][p]
    )
    ### End Constraints ###

    return MESS
end
