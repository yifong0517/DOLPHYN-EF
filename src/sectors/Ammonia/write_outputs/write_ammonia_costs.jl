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
function write_ammonia_costs(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        ammonia_settings = settings["AmmoniaSettings"]
        path = ammonia_settings["SavePath"]

        ## Flags
        IncludeExistingGen = ammonia_settings["IncludeExistingGen"]

        SimpleTransport = ammonia_settings["SimpleTransport"]
        NetworkExpansion = ammonia_settings["NetworkExpansion"]
        ModelTrucks = ammonia_settings["ModelTrucks"]

        ModelStorage = ammonia_settings["ModelStorage"]
        IncludeExistingSto = ammonia_settings["IncludeExistingSto"]

        AllowNse = ammonia_settings["AllowNse"]
        CO2Policy = ammonia_settings["CO2Policy"]

        ## Basic zonal and temporal resolution of the model
        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]

        ammonia_inputs = inputs["AmmoniaInputs"]

        ## Generation related inputs
        G = ammonia_inputs["G"]
        NEW_GEN_CAP = ammonia_inputs["NEW_GEN_CAP"]
        dfGen = ammonia_inputs["dfGen"]
        COMMIT = ammonia_inputs["COMMIT"]

        ## Storage related inputs
        if ammonia_settings["ModelStorage"] == 1
            S = ammonia_inputs["S"]
            NEW_STO_CAP = ammonia_inputs["NEW_STO_CAP"]
            dfSto = ammonia_inputs["dfSto"]
        end

        if ModelTrucks == 1
            TRUCK_TYPES = ammonia_inputs["TRUCK_TYPES"]
            TRANSPORT_ZONES = ammonia_inputs["TRANSPORT_ZONES"]
        end

        if AllowNse == 1
            SEG = ammonia_inputs["SEG"]
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
                "cFixTru",
                "cFixTruInv",
                "cFixTruFom",
                "cFixTruComp",
                "cFixTruCompInv",
                "cFixTruCompFom",
                "cVar",
                "cVarGen",
                "cVarStart",
                "cVarSto",
                "cVarNse",
                "cVarEmi",
                "cVarTru",
                "cVarTruComp",
                "cVarTransport",
                "cFeedstock",
                "cCO2DiposalTransport",
                "cCO2DiposalStorage",
            ],
        )

        ## Investment and fixed maintainance costs of generation
        cFixGenInv = round(value(MESS[:eAObjFixInvGen]); digits = 2)
        if IncludeExistingGen > 0
            cFixSunkGenInv = round(value(MESS[:eAObjFixSunkInvGen]); digits = 2)
            cFixGenInv += cFixSunkGenInv
        end
        cFixGenFom = round(value(MESS[:eAObjFixFomGen]); digits = 2)
        cFixGen = cFixGenInv + cFixGenFom

        ## Investment and fixed maintainance costs of storage energy
        cFixStoEneInv =
            (ModelStorage == 1) ? round(value(MESS[:eAObjFixInvStoEne]); digits = 2) : 0.0
        if ModelStorage == 1
            cFixSunkStoEneInv =
                (IncludeExistingSto == 1) ? round(value(MESS[:eAObjFixSunkInvStoEne]); digits = 2) :
                0.0
            cFixStoEneInv += cFixSunkStoEneInv
        end
        cFixStoEneFom =
            (ModelStorage == 1) ? round(value(MESS[:eAObjFixFomStoEne]); digits = 2) : 0.0
        cFixStoEne = cFixStoEneInv + cFixStoEneFom

        ## Investment and fixed maintainance costs of storage discharge
        cFixStoDisInv =
            (ModelStorage == 1) ? round(value(MESS[:eAObjFixInvStoDis]); digits = 2) : 0.0
        if ModelStorage == 1
            cFixSunkStoDisInv =
                (IncludeExistingSto == 1) ? round(value(MESS[:eAObjFixSunkInvStoDis]); digits = 2) :
                0.0
            cFixStoDisInv += cFixSunkStoDisInv
        end
        cFixStoDisFom =
            (ModelStorage == 1) ? round(value(MESS[:eAObjFixFomStoDis]); digits = 2) : 0.0
        cFixStoDis = cFixStoDisInv + cFixStoDisFom

        ## Investment and fixed maintainance costs of storage charge
        cFixStoChaInv =
            (ModelStorage == 1) ? round(value(MESS[:eAObjFixInvStoCha]); digits = 2) : 0.0
        if ModelStorage == 1
            cFixSunkStoChaInv =
                (IncludeExistingSto == 1) ? round(value(MESS[:eAObjFixSunkInvStoCha]); digits = 2) :
                0.0
            cFixStoChaInv += cFixSunkStoChaInv
        end
        cFixStoChaFom =
            (ModelStorage == 1) ? round(value(MESS[:eAObjFixFomStoCha]); digits = 2) : 0.0
        cFixStoCha = cFixStoChaInv + cFixStoChaFom

        ## Fixed costs of storage = costs of energy + costs of discharge + costs of charge (if any)
        cFixSto = cFixStoEne + cFixStoDis + cFixStoCha

        ## Investment costs of trucks
        cFixTruInv =
            ((NetworkExpansion == 1) && (ModelTrucks == 1)) ?
            round(value(MESS[:eAObjFixInvTru]); digits = 2) : 0.0
        cFixTruFom = (ModelTrucks == 1) ? round(value(MESS[:eAObjFixFomTru]); digits = 2) : 0.0
        cFixTru = cFixTruInv + cFixTruFom

        ## Investment and maintainance costs of truck compression
        cFixTruCompInv =
            ((NetworkExpansion == 1) && (ModelTrucks == 1)) ?
            round(value(MESS[:eAObjFixInvTruComp]); digits = 2) : 0.0
        cFixTruCompFom = (ModelTrucks == 1) ? value(MESS[:eAObjFixFomTruComp]) : 0.0
        cFixTruComp = cFixTruCompInv + cFixTruCompFom

        ## Fixed costs = costs of generation + costs of storage + costs of trucks + costs of trucks compression
        cFix = cFixGen + cFixSto + cFixTru + cFixTruComp

        ## Variable costs
        cVarGen = round(value(MESS[:eAObjVarGen]); digits = 2)
        cVarStart = !isempty(COMMIT) ? round(value(MESS[:eAObjVarStart]); digits = 2) : 0.0
        cVarSto =
            (ModelStorage == 1) ?
            round(value(MESS[:eAObjVarStoCha] + value(MESS[:eAObjVarStoDis])); digits = 2) : 0.0
        cVarNse = (AllowNse == 1) ? round(value(MESS[:eAObjVarNse]); digits = 2) : 0.0
        cVarEmi = in(4, CO2Policy) ? round(value(MESS[:eAObjVarEmission]); digits = 2) : 0.0
        cVarTru = (ModelTrucks == 1) ? round(value(MESS[:eAObjVarTru]); digits = 2) : 0.0
        cVarTruComp = (ModelTrucks == 1) ? round(value(MESS[:eAObjVarTruComp]); digits = 2) : 0.0
        cVarTransport =
            (SimpleTransport == 1) ? round(value(MESS[:eAObjTransportCosts]); digits = 2) : 0.0

        ## Variable costs = costs of generation + costs of start action + costs of storage + costs of non served energy + costs of trucks + costs of trucks compression + costs of transport
        cVar =
            cVarGen +
            cVarStart +
            cVarSto +
            cVarNse +
            cVarEmi +
            cVarTru +
            cVarTruComp +
            cVarTransport

        ## Feedstock expenses
        cFeedstock = round(value(MESS[:eAObjFeedStock]); digits = 2)

        ## CO2 disposal costs
        cCO2DiposalTransport =
            ammonia_settings["CO2Disposal"] == 1 ?
            round(value(MESS[:eAObjCO2DisposalTransport]); digits = 2) : 0.0

        cCO2DiposalStorage =
            ammonia_settings["CO2Disposal"] == 1 ?
            round(value(MESS[:eAObjCO2DisposalStorage]); digits = 2) : 0.0

        ## Total cost = fixed costs + variable costs + feedstock expenses + CO2 disposal costs
        cTotal = cFix + cVar + cFeedstock + cCO2DiposalTransport + cCO2DiposalStorage

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
                    cFixTru,
                    cFixTruInv,
                    cFixTruFom,
                    cFixTruComp,
                    cFixTruCompInv,
                    cFixTruCompFom,
                    cVar,
                    cVarGen,
                    cVarStart,
                    cVarSto,
                    cVarNse,
                    cVarEmi,
                    cVarTru,
                    cVarTruComp,
                    cVarTransport,
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
            tempcFixTruComp = 0.0
            tempcFixTruCompInv = 0.0
            tempcFixTruCompFom = 0.0
            tempcVar = 0.0
            tempcVarGen = 0.0
            tempcVarStart = 0.0
            tempcVarSto = 0.0
            tempcVarNse = 0.0
            tempcVarEmi = 0.0
            tempcFeedstock = 0.0
            tempcCO2DiposalTransport = 0.0
            tempcCO2DiposalStorage = 0.0

            for g in dfGen[dfGen.Zone .== Zones[z], :R_ID]
                tempcFixGenInv +=
                    (g in NEW_GEN_CAP) ? round(value(MESS[:eAObjFixInvGenOG][g]); digits = 2) : 0.0
                if IncludeExistingGen > 0
                    tempcFixGenInv += round(value(MESS[:eAObjFixSunkInvGenOG][g]); digits = 2)
                end
                tempcFixGenFom += round(value(MESS[:eAObjFixFomGenOG][g]); digits = 2)

                tempcVarGen += round(value(MESS[:eAObjVarGenOG][g]); digits = 2)
                tempcVarStart +=
                    g in COMMIT ? round(value(MESS[:eAObjVarStartOG][g]); digits = 2) : 0.0
            end
            tempcFixGen += (tempcFixGenInv + tempcFixGenFom)

            if ammonia_settings["ModelStorage"] == 1
                for s in dfSto[dfSto.Zone .== Zones[z], :R_ID]
                    tempcFixStoEneInv +=
                        (s in NEW_STO_CAP) ?
                        round(value(MESS[:eAObjFixInvStoEneOS][s]); digits = 2) : 0.0
                    if IncludeExistingSto == 1
                        tempcFixStoEneInv +=
                            round(value(MESS[:eAObjFixSunkInvStoEneOS][s]); digits = 2)
                    end
                    tempcFixStoEneFom += round(value(MESS[:eAObjFixFomStoEneOS][s]); digits = 2)

                    tempcFixStoDisInv +=
                        (s in NEW_STO_CAP) ?
                        round(value(MESS[:eAObjFixInvStoDisOS][s]); digits = 2) : 0.0
                    if IncludeExistingSto == 1
                        tempcFixStoDisInv +=
                            round(value(MESS[:eAObjFixSunkInvStoDisOS][s]); digits = 2)
                    end
                    tempcFixStoDisFom += round(value(MESS[:eAObjFixFomStoDisOS][s]); digits = 2)

                    tempcFixStoChaInv +=
                        s in intersect(NEW_STO_CAP) ?
                        round(value(MESS[:eAObjFixInvStoChaOS][s]); digits = 2) : 0.0
                    if IncludeExistingSto == 1
                        tempcFixStoChaInv +=
                            round(value(MESS[:eAObjFixSunkInvStoChaOS][s]); digits = 2)
                    end
                    tempcFixStoChaFom += round(value(MESS[:eAObjFixFomStoChaOS][s]); digits = 2)

                    tempcVarSto += round(
                        value(MESS[:eAObjVarStoChaOS][s] + MESS[:eAObjVarStoDisOS][s]);
                        digits = 2,
                    )
                end
                tempcFixStoEne += (tempcFixStoEneInv + tempcFixStoEneFom)
                tempcFixStoDis += (tempcFixStoDisInv + tempcFixStoDisFom)
                tempcFixStoCha += (tempcFixStoChaInv + tempcFixStoChaFom)
                tempcFixSto += (tempcFixStoEne + tempcFixStoDis + tempcFixStoCha)
            end

            tempcVarNse += (AllowNse == 1) ? round(value(MESS[:eAObjVarNseOZ][z]); digits = 2) : 0.0
            tempcVarEmi +=
                in(4, CO2Policy) ? round(value(MESS[:eAObjVarEmissionOZ][z]); digits = 2) : 0.0

            if (ModelTrucks == 1)
                if (NetworkExpansion == 1)
                    tempcFixTruCompInv +=
                        (Zones[z] in TRANSPORT_ZONES) ?
                        round(value(MESS[:eAObjFixInvTruCompOZ][Zones[z]]); digits = 2) : 0.0
                end
                tempcFixTruCompFom +=
                    (Zones[z] in TRANSPORT_ZONES) ? value(MESS[:eAObjFixFomTruCompOZ][Zones[z]]) :
                    0.0
                tempcFixTruComp
            end

            tempcFix += (tempcFixGen + tempcFixSto + tempcFixTruComp)
            tempcVar += (tempcVarGen + tempcVarStart + tempcVarSto + tempcVarNse + tempcVarEmi)
            tempcFeedstock += round(value(MESS[:eAObjFeedStockOZ][z]))
            tempcCO2DiposalTransport +=
                ammonia_settings["CO2Disposal"] == 1 ?
                round(value(MESS[:eAObjCO2DisposalTransportOZ][z]); digits = 2) : 0.0
            tempcCO2DiposalStorage +=
                ammonia_settings["CO2Disposal"] == 1 ?
                round(value(MESS[:eAObjCO2DisposalStorageOZ][z]); digits = 2) : 0.0

            tempcTotal +=
                tempcFix +
                tempcVar +
                tempcFeedstock +
                tempcCO2DiposalTransport +
                tempcCO2DiposalStorage
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
                "-",
                "-",
                "-",
                tempcFixTruComp,
                tempcFixTruCompInv,
                tempcFixTruCompFom,
                tempcVar,
                tempcVarGen,
                tempcVarStart,
                tempcVarSto,
                tempcVarNse,
                tempcVarEmi,
                "-",
                "-",
                "-",
                tempcFeedstock,
                tempcCO2DiposalTransport,
                tempcCO2DiposalStorage,
            ]
        end

        ## CSV writing
        CSV.write(joinpath(path, "costs.csv"), df)
    end
end
