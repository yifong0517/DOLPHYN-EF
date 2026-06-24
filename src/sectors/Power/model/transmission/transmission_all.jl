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
	function transmission_all(settings::Dict, inputs::Dict, MESS::Model)

"""
function transmission_all(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Power Transmission Core Module")

    Z = inputs["Z"]
    T = inputs["T"]

    power_settings = settings["PowerSettings"]
    power_inputs = inputs["PowerInputs"]

    ## Number of transmission lines
    L = power_inputs["L"]
    dfLine = power_inputs["dfLine"]

    ## Sets and indices for transmission losses and expansion
    ## Number of segments used in piecewise linear approximations quadratic loss functions - can only take values of TRANS_LOSS_SEGS =1, 2
    TRANS_LOSS_SEGS = power_inputs["TRANS_LOSS_SEGS"]
    ## Lines for which loss coefficients apply (are non-zero);
    LOSS_LINES = power_inputs["LOSS_LINES"]

    ### Variables ###
    ## Power flow on each transmission line "l" at hour "t"
    @variable(MESS, vPLineFlow[l in 1:L, t in 1:T])

    if (TRANS_LOSS_SEGS == 1)
        ## Loss is a constant times absolute value of power flow
        ## Positive and negative flow variables
        @variable(MESS, vPLineFlowPos[l in LOSS_LINES, t in 1:T] >= 0)
        @variable(MESS, vPLineFlowNeg[l in LOSS_LINES, t in 1:T] >= 0)

        if power_settings["UCommit"] == 1
            ## Single binary variable to ensure positive or negative flows only
            @variable(MESS, vPLineAuxBin[l in LOSS_LINES, t in 1:T], Bin)
            ## Continuous variable representing product of binary variable (vPLineAuxBin) and avail transmission capacity
            @variable(MESS, vPLineProductAux[l in LOSS_LINES, t in 1:T] >= 0)
        end
    else
        ## TRANS_LOSS_SEGS>1
        ## Auxiliary variables for linear piecewise interpolation of quadratic losses
        @variable(MESS, vPLineFlowPos[l in LOSS_LINES, s in 0:TRANS_LOSS_SEGS, t in 1:T] >= 0)
        @variable(MESS, vPLineFlowNeg[l in LOSS_LINES, s in 0:TRANS_LOSS_SEGS, t in 1:T] >= 0)
        if power_settings["UCommit"] == 1
            ## Binary auxilary variables for each segment >1 to ensure segments fill in order
            @variable(MESS, vPLineAuxPosBin[l in LOSS_LINES, s in 1:TRANS_LOSS_SEGS, t in 1:T], Bin)
            @variable(MESS, vPLineAuxNegBin[l in LOSS_LINES, s in 1:TRANS_LOSS_SEGS, t in 1:T], Bin)
        end
    end

    ## Transmission losses on each transmission line "l" at hour "t"
    @variable(MESS, vPLineFlowLoss[l in LOSS_LINES, t in 1:T] >= 0)

    ### Expressions ###
    ## Net power flow outgoing from zone "z" at hour "t" in MW
    @expression(
        MESS,
        ePLineFlow[z in 1:Z, t in 1:T],
        sum(power_inputs["Network_map"][l, z] * MESS[:vPLineFlow][l, t] for l in 1:L; init = 0.0)
    )

    ## Losses from power flows into or out of zone "z" in MW
    @expression(
        MESS,
        ePLineLoss[z in 1:Z, t in 1:T],
        sum(
            abs(power_inputs["Network_map"][l, z]) * MESS[:vPLineFlowLoss][l, t] for l in LOSS_LINES;
            init = 0.0,
        )
    )

    ## Balance Expressions ##
    @expression(MESS, ePBalanceLineFlow[z in 1:Z, t in 1:T], -MESS[:ePLineFlow][z, t])
    add_to_expression!.(MESS[:ePBalance], MESS[:ePBalanceLineFlow])

    @expression(MESS, ePBalanceLineLoss[z in 1:Z, t in 1:T], -(1 / 2) * MESS[:ePLineLoss][z, t])
    add_to_expression!.(MESS[:ePBalance], MESS[:ePBalanceLineLoss])

    add_to_expression!.(MESS[:ePTransmission], MESS[:ePBalanceLineFlow])
    add_to_expression!.(MESS[:ePTransmission], MESS[:ePBalanceLineLoss])
    ## End Balance Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Transmission loss related constraints - linear losses as a function of absolute value
    if TRANS_LOSS_SEGS == 1 && !isempty(LOSS_LINES)
        @constraints(
            MESS,
            begin
                ## Losses are alpha times absolute values
                cPLineFlowLoss[l in LOSS_LINES, t in 1:T],
                MESS[:vPLineFlowLoss][l, t] ==
                dfLine[!, :Line_Loss_Percentage][l] *
                (MESS[:vPLineFlowPos][l, t] + MESS[:vPLineFlowNeg][l, t])

                ## Power flow is sum of positive and negative components
                cPLineAuxSum[l in LOSS_LINES, t in 1:T],
                MESS[:vPLineFlowPos][l, t] - MESS[:vPLineFlowNeg][l, t] == MESS[:vPLineFlow][l, t]

                ## Sum of auxiliary flow variables in either direction cannot exceed maximum line flow capacity
                cPLineAuxLimit[l in LOSS_LINES, t in 1:T],
                MESS[:vPLineFlowPos][l, t] + MESS[:vPLineFlowNeg][l, t] <= MESS[:ePLineCap][l]
            end
        )

        if power_settings["UCommit"] == 1
            ## Constraints to limit phantom losses that can occur to avoid discrete cycling costs/opportunity costs due to min down
            @constraints(
                MESS,
                begin
                    cPLineTAuxPosUB[l in LOSS_LINES, t in 1:T],
                    MESS[:vPLineFlowPos][l, t] <= MESS[:vPLineProductAux][l, t]

                    ## Either negative or positive flows are activated, not both
                    cPLineTAuxNegUB[l in LOSS_LINES, t in 1:T],
                    MESS[:vPLineFlowPos][l, t] <=
                    MESS[:ePLineCap][l] - MESS[:vPLineProductAux][l, t]

                    ## McCormick representation of product of continuous and binary variable
                    ## (in this case, of: vPLineProductAux[l,t] = ePLineCap[l] * vPLineAuxBin[l,t])
                    ## McCormick constraint 1
                    cPLineTAuxMaxPossible[l in LOSS_LINES, t in 1:T],
                    MESS[:vPLineProductAux][l, t] <=
                    dfLine[!, :Trans_Max_Possible][l] * MESS[:vPLineAuxBin][l, t]

                    ## McCormick constraint 2
                    cPLineTAuxMax[l in LOSS_LINES, t in 1:T],
                    MESS[:vPLineProductAux][l, t] <= MESS[:ePLineCap][l]

                    ## McCormick constraint 3
                    cPLineTAuxMin[l in LOSS_LINES, t in 1:T],
                    MESS[:vPLineProductAux][l, t] >=
                    MESS[:ePLineCap][l] -
                    (1 - MESS[:vPLineAuxBin][l, t]) * dfLine[!, :Trans_Max_Possible][l]
                end
            )
        end
    end

    ## When number of segments is greater than 1
    if (TRANS_LOSS_SEGS > 1) && !isempty(LOSS_LINES)
        ## between zone transmission loss constraints
        ## Losses are expressed as a piecewise approximation of a quadratic function of power flows across each line
        ## Eq 1: Total losses are function of loss coefficient times the sum of auxilary segment variables across all segments of piecewise approximation
        ## (Includes both positive domain and negative domain segments)
        @constraint(
            MESS,
            cPLineFlowLoss[l in LOSS_LINES, t in 1:T],
            MESS[:vPLineFlowLoss][l, t] ==
            (
                dfLine[!, :Trans_Loss_Coef][l] * sum(
                    (2 * s - 1) *
                    (dfLine[!, :Trans_Max_Possible][l] / TRANS_LOSS_SEGS) *
                    MESS[:vPLineFlowPos][l, s, t] for s in 1:TRANS_LOSS_SEGS
                )
            ) + (
                dfLine[!, :Trans_Loss_Coef][l] * sum(
                    (2 * s - 1) *
                    (dfLine[!, :Trans_Max_Possible][l] / TRANS_LOSS_SEGS) *
                    MESS[:vPLineFlowNeg][l, s, t] for s in 1:TRANS_LOSS_SEGS
                )
            )
        )

        ## Eq 2: Sum of auxilary segment variables (s >= 1) minus the "zero" segment (which allows values to go negative)
        ## from both positive and negative domains must total the actual power flow across the line
        @constraints(
            MESS,
            begin
                cPLineAuxSumPos[l in LOSS_LINES, t in 1:T],
                sum(MESS[:vPLineFlowPos][l, s, t] for s in 1:TRANS_LOSS_SEGS) -
                MESS[:vPLineFlowPos][l, 0, t] == MESS[:vPLineFlow][l, t]
                cPLineTAuxSumNeg[l in LOSS_LINES, t in 1:T],
                sum(MESS[:vPLineFlowNeg][l, s, t] for s in 1:TRANS_LOSS_SEGS) -
                MESS[:vPLineFlowNeg][l, 0, t] == -MESS[:vPLineFlow][l, t]
            end
        )
        ## Eq 3: Each auxilary segment variables (s >= 1) must be less than the maximum power flow in the zone / number of segments
        if power_settings["UCommit"] == 0 || power_settings["UCommit"] == 2
            @constraints(
                MESS,
                begin
                    cPLineAuxMaxPos[l in LOSS_LINES, s in 1:TRANS_LOSS_SEGS, t in 1:T],
                    MESS[:vPLineFlowPos][l, s, t] <=
                    (dfLine[!, :Trans_Max_Possible][l] / TRANS_LOSS_SEGS)
                    cPLineAuxMaxNeg[l in LOSS_LINES, s in 1:TRANS_LOSS_SEGS, t in 1:T],
                    MESS[:vPLineFlowNeg][l, s, t] <=
                    (dfLine[!, :Trans_Max_Possible][l] / TRANS_LOSS_SEGS)
                end
            )
        else
            ## Constraints that can be ommitted if problem is convex (i.e. if not using MILP unit commitment constraints)
            ## Eqs 3-4: Ensure that auxilary segment variables do not exceed maximum value per segment and that they
            ## "fill" in order: i.e. one segment cannot be non-zero unless prior segment is at it's maximum value
            ## (These constraints are necessary to prevents phantom losses in MILP problems)
            @constraints(
                MESS,
                begin
                    cPLineAuxOrderPos1[l in LOSS_LINES, s in 1:TRANS_LOSS_SEGS, t in 1:T],
                    MESS[:vPLineFlowAux][l, s, t] <=
                    (dfLine[!, :Trans_Max_Possible][l] / TRANS_LOSS_SEGS) *
                    MESS[:vPLineAuxPosBin][l, s, t]
                    cPLineAuxOrderNeg1[l in LOSS_LINES, s in 1:TRANS_LOSS_SEGS, t in 1:T],
                    MESS[:vPLineFlowNeg][l, s, t] <=
                    (dfLine[!, :Trans_Max_Possible][l] / TRANS_LOSS_SEGS) *
                    MESS[:vPLineAuxNegBin][l, s, t]
                    cPLineAuxOrderPos2[l in LOSS_LINES, s in 1:(TRANS_LOSS_SEGS - 1), t in 1:T],
                    MESS[:vPLineFlowPos][l, s, t] >=
                    (dfLine[!, :Trans_Max_Possible][l] / TRANS_LOSS_SEGS) *
                    MESS[:vPLineAuxPosBin][l, s + 1, t]
                    cPLineAuxOrderNeg2[l in LOSS_LINES, s in 1:(TRANS_LOSS_SEGS - 1), t in 1:T],
                    MESS[:vPLineFlowNeg][l, s, t] >=
                    (dfLine[!, :Trans_Max_Possible][l] / TRANS_LOSS_SEGS) *
                    MESS[:vPLineAuxNegBin][l, s + 1, t]
                end
            )

            ## Eq 5: Binary constraints to deal with absolute value of vPLineFlow.
            @constraints(
                MESS,
                begin
                    ## If flow is positive, vPLineFlowPos segment 0 must be zero; If flow is negative, vPLineFlowPos segment 0 must be positive
                    ## (and takes on value of the full negative flow), forcing all vPLineFlowPos other segments (s>=1) to be zero
                    cPLineAuxSegmentZeroPos[l in LOSS_LINES, t in 1:T],
                    MESS[:vPLineFlowPos][l, 0, t] <=
                    dfLine[!, :Trans_Max_Possible][l] * (1 - MESS[:vPLineAuxPosBin][l, 1, t])

                    ## If flow is negative, vPLineFlowNeg segment 0 must be zero; If flow is positive, vPLineFlowNeg segment 0 must be positive
                    ## (and takes on value of the full positive flow), forcing all other vPLineFlowNeg segments (s>=1) to be zero
                    cPLineAuxSegmentZeroNeg[l in LOSS_LINES, t in 1:T],
                    MESS[:vPLineFlowNeg][l, 0, t] <=
                    dfLine[!, :Trans_Max_Possible][l] * (1 - MESS[:vPLineAuxNegBin][l, 1, t])
                end
            )
        end
    end # End if(TRANS_LOSS_SEGS > 0) block

    ## Maximum power flows, power flow on each transmission line cannot exceed maximum capacity of the line at any hour "t"
    @constraints(
        MESS,
        begin
            cPLineMaxFlowPos[l in 1:L, t in 1:T], MESS[:vPLineFlow][l, t] <= MESS[:ePLineCap][l]
            cPLineMaxFlowNeg[l in 1:L, t in 1:T], MESS[:vPLineFlow][l, t] >= -MESS[:ePLineCap][l]
        end
    )
    ### End Constraints ###

    return MESS
end
