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
function truck_investment(settings::Dict, inputs::Dict, MESS::Model)

    print_and_log(settings, "i", "Carbon Transmission Truck Investment Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]
    T = inputs["T"]

    carbon_settings = settings["CarbonSettings"]
    carbon_inputs = inputs["CarbonInputs"]

    dfTru = carbon_inputs["dfTru"]
    dfRoute = carbon_inputs["dfRoute"]

    TRUCK_TYPES = carbon_inputs["TRUCK_TYPES"]
    TRANSPORT_ZONES = carbon_inputs["TRANSPORT_ZONES"]

    ### Variables ###
    ## Truck capacity built and retired
    if carbon_settings["NetworkExpansion"] == 1
        ## New installed charge capacity of truck type "j"
        @variable(MESS, vCNewTruNumber[j in TRUCK_TYPES] >= 0)

        ## New installed energy capacity of truck type "j" on zone "z"
        @variable(MESS, vCNewTruComp[z in TRANSPORT_ZONES, j in TRUCK_TYPES] >= 0)
    end

    ### Expressions ###
    ## Total available truck numbers
    @expression(
        MESS,
        eCTruNumber[j in TRUCK_TYPES],
        if carbon_settings["NetworkExpansion"] == 1
            dfTru[!, :Existing_Number][j] + MESS[:vCNewTruNumber][j]
        else
            dfTru[!, :Existing_Number][j]
        end
    )

    ## Total available energy capacity in tonnes
    @expression(
        MESS,
        eCTruComp[z in TRANSPORT_ZONES, j in TRUCK_TYPES],
        if carbon_settings["NetworkExpansion"] == 1
            dfTru[!, Symbol("Existing_Comp_Cap_tonne_$z")][j] + MESS[:vCNewTruComp][z, j]
        else
            dfTru[!, Symbol("Existing_Comp_Cap_tonne_$z")][j]
        end
    )

    ## Objective Expressions ##
    ## Fixed costs for truck type "j" = annuitized investment cost
    ## If truck is not eligible for new charge capacity, fixed costs are zero
    if carbon_settings["NetworkExpansion"] == 1
        @expression(
            MESS,
            eCObjFixInvTruOJ[j in TRUCK_TYPES],
            (
                dfTru[!, :Inv_Cost_Truck_per_unit][j] * dfTru[!, :Truck_AF][j] +
                dfTru[!, :Trailer_Number][j] *
                dfTru[!, :Trailer_AF][j] *
                dfTru[!, :Inv_Cost_Trailer_per_number][j]
            ) * MESS[:vCNewTruNumber][j]
        )
        @expression(
            MESS,
            eCObjFixInvTru,
            sum(MESS[:eCObjFixInvTruOJ][j] for j in TRUCK_TYPES; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:eCObj], MESS[:eCObjFixInvTru])
    end

    ## Truck fixed operation and maintainance costs
    @expression(
        MESS,
        eCObjFixFomTruOJ[j in TRUCK_TYPES],
        (
            dfTru[!, :Fixed_OM_Cost_Truck_per_unit][j] +
            dfTru[!, :Trailer_Number][j] * dfTru[!, :Fixed_OM_Cost_Trailer_per_number][j]
        ) * MESS[:eCTruNumber][j]
    )
    @expression(
        MESS,
        eCObjFixFomTru,
        sum(MESS[:eCObjFixFomTruOJ][j] for j in TRUCK_TYPES; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eCObj], MESS[:eCObjFixFomTru])

    ## Compression capacity costs
    ## Fixed costs for truck type "j" on zone "z" = annuitized investment cost plus fixed O&M costs
    if carbon_settings["NetworkExpansion"] == 1
        @expression(
            MESS,
            eCObjFixInvTruCompOZJ[z in TRANSPORT_ZONES, j in TRUCK_TYPES],
            dfTru[!, :Inv_Cost_Comp_per_tonne_per_hr][j] *
            dfTru[!, :Comp_AF][j] *
            MESS[:vCNewTruComp][z, j]
        )
        @expression(
            MESS,
            eCObjFixInvTruCompOJ[j in TRUCK_TYPES],
            sum(MESS[:eCObjFixInvTruCompOZJ][z, j] for z in TRANSPORT_ZONES; init = 0.0)
        )
        @expression(
            MESS,
            eCObjFixInvTruCompOZ[z in TRANSPORT_ZONES],
            sum(MESS[:eCObjFixInvTruCompOZJ][z, j] for j in TRUCK_TYPES; init = 0.0)
        )
        @expression(
            MESS,
            eCObjFixInvTruComp,
            sum(MESS[:eCObjFixInvTruCompOZ][z] for z in TRANSPORT_ZONES; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:eCObj], MESS[:eCObjFixInvTruComp])
    end

    ## Compression fixed operation and maintainance costs
    @expression(
        MESS,
        eCObjFixFomTruCompOZJ[z in TRANSPORT_ZONES, j in TRUCK_TYPES],
        dfTru[!, :Fixed_OM_Cost_Comp_per_tonne_per_hr][j] * MESS[:eCTruComp][z, j]
    )
    @expression(
        MESS,
        eCObjFixFomTruCompOJ[j in TRUCK_TYPES],
        sum(MESS[:eCObjFixFomTruCompOZJ][z, j] for z in TRANSPORT_ZONES; init = 0.0)
    )
    @expression(
        MESS,
        eCObjFixFomTruCompOZ[z in TRANSPORT_ZONES],
        sum(MESS[:eCObjFixFomTruCompOZJ][z, j] for j in TRUCK_TYPES; init = 0.0)
    )
    @expression(
        MESS,
        eCObjFixFomTruComp,
        sum(MESS[:eCObjFixFomTruCompOZ][z] for z in TRANSPORT_ZONES; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eCObj], MESS[:eCObjFixFomTruComp])
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Constraints on new built truck compression capacity
    ## Constraint on maximum compression capacity (if applicable) [set input to -1 if no constraint on maximum compression capacity]
    @constraint(
        MESS,
        cCTruckMaxCompCap[
            z in TRANSPORT_ZONES,
            j in intersect(TRUCK_TYPES, dfTru[dfTru.Max_Comp_Cap_tonne .> 0, :T_ID]),
        ],
        MESS[:eCTruComp][z, j] <= dfTru[!, :Max_Comp_Cap_tonne][j]
    )

    ## Constraint on minimum energy capacity (if applicable) [set input to -1 if no constraint on minimum energy apacity]
    @constraint(
        MESS,
        cCTruckMinCompCap[
            z in TRANSPORT_ZONES,
            j in intersect(TRUCK_TYPES, dfTru[dfTru.Min_Comp_Cap_tonne .> 0, :T_ID]),
        ],
        MESS[:eCTruComp][z, j] >= dfTru[!, :Min_Comp_Cap_tonne][j]
    )

    ## Integer constraints
    if carbon_settings["TruckInteger"] == 1
        for j in TRUCK_TYPES
            set_integer.(MESS[:vCNewTruNumber][j])
        end
    end
    ### End Constraints ###

    return MESS
end
