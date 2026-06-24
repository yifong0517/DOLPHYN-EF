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
function write_bioenergy_costs(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        bioenergy_settings = settings["BioenergySettings"]
        path = bioenergy_settings["SavePath"]

        ## Flags
        NetworkExpansion = bioenergy_settings["NetworkExpansion"]
        ModelTrucks = bioenergy_settings["ModelTrucks"]

        ModelStorage = bioenergy_settings["ModelStorage"]
        IncludeExistingSto = bioenergy_settings["IncludeExistingSto"]

        CO2Policy = bioenergy_settings["CO2Policy"]

        ## Basic zonal and temporal resolution of the model
        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]

        bioenergy_inputs = inputs["BioenergyInputs"]

        ## Storage related inputs
        if bioenergy_settings["ModelStorage"] == 1
            S = bioenergy_inputs["S"]
            NEW_STO_CAP = bioenergy_inputs["NEW_STO_CAP"]
            dfSto = bioenergy_inputs["dfSto"]
        end

        if ModelTrucks == 1
            TRUCK_TYPES = bioenergy_inputs["TRUCK_TYPES"]
            TRUCK_ZONES = bioenergy_inputs["TRUCK_ZONES"]
        end

        df = DataFrame(
            Costs = [
                "cTotal",
                "cFix",
                "cFixSto",
                "cFixStoVolume",
                "cFixStoVolumeInv",
                "cFixStoVolumeFom",
                "cFixTru",
                "cFixTruInv",
                "cFixTruFom",
                "cVar",
                "cVarEmi",
                "cVarTru",
                "cFeedstock",
            ],
        )

        ## Investment and fixed maintainance costs of storage energy
        cFixStoVolumeInv =
            (ModelStorage == 1) ? round(value(MESS[:eBObjFixInvStoVolume]); sigdigits = 2) : 0.0
        if ModelStorage == 1
            cFixSunkStoVolumeInv =
                (IncludeExistingSto == 1) ?
                round(value(MESS[:eBObjFixSunkInvStoVolume]); digits = 2) : 0.0
            cFixStoVolumeInv += cFixSunkStoVolumeInv
        end
        cFixStoVolumeFom =
            (ModelStorage == 1) ? round(value(MESS[:eBObjFixFomStoVolume]); sigdigits = 2) : 0.0
        cFixStoVolume = cFixStoVolumeInv + cFixStoVolumeFom

        ## Fixed costs of storage = costs of volume
        cFixSto = cFixStoVolume

        ## Investment costs of trucks
        cFixTruInv =
            ((NetworkExpansion == 1) && (ModelTrucks == 1)) ?
            round(value(MESS[:eBObjFixInvTru]); sigdigits = 2) : 0.0
        cFixTruFom = (ModelTrucks == 1) ? round(value(MESS[:eBObjFixFomTru]); sigdigits = 2) : 0.0
        cFixTru = cFixTruInv + cFixTruFom

        ## Fixed costs = costs of generation + costs of storage + costs of trucks
        cFix = cFixSto + cFixTru

        ## Variable costs
        cVarEmi = in(4, CO2Policy) ? round(value(MESS[:eBObjVarEmission]); sigdigits = 2) : 0.0
        cVarTru = (ModelTrucks == 1) ? round(value(MESS[:eBObjVarTru]); sigdigits = 2) : 0.0

        ## Variable costs = costs of generation + costs of non served energy + costs of trucks
        cVar = cVarEmi + cVarTru

        ## Feedstock expenses
        cFeedstock = round(value(MESS[:eBObjFeedStock]); digits = 2)

        ## Total cost = fixed costs + variable costs + network expansion costs
        cTotal = cFix + cVar + cFeedstock

        df = hcat(
            df,
            DataFrame(
                Total = [
                    cTotal,
                    cFix,
                    cFixSto,
                    cFixStoVolume,
                    cFixStoVolumeInv,
                    cFixStoVolumeFom,
                    cFixTru,
                    cFixTruInv,
                    cFixTruFom,
                    cVar,
                    cVarEmi,
                    cVarTru,
                    cFeedstock,
                ],
            ),
        )

        for z in 1:Z
            tempcTotal = 0.0
            tempcFix = 0.0
            tempcFixSto = 0.0
            tempcFixStoVolume = 0.0
            tempcFixStoVolumeInv = 0.0
            tempcFixStoVolumeFom = 0.0
            tempcVar = 0.0
            tempcVarGen = 0.0
            tempcVarNse = 0.0
            tempcVarEmi = 0.0
            tempcFeedstock = 0.0

            if ModelStorage == 1
                for s in dfSto[dfSto.Zone .== Zones[z], :R_ID]
                    tempcFixStoVolumeInv +=
                        (s in NEW_STO_CAP) ?
                        round(value(MESS[:eBObjFixInvStoVolumeOS][s]); sigdigits = 2) : 0.0
                    if IncludeExistingSto == 1
                        tempcFixStoVolumeInv +=
                            round(value(MESS[:eBObjFixSunkInvStoVolumeOS][s]); digits = 2)
                    end
                    tempcFixStoVolumeFom +=
                        round(value(MESS[:eBObjFixFomStoVolumeOS][s]); sigdigits = 2)
                end
                tempcFixStoVolume += (tempcFixStoVolumeInv + tempcFixStoVolumeFom)
                tempcFixSto += tempcFixStoVolume
            end

            tempcVarEmi +=
                in(4, CO2Policy) ? round(value(MESS[:eBObjVarEmissionOZ][z]); sigdigits = 2) : 0.0

            tempcFix += tempcFixStoVolume
            tempcVar += tempcVarEmi
            tempcFeedstock += round(value(MESS[:eBObjFeedStockOZ][z]); sigdigits = 2)

            tempcTotal += (tempcFix + tempcVar + tempcFeedstock)
            df[!, Symbol("$(Zones[z])")] = [
                tempcTotal,
                tempcFix,
                tempcFixSto,
                tempcFixStoVolume,
                tempcFixStoVolumeInv,
                tempcFixStoVolumeFom,
                "-",
                "-",
                "-",
                tempcVar,
                tempcVarEmi,
                "-",
                tempcFeedstock,
            ]
        end

        ## CSV writing
        CSV.write(joinpath(path, "costs.csv"), df)
    end
end
