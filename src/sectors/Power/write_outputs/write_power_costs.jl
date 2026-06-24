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
function write_power_costs(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        power_settings = settings["PowerSettings"]
        path = power_settings["SavePath"]

        ## Flags
        IncludeExistingGen = power_settings["IncludeExistingGen"]

        ModelTransmission = power_settings["ModelTransmission"]
        IncludeExistingNetwork = power_settings["IncludeExistingNetwork"]

        ModelStorage = power_settings["ModelStorage"]
        IncludeExistingSto = power_settings["IncludeExistingSto"]

        AllowNse = power_settings["AllowNse"]
        CO2Policy = power_settings["CO2Policy"]

        ## Basic zonal and temporal resolution of the model
        Z = inputs["Z"]
        T = inputs["T"]
        Zones = inputs["Zones"]

        power_inputs = inputs["PowerInputs"]

        ## Generation related inputs
        G = power_inputs["G"]
        NEW_GEN_CAP = power_inputs["NEW_GEN_CAP"]
        dfGen = power_inputs["dfGen"]
        COMMIT = power_inputs["THERM_COMMIT"]

        ## Storage related inputs
        if ModelStorage == 1
            NEW_STO_CAP = power_inputs["NEW_STO_CAP"]
            dfSto = power_inputs["dfSto"]
            STO_ASYMMETRIC = power_inputs["STO_ASYMMETRIC"]
            AGING_STO = power_inputs["AGING_STO"]
        end

        if AllowNse == 1
            SEG = power_inputs["SEG"]
        end

        df = DataFrame(
            Costs = [
                "cTotal",
                "cFix",
                "cFixGen",
                "cFixGenInv",
                "cFixGenFom",
                "cFixSto",
                "cFixStoEne",
                "cFixStoEneInv",
                "cFixStoEneFom",
                "cFixStoDis",
                "cFixStoDisInv",
                "cFixStoDisFom",
                "cFixStoCha",
                "cFixStoChaInv",
                "cFixStoChaFom",
                "cVar",
                "cVarGen",
                "cVarStart",
                "cVarSto",
                "cVarStoAging",
                "cVarNse",
                "cVarEmi",
                "cNetworkExpansion",
                "cFeedstock",
                "cCO2DiposalTransport",
                "cCO2DiposalStorage",
            ],
        )

        ## Investment and fixed maintainance costs of generation
        cFixGenInv = round(value(MESS[:ePObjFixInvGen]); digits = 2)
        if IncludeExistingGen > 0
            cFixSunkGenInv = round(value(MESS[:ePObjFixSunkInvGen]); digits = 2)
            cFixGenInv += cFixSunkGenInv
        end
        cFixGenFom = round(value(MESS[:ePObjFixFomGen]); digits = 2)
        cFixGen = cFixGenInv + cFixGenFom

        ## Investment and fixed maintainance costs of storage energy
        cFixStoEneInv =
            (ModelStorage == 1) ? round(value(MESS[:ePObjFixInvStoEne]); digits = 2) : 0.0
        cFixStoEneFom =
            (ModelStorage == 1) ? round(value(MESS[:ePObjFixFomStoEne]); digits = 2) : 0.0
        if ModelStorage == 1
            cFixSunkStoEneInv =
                (IncludeExistingSto > 0) ? round(value(MESS[:ePObjFixSunkInvStoEne]); digits = 2) :
                0.0
            cFixStoEneInv += cFixSunkStoEneInv
        end
        cFixStoEne = cFixStoEneInv + cFixStoEneFom

        ## Investment and fixed maintainance costs of storage discharge
        cFixStoDisInv =
            (ModelStorage == 1) ? round(value(MESS[:ePObjFixInvStoDis]); digits = 2) : 0.0
        cFixStoDisFom =
            (ModelStorage == 1) ? round(value(MESS[:ePObjFixFomStoDis]); digits = 2) : 0.0
        if ModelStorage == 1
            cFixSunkStoDisInv =
                (IncludeExistingSto > 0) ? round(value(MESS[:ePObjFixSunkInvStoDis]); digits = 2) :
                0.0
            cFixStoDisInv += cFixSunkStoDisInv
        end
        cFixStoDis = cFixStoDisInv + cFixStoDisFom

        ## Investment and fixed maintainance costs of storage charge
        cFixStoChaInv =
            (ModelStorage == 1 && !isempty(STO_ASYMMETRIC)) ?
            round(value(MESS[:ePObjFixInvStoCha]); digits = 2) : 0.0
        cFixStoChaFom =
            (ModelStorage == 1 && !isempty(STO_ASYMMETRIC)) ?
            round(value(MESS[:ePObjFixFomStoCha]); digits = 2) : 0.0
        if (ModelStorage == 1 && !isempty(STO_ASYMMETRIC))
            cFixSunkStoChaInv =
                (IncludeExistingSto > 0) ? round(value(MESS[:ePObjFixSunkInvStoCha]); digits = 2) :
                0.0
            cFixStoChaInv += cFixSunkStoChaInv
        end
        cFixStoCha = cFixStoChaInv + cFixStoChaFom

        ## Fixed costs of storage = costs of energy + costs of discharge + costs of charge (if any)
        cFixSto = cFixStoEne + cFixStoDis + cFixStoCha

        ## Fixed costs = costs of generation + costs of storage
        cFix = cFixGen + cFixSto

        ## Variable costs
        cVarGen = round(value(MESS[:ePObjVarGen]); digits = 2)
        cVarStart = !isempty(COMMIT) ? round(value(MESS[:ePObjVarStart]); digits = 2) : 0.0
        cVarSto =
            (ModelStorage == 1) ?
            round(value(MESS[:ePObjVarStoCha]) + value(MESS[:ePObjVarStoDis]); digits = 2) : 0.0
        cVarStoAging =
            (ModelStorage == 1 && !isempty(AGING_STO)) ? round(value(MESS[:ePObjStoAging])) : 0
        cVarNse = (AllowNse == 1) ? round(value(MESS[:ePObjVarNse]); digits = 2) : 0.0
        cVarEmi = in(4, CO2Policy) ? round(value(MESS[:ePObjVarEmission]); digits = 2) : 0.0

        ## Variable costs = costs of generation + costs of start action + costs of storage + costs of non served energy + costs of emission
        cVar = cVarGen + cVarStart + cVarSto + cVarNse + cVarEmi

        ## Network expansion costs
        cNetworkExpansion =
            ModelTransmission == 1 ? round(value(MESS[:ePObjNetworkExpansion]); digits = 2) : 0.0
        if ModelTransmission == 1
            cNetworkExisting =
                IncludeExistingNetwork > 0 ?
                round(value(MESS[:ePObjNetworkExisting]); digits = 2) : 0.0
            cNetworkExpansion += cNetworkExisting
        end
        ## Feedstock expenses
        cFeedstock = round(value(MESS[:ePObjFeedStock]); digits = 2)

        ## CO2 Diposal Transport costs
        cCO2DiposalTransport =
            power_settings["CO2Disposal"] == 1 ?
            round(value(MESS[:ePObjCO2DisposalTransport]); digits = 2) : 0.0

        ## CO2 Diposal Storage costs
        cCO2DiposalStorage =
            power_settings["CO2Disposal"] == 1 ?
            round(value(MESS[:ePObjCO2DisposalStorage]); digits = 2) : 0.0

        ## Total cost = fixed costs + variable costs + network expansion costs + feedstock costs + CO2 disposal costs
        cTotal =
            cFix + cVar + cNetworkExpansion + cFeedstock + cCO2DiposalTransport + cCO2DiposalStorage

        df = hcat(
            df,
            DataFrame(
                Total = [
                    cTotal,
                    cFix,
                    cFixGen,
                    cFixGenInv,
                    cFixGenFom,
                    cFixSto,
                    cFixStoEne,
                    cFixStoEneInv,
                    cFixStoEneFom,
                    cFixStoDis,
                    cFixStoDisInv,
                    cFixStoDisFom,
                    cFixStoCha,
                    cFixStoChaInv,
                    cFixStoChaFom,
                    cVar,
                    cVarGen,
                    cVarStart,
                    cVarSto,
                    cVarStoAging,
                    cVarNse,
                    cVarEmi,
                    cNetworkExpansion,
                    cFeedstock,
                    cCO2DiposalTransport,
                    cCO2DiposalStorage,
                ],
            ),
        )

        for z in 1:Z
            tempcTotal = 0.0
            tempcFix = 0.0
            tempcFixGen = 0.0
            tempcFixGenInv = 0.0
            tempcFixGenFom = 0.0
            tempcFixSto = 0.0
            tempcFixStoEne = 0.0
            tempcFixStoEneInv = 0.0
            tempcFixStoEneFom = 0.0
            tempcFixStoDis = 0.0
            tempcFixStoDisInv = 0.0
            tempcFixStoDisFom = 0.0
            tempcFixStoCha = 0.0
            tempcFixStoChaInv = 0.0
            tempcFixStoChaFom = 0.0
            tempcVar = 0.0
            tempcVarGen = 0.0
            tempcVarStart = 0.0
            tempcVarSto = 0.0
            tempcVarStoAging = 0.0
            tempcVarNse = 0.0
            tempcVarEmi = 0.0
            tempcFeedstock = 0.0
            tempcDisposalTransport = 0.0
            tempcDisposalStorage = 0.0
            for g in dfGen[dfGen.Zone .== Zones[z], :R_ID]
                tempcFixGenInv +=
                    (g in NEW_GEN_CAP) ? round(value(MESS[:ePObjFixInvGenOG][g]); digits = 2) : 0.0
                if IncludeExistingGen > 0
                    tempcFixGenInv += round(value(MESS[:ePObjFixSunkInvGenOG][g]); digits = 2)
                end
                tempcFixGenFom += round(value(MESS[:ePObjFixFomGenOG][g]); digits = 2)

                tempcVarGen += round(value(MESS[:ePObjVarGenOG][g]); digits = 2)
                tempcVarStart +=
                    g in COMMIT ? round(value(MESS[:ePObjVarStartOG][g]); digits = 2) : 0.0
            end
            tempcFixGen += (tempcFixGenInv + tempcFixGenFom)

            if ModelStorage == 1
                for s in dfSto[dfSto.Zone .== Zones[z], :R_ID]
                    tempcFixStoEneInv +=
                        (s in NEW_STO_CAP) ?
                        round(value(MESS[:ePObjFixInvStoEneOS][s]); digits = 2) : 0.0
                    if IncludeExistingSto > 0
                        tempcFixStoEneInv +=
                            round(value(MESS[:ePObjFixSunkInvStoEneOS][s]); digits = 2)
                    end
                    tempcFixStoEneFom += round(value(MESS[:ePObjFixFomStoEneOS][s]); digits = 2)

                    tempcFixStoDisInv +=
                        (s in NEW_STO_CAP) ?
                        round(value(MESS[:ePObjFixInvStoDisOS][s]); digits = 2) : 0.0
                    if IncludeExistingSto > 0
                        tempcFixStoDisInv +=
                            round(value(MESS[:ePObjFixSunkInvStoDisOS][s]); digits = 2)
                    end
                    tempcFixStoDisFom += round(value(MESS[:ePObjFixFomStoDisOS][s]); digits = 2)

                    tempcFixStoChaInv +=
                        (!isempty(STO_ASYMMETRIC) && s in intersect(NEW_STO_CAP, STO_ASYMMETRIC)) ?
                        round(value(MESS[:ePObjFixInvStoChaOS][s]); digits = 2) : 0.0
                    if IncludeExistingSto > 0
                        tempcFixStoChaInv +=
                            !isempty(STO_ASYMMETRIC) ?
                            round(value(MESS[:ePObjFixSunkInvStoChaOS][s]); digits = 2) : 0.0
                    end
                    tempcFixStoChaFom +=
                        (!isempty(STO_ASYMMETRIC) && s in STO_ASYMMETRIC) ?
                        round(value(MESS[:ePObjFixFomStoChaOS][s]); digits = 2) : 0.0

                    tempcVarSto +=
                        round(value(MESS[:ePObjVarStoChaOS][s]); digits = 2) +
                        round(value(MESS[:ePObjVarStoDisOS][s]); digits = 2)

                    if s in AGING_STO
                        tempcVarStoAging += round(value(MESS[:ePObjStoAgingOS][s]); digits = 2)
                    end
                end
                tempcFixStoEne += (tempcFixStoEneInv + tempcFixStoEneFom)
                tempcFixStoDis += (tempcFixStoDisInv + tempcFixStoDisFom)
                tempcFixStoCha += (tempcFixStoChaInv + tempcFixStoChaFom)
                tempcFixSto += (tempcFixStoEne + tempcFixStoDis + tempcFixStoCha)
            end

            tempcVarNse += (AllowNse == 1) ? round(value(MESS[:ePObjVarNseOZ][z]); digits = 2) : 0.0
            tempcVarEmi +=
                in(4, CO2Policy) ? round(value(MESS[:ePObjVarEmissionOZ][z]); digits = 2) : 0.0

            ## Cost term for each zone
            tempcFix += (tempcFixGen + tempcFixSto)
            tempcVar += (tempcVarGen + tempcVarStart + tempcVarSto + tempcVarEmi)
            tempcFeedstock += round(value(MESS[:ePObjFeedStockOZ][z]); digits = 2)
            tempcDisposalTransport +=
                power_settings["CO2Disposal"] == 1 ?
                round(value(MESS[:ePObjCO2DisposalTransportOZ][z]); digits = 2) : 0.0
            tempcDisposalStorage +=
                power_settings["CO2Disposal"] == 1 ?
                round(value(MESS[:ePObjCO2DisposalStorageOZ][z]); digits = 2) : 0.0

            tempcTotal +=
                tempcFix + tempcVar + tempcFeedstock + tempcDisposalTransport + tempcDisposalStorage
            df[!, Symbol("$(Zones[z])")] = [
                tempcTotal,
                tempcFix,
                tempcFixGen,
                tempcFixGenInv,
                tempcFixGenFom,
                tempcFixSto,
                tempcFixStoEne,
                tempcFixStoEneInv,
                tempcFixStoEneFom,
                tempcFixStoDis,
                tempcFixStoDisInv,
                tempcFixStoDisFom,
                tempcFixStoCha,
                tempcFixStoChaInv,
                tempcFixStoChaFom,
                tempcVar,
                tempcVarGen,
                tempcVarStart,
                tempcVarSto,
                tempcVarStoAging,
                tempcVarNse,
                tempcVarEmi,
                "-",
                tempcFeedstock,
                tempcDisposalTransport,
                tempcDisposalStorage,
            ]
        end

        ## CSV writing
        CSV.write(joinpath(path, "costs.csv"), df)
    end
end
