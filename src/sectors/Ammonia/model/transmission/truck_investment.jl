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

    print_and_log(settings, "i", "Ammonia Transmission Truck Investment Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]
    T = inputs["T"]

    ammonia_settings = settings["AmmoniaSettings"]
    ammonia_inputs = inputs["AmmoniaInputs"]

    dfTru = ammonia_inputs["dfTru"]
    dfRoute = ammonia_inputs["dfRoute"]

    TRUCK_TYPES = ammonia_inputs["TRUCK_TYPES"]
    TRANSPORT_ZONES = ammonia_inputs["TRANSPORT_ZONES"]

    ### Variables ###
    ## Truck capacity built and retired
    if ammonia_settings["NetworkExpansion"] == 1
        ## New installed charge capacity of truck type "j"
        @variable(MESS, vANewTruNumber[j in TRUCK_TYPES] >= 0)

        ## New installed energy capacity of truck type "j" on zone "z"
        @variable(MESS, vANewTruComp[z in TRANSPORT_ZONES, j in TRUCK_TYPES] >= 0)
    end

    ### Expressions ###
    ## Total available truck numbers
    @expression(
        MESS,
        eATruNumber[j in TRUCK_TYPES],
        if ammonia_settings["NetworkExpansion"] == 1
            dfTru[!, :Existing_Number][j] + MESS[:vANewTruNumber][j]
        else
            dfTru[!, :Existing_Number][j]
        end
    )

    ## Total available energy capacity in tonnes
    @expression(
        MESS,
        eATruComp[z in TRANSPORT_ZONES, j in TRUCK_TYPES],
        if ammonia_settings["NetworkExpansion"] == 1
            dfTru[!, Symbol("Existing_Comp_Cap_tonne_$z")][j] + MESS[:vANewTruComp][z, j]
        else
            dfTru[!, Symbol("Existing_Comp_Cap_tonne_$z")][j]
        end
    )

    ## Objective Expressions ##
    ## Fixed costs for truck type "j" = annuitized investment cost
    ## If truck is not eligible for new charge capacity, fixed costs are zero
    if ammonia_settings["NetworkExpansion"] == 1
        @expression(
            MESS,
            eAObjFixInvTruOJ[j in TRUCK_TYPES],
            (
                dfTru[!, :Inv_Cost_Truck_per_unit][j] * dfTru[!, :Truck_AF][j] +
                dfTru[!, :Trailer_Number][j] *
                dfTru[!, :Trailer_AF][j] *
                dfTru[!, :Inv_Cost_Trailer_per_number][j]
            ) * MESS[:vANewTruNumber][j]
        )
        @expression(
            MESS,
            eAObjFixInvTru,
            sum(MESS[:eAObjFixInvTruOJ][j] for j in TRUCK_TYPES; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:eAObj], MESS[:eAObjFixInvTru])
    end

    ## Truck fixed operation and maintainance costs
    @expression(
        MESS,
        eAObjFixFomTruOJ[j in TRUCK_TYPES],
        (
            dfTru[!, :Fixed_OM_Cost_Truck_per_unit][j] +
            dfTru[!, :Trailer_Number][j] * dfTru[!, :Fixed_OM_Cost_Trailer_per_number][j]
        ) * MESS[:eATruNumber][j]
    )
    @expression(
        MESS,
        eAObjFixFomTru,
        sum(MESS[:eAObjFixFomTruOJ][j] for j in TRUCK_TYPES; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eAObj], MESS[:eAObjFixFomTru])

    ## Compression capacity costs
    ## Fixed costs for truck type "j" on zone "z" = annuitized investment cost plus fixed O&M costs
    if ammonia_settings["NetworkExpansion"] == 1
        @expression(
            MESS,
            eAObjFixInvTruCompOZJ[z in TRANSPORT_ZONES, j in TRUCK_TYPES],
            dfTru[!, :Inv_Cost_Comp_per_tonne_per_hr][j] *
            dfTru[!, :Comp_AF][j] *
            MESS[:vANewTruComp][z, j]
        )
        @expression(
            MESS,
            eAObjFixInvTruCompOJ[j in TRUCK_TYPES],
            sum(MESS[:eAObjFixInvTruCompOZJ][z, j] for z in TRANSPORT_ZONES; init = 0.0)
        )
        @expression(
            MESS,
            eAObjFixInvTruCompOZ[z in TRANSPORT_ZONES],
            sum(MESS[:eAObjFixInvTruCompOZJ][z, j] for j in TRUCK_TYPES; init = 0.0)
        )
        @expression(
            MESS,
            eAObjFixInvTruComp,
            sum(MESS[:eAObjFixInvTruCompOZ][z] for z in TRANSPORT_ZONES; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:eAObj], MESS[:eAObjFixInvTruComp])
    end

    ## Compression fixed operation and maintainance costs
    @expression(
        MESS,
        eAObjFixFomTruCompOZJ[z in TRANSPORT_ZONES, j in TRUCK_TYPES],
        dfTru[!, :Fixed_OM_Cost_Comp_per_tonne_per_hr][j] * MESS[:eATruComp][z, j]
    )
    @expression(
        MESS,
        eAObjFixFomTruCompOJ[j in TRUCK_TYPES],
        sum(MESS[:eAObjFixFomTruCompOZJ][z, j] for z in TRANSPORT_ZONES; init = 0.0)
    )
    @expression(
        MESS,
        eAObjFixFomTruCompOZ[z in TRANSPORT_ZONES],
        sum(MESS[:eAObjFixFomTruCompOZJ][z, j] for j in TRUCK_TYPES; init = 0.0)
    )
    @expression(
        MESS,
        eAObjFixFomTruComp,
        sum(MESS[:eAObjFixFomTruCompOZ][z] for z in TRANSPORT_ZONES; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eAObj], MESS[:eAObjFixFomTruComp])
    ## End Objective Expressions ##
    ### End Expressions ###

    ### Constraints ###
    ## Constraints on new built truck compression capacity
    ## Constraint on maximum compression capacity (if applicable) [set input to -1 if no constraint on maximum compression capacity]
    @constraint(
        MESS,
        cATruckMaxCompCap[
            z in TRANSPORT_ZONES,
            j in intersect(TRUCK_TYPES, dfTru[dfTru.Max_Comp_Cap_tonne .> 0, :T_ID]),
        ],
        eATruComp[z, j] <= dfTru[!, :Max_Comp_Cap_tonne][j]
    )

    ## Constraint on minimum energy capacity (if applicable) [set input to -1 if no constraint on minimum energy apacity]
    @constraint(
        MESS,
        cATruckMinCompCap[
            z in TRANSPORT_ZONES,
            j in intersect(TRUCK_TYPES, dfTru[dfTru.Min_Comp_Cap_tonne .> 0, :T_ID]),
        ],
        eATruComp[z, j] >= dfTru[!, :Min_Comp_Cap_tonne][j]
    )

    ## Integer constraints
    if ammonia_settings["TruckInteger"] == 1
        for j in TRUCK_TYPES
            set_integer.(MESS[:vANewTruNumber][j])
        end
    end
    ### End Constraints ###

    return MESS
end
