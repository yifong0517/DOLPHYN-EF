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
function write_foodstuff_costs(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        foodstuff_settings = settings["FoodstuffSettings"]
        path = foodstuff_settings["SavePath"]

        ## Basic zonal and temporal resolution of the model
        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]

        foodstuff_inputs = inputs["FoodstuffInputs"]

        ## Storage related inputs
        NEW_STO_CAP = foodstuff_inputs["NEW_STO_CAP"]
        dfSto = foodstuff_inputs["dfSto"]

        ## Model flags
        AllowImport = foodstuff_settings["AllowImport"]
        AllowExport = foodstuff_settings["AllowExport"]
        CropTransport = foodstuff_settings["CropTransport"]
        FoodTransport = foodstuff_settings["FoodTransport"]
        ModelTrucks = foodstuff_settings["ModelTrucks"]
        TruckExpansion = foodstuff_settings["TruckExpansion"]

        if ModelTrucks == 1
            TRUCK_TYPES = foodstuff_inputs["TRUCK_TYPES"]
            TRUCK_ZONES = foodstuff_inputs["TRUCK_ZONES"]
        end

        df = DataFrame(
            Costs = [
                "cTotal",
                "cFix",
                "cFixFoodSto",
                "cFixFoodStoVolume",
                "cFixInvFoodStoVolume",
                "cFixFomFoodStoVolume",
                "cFixTru",
                "cFixInvTru",
                "cFixFomTru",
                "cVar",
                "cVarTru",
                "cVarProduction",
                "cVarCropTransport",
                "cVarFoodTransport",
                "cFeedStock",
                "cImport",
                "cExport",
            ],
        )

        ## Investment and fixed maintainance costs of storage food
        cFixInvFoodStoVolume = round(value(MESS[:eFObjFixInvFoodStoVolume]); digits = 2)
        cFixFomFoodStoVolume = round(value(MESS[:eFObjFixFomFoodStoVolume]); digits = 2)
        cFixFoodStoVolume = cFixInvFoodStoVolume + cFixFomFoodStoVolume

        ## Fixed costs of storage = costs of volume
        cFixFoodSto = cFixFoodStoVolume

        ## Investment costs of trucks
        cFixInvTru =
            ((TruckExpansion == 1) && (ModelTrucks == 1)) ?
            round(value(MESS[:eFObjFixInvTru]); digits = 2) : 0.0
        cFixFomTru = (ModelTrucks == 1) ? round(value(MESS[:eFObjFixFomTru]); digits = 2) : 0.0
        cFixTru = cFixInvTru + cFixFomTru

        ## Fixed costs = costs of storage + costs of trucks
        cFix = cFixFoodSto + cFixTru

        ## Variable costs
        cVarProduction = round(value(MESS[:eFObjFoodProduction]); digits = 2)
        cVarTru = (ModelTrucks == 1) ? round(value(MESS[:eFObjVarTru]); digits = 2) : 0.0
        cVarCropTransport =
            (CropTransport == 1) ? round(value(MESS[:eFObjCropTransportCosts]); digits = 2) : 0.0
        cVarFoodTransport =
            (FoodTransport == 1) ? round(value(MESS[:eFObjFoodTransportCosts]); digits = 2) : 0.0

        ## Variable costs = costs of trucks + cost of production
        cVar = cVarTru + cVarProduction + cVarCropTransport + cVarFoodTransport

        ## Feedstock costs
        cFeedstock = round(value(MESS[:eFObjFeedStock]); digits = 2)

        ## Import costs
        cImport = (AllowImport == 1) ? round(value(MESS[:eFObjCropImport]); digits = 2) : 0.0

        ## Export costs
        cExport = (AllowExport == 1) ? -round(value(MESS[:eFObjCropExport]); digits = 2) : 0.0

        ## Total cost = fixed costs + variable costs + feedstock costs + import costs - export costs
        cTotal = cFix + cVar + cFeedstock + cImport + cExport

        df = hcat(
            df,
            DataFrame(
                Total = [
                    cTotal,
                    cFix,
                    cFixFoodSto,
                    cFixFoodStoVolume,
                    cFixInvFoodStoVolume,
                    cFixFomFoodStoVolume,
                    cFixTru,
                    cFixInvTru,
                    cFixFomTru,
                    cVar,
                    cVarTru,
                    cVarProduction,
                    cVarCropTransport,
                    cVarFoodTransport,
                    cFeedstock,
                    cImport,
                    cExport,
                ],
            ),
        )

        for z in 1:Z
            tempcTotal = 0.0
            tempcFix = 0.0
            tempcFixFoodSto = 0.0
            tempcFixFoodStoVolume = 0.0
            tempcFixInvFoodStoVolume = 0.0
            tempcFixFomFoodStoVolume = 0.0
            tempcVar = 0.0
            tempcVarProduction = 0.0
            tempcFeedstock = 0.0
            ctempImport = 0.0
            ctempExport = 0.0

            for s in dfSto[dfSto.Zone .== Zones[z], :R_ID]
                tempcFixInvFoodStoVolume +=
                    (s in NEW_STO_CAP) ?
                    round(value(MESS[:eFObjFixInvFoodStoVolumeOS][s]); digits = 2) : 0.0
                tempcFixFomFoodStoVolume +=
                    round(value(MESS[:eFObjFixFomFoodStoVolumeOS][s]); digits = 2)
            end
            tempcFixFoodStoVolume += (tempcFixInvFoodStoVolume + tempcFixFomFoodStoVolume)

            tempcFixFoodSto += tempcFixFoodStoVolume

            tempcVarProduction += round(value(MESS[:eFObjFoodProductionOZ][z]); digits = 2)

            tempcFix += tempcFixFoodSto
            tempcVar += tempcVarProduction

            tempcFix += tempcFixFoodSto
            tempcFeedstock += round(value(MESS[:eFObjFeedStockOZ][z]); digits = 2)

            ctempImport += round(value(MESS[:eFObjCropImportOZ][z]); digits = 2)
            ctempExport -= round(value(MESS[:eFObjCropExportOZ][z]); digits = 2)

            tempcTotal += tempcFix + tempcVar + tempcFeedstock + ctempImport + ctempExport
            df[!, Symbol("$(Zones[z])")] = [
                tempcTotal,
                tempcFix,
                tempcFixFoodSto,
                tempcFixFoodStoVolume,
                tempcFixInvFoodStoVolume,
                tempcFixFomFoodStoVolume,
                "-",
                "-",
                "-",
                tempcVar,
                "-",
                tempcVarProduction,
                "-",
                "-",
                tempcFeedstock,
                ctempImport,
                ctempExport,
            ]
        end

        CSV.write(joinpath(path, "foodstuff_costs.csv"), df)
    end
end
