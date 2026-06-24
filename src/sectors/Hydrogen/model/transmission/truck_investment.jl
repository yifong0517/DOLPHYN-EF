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

    print_and_log(settings, "i", "Hydrogen Transmission Truck Investment Module")

    Z = inputs["Z"]
    Zones = inputs["Zones"]
    T = inputs["T"]

    hydrogen_settings = settings["HydrogenSettings"]
    hydrogen_inputs = inputs["HydrogenInputs"]

    dfTru = hydrogen_inputs["dfTru"]
    dfRoute = hydrogen_inputs["dfRoute"]

    TRUCK_TYPES = hydrogen_inputs["TRUCK_TYPES"]
    TRANSPORT_ZONES = hydrogen_inputs["TRANSPORT_ZONES"]

    ### Variables ###
    ## Truck capacity built and retired
    if hydrogen_settings["NetworkExpansion"] == 1
        ## New installed charge capacity of truck type "j"
        @variable(MESS, vHNewTruNumber[j in TRUCK_TYPES] >= 0)

        ## New installed energy capacity of truck type "j" on zone "z"
        @variable(MESS, vHNewTruComp[z in TRANSPORT_ZONES, j in TRUCK_TYPES] >= 0)
    end

    ### Expressions ###
    ## Total available truck numbers
    @expression(
        MESS,
        eHTruNumber[j in TRUCK_TYPES],
        if hydrogen_settings["NetworkExpansion"] == 1
            dfTru[!, :Existing_Number][j] + MESS[:vHNewTruNumber][j]
        else
            dfTru[!, :Existing_Number][j]
        end
    )

    ## Total available energy capacity in tonnes
    @expression(
        MESS,
        eHTruComp[z in TRANSPORT_ZONES, j in TRUCK_TYPES],
        if hydrogen_settings["NetworkExpansion"] == 1
            dfTru[!, Symbol("Existing_Comp_Cap_tonne_$z")][j] + MESS[:vHNewTruComp][z, j]
        else
            dfTru[!, Symbol("Existing_Comp_Cap_tonne_$z")][j]
        end
    )

    ## Objective Expressions ##
    ## Fixed costs for truck type "j" = annuitized investment cost
    ## If truck is not eligible for new charge capacity, fixed costs are zero
    if hydrogen_settings["NetworkExpansion"] == 1
        @expression(
            MESS,
            eHObjFixInvTruOJ[j in TRUCK_TYPES],
            (
                dfTru[!, :Inv_Cost_Truck_per_unit][j] * dfTru[!, :Truck_AF][j] +
                dfTru[!, :Trailer_Number][j] *
                dfTru[!, :Trailer_AF][j] *
                dfTru[!, :Inv_Cost_Trailer_per_number][j]
            ) * MESS[:vHNewTruNumber][j]
        )
        @expression(
            MESS,
            eHObjFixInvTru,
            sum(MESS[:eHObjFixInvTruOJ][j] for j in TRUCK_TYPES; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:eHObj], MESS[:eHObjFixInvTru])
    end

    ## Truck fixed operation and maintainance costs
    @expression(
        MESS,
        eHObjFixFomTruOJ[j in TRUCK_TYPES],
        (
            dfTru[!, :Fixed_OM_Cost_Truck_per_unit][j] +
            dfTru[!, :Trailer_Number][j] * dfTru[!, :Fixed_OM_Cost_Trailer_per_number][j]
        ) * MESS[:eHTruNumber][j]
    )
    @expression(
        MESS,
        eHObjFixFomTru,
        sum(MESS[:eHObjFixFomTruOJ][j] for j in TRUCK_TYPES; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eHObj], MESS[:eHObjFixFomTru])

    ## Compression capacity costs
    ## Fixed costs for truck type "j" on zone "z" = annuitized investment cost plus fixed O&M costs
    if hydrogen_settings["NetworkExpansion"] == 1
        @expression(
            MESS,
            eHObjFixInvTruCompOZJ[z in TRANSPORT_ZONES, j in TRUCK_TYPES],
            dfTru[!, :Inv_Cost_Comp_per_tonne_per_hr][j] *
            dfTru[!, :Comp_AF][j] *
            MESS[:vHNewTruComp][z, j]
        )
        @expression(
            MESS,
            eHObjFixInvTruCompOJ[j in TRUCK_TYPES],
            sum(MESS[:eHObjFixInvTruCompOZJ][z, j] for z in TRANSPORT_ZONES; init = 0.0)
        )
        @expression(
            MESS,
            eHObjFixInvTruCompOZ[z in TRANSPORT_ZONES],
            sum(MESS[:eHObjFixInvTruCompOZJ][z, j] for j in TRUCK_TYPES; init = 0.0)
        )
        @expression(
            MESS,
            eHObjFixInvTruComp,
            sum(MESS[:eHObjFixInvTruCompOZ][z] for z in TRANSPORT_ZONES; init = 0.0)
        )
        ## Add term to objective function expression
        add_to_expression!(MESS[:eHObj], MESS[:eHObjFixInvTruComp])
    end

    ## Compression fixed operation and maintainance costs
    @expression(
        MESS,
        eHObjFixFomTruCompOZJ[z in TRANSPORT_ZONES, j in TRUCK_TYPES],
        dfTru[!, :Fixed_OM_Cost_Comp_per_tonne_per_hr][j] * MESS[:eHTruComp][z, j]
    )
    @expression(
        MESS,
        eHObjFixFomTruCompOJ[j in TRUCK_TYPES],
        sum(MESS[:eHObjFixFomTruCompOZJ][z, j] for z in TRANSPORT_ZONES; init = 0.0)
    )
    @expression(
        MESS,
        eHObjFixFomTruCompOZ[z in TRANSPORT_ZONES],
        sum(MESS[:eHObjFixFomTruCompOZJ][z, j] for j in TRUCK_TYPES; init = 0.0)
    )
    @expression(
        MESS,
        eHObjFixFomTruComp,
        sum(MESS[:eHObjFixFomTruCompOZ][z] for z in TRANSPORT_ZONES; init = 0.0)
    )
    ## Add term to objective function expression
    add_to_expression!(MESS[:eHObj], MESS[:eHObjFixFomTruComp])
    ### End Expressions ###

    ### Constraints ###
    ## Constraints on new built truck compression capacity
    ## Constraint on maximum compression capacity (if applicable) [set input to -1 if no constraint on maximum compression capacity]
    @constraint(
        MESS,
        cHTruckMaxCompCap[
            z in TRANSPORT_ZONES,
            j in intersect(TRUCK_TYPES, dfTru[dfTru.Max_Comp_Cap_tonne .> 0, :T_ID]),
        ],
        MESS[:eHTruComp][z, j] <= dfTru[!, :Max_Comp_Cap_tonne][j]
    )

    ## Constraint on minimum energy capacity (if applicable) [set input to -1 if no constraint on minimum energy apacity]
    @constraint(
        MESS,
        cHTruckMinCompCap[
            z in TRANSPORT_ZONES,
            j in intersect(TRUCK_TYPES, dfTru[dfTru.Min_Comp_Cap_tonne .> 0, :T_ID]),
        ],
        MESS[:eHTruComp][z, j] >= dfTru[!, :Min_Comp_Cap_tonne][j]
    )

    ## Integer constraints
    if hydrogen_settings["TruckInteger"] == 1
        if hydrogen_settings["NetworkExpansion"] == 1
            for j in TRUCK_TYPES
                set_integer.(MESS[:vHNewTruNumber][j])
            end
        end
    end
    ### End Constraints ###

    return MESS
end
