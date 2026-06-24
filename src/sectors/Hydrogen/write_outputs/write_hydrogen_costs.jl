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
function write_hydrogen_costs(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        hydrogen_settings = settings["HydrogenSettings"]
        path = hydrogen_settings["SavePath"]

        ## Flags
        IncludeExistingGen = hydrogen_settings["IncludeExistingGen"]

        SimpleTransport = hydrogen_settings["SimpleTransport"]
        NetworkExpansion = hydrogen_settings["NetworkExpansion"]
        IncludeExistingNetwork = hydrogen_settings["IncludeExistingNetwork"]
        ModelPipelines = hydrogen_settings["ModelPipelines"]
        ModelTrucks = hydrogen_settings["ModelTrucks"]

        ModelStorage = hydrogen_settings["ModelStorage"]
        IncludeExistingSto = hydrogen_settings["IncludeExistingSto"]

        AllowNse = hydrogen_settings["AllowNse"]
        CO2Policy = hydrogen_settings["CO2Policy"]

        ## Basic zonal and temporal resolution of the model
        Z = inputs["Z"]
        T = inputs["T"]
        Zones = inputs["Zones"]

        hydrogen_inputs = inputs["HydrogenInputs"]

        ## Generation related inputs
        G = hydrogen_inputs["G"]
        NEW_GEN_CAP = hydrogen_inputs["NEW_GEN_CAP"]
        dfGen = hydrogen_inputs["dfGen"]
        COMMIT = hydrogen_inputs["COMMIT"]

        ## Storage related inputs
        if ModelStorage == 1
            S = hydrogen_inputs["S"]
            NEW_STO_CAP = hydrogen_inputs["NEW_STO_CAP"]
            dfSto = hydrogen_inputs["dfSto"]
        end

        if ModelTrucks == 1
            TRUCK_TYPES = hydrogen_inputs["TRUCK_TYPES"]
            TRANSPORT_ZONES = hydrogen_inputs["TRANSPORT_ZONES"]
        end

        if AllowNse == 1
            SEG = hydrogen_inputs["SEG"]
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
                "cNetworkExpansion",
                "cNetworkComp",
                "cFeedstock",
                "cCO2DiposalTransport",
                "cCO2DiposalStorage",
            ],
        )

        ## Investment and fixed maintainance costs of generation
        cFixGenInv = round(value(MESS[:eHObjFixInvGen]); digits = 2)
        if IncludeExistingGen > 0
            cFixSunkGenInv = round(value(MESS[:eHObjFixSunkInvGen]); digits = 2)
            cFixGenInv += cFixSunkGenInv
        end
        cFixGenFom = round(value(MESS[:eHObjFixFomGen]); digits = 2)
        cFixGen = cFixGenInv + cFixGenFom

        ## Investment and fixed maintainance costs of storage energy
        cFixStoEneInv =
            (ModelStorage == 1) ? round(value(MESS[:eHObjFixInvStoEne]); digits = 2) : 0.0
        if ModelStorage == 1
            cFixSunkStoEneInv =
                (IncludeExistingSto == 1) ? round(value(MESS[:eHObjFixSunkInvStoEne]); digits = 2) :
                0.0
            cFixStoEneInv += cFixSunkStoEneInv
        end
        cFixStoEneFom =
            (ModelStorage == 1) ? round(value(MESS[:eHObjFixFomStoEne]); digits = 2) : 0.0
        cFixStoEne = cFixStoEneInv + cFixStoEneFom

        ## Investment and fixed maintainance costs of storage discharge
        cFixStoDisInv =
            (ModelStorage == 1) ? round(value(MESS[:eHObjFixInvStoDis]); digits = 2) : 0.0
        if ModelStorage == 1
            cFixSunkStoDisInv =
                (IncludeExistingSto == 1) ? round(value(MESS[:eHObjFixSunkInvStoDis]); digits = 2) :
                0.0
            cFixStoDisInv += cFixSunkStoDisInv
        end
        cFixStoDisFom = (ModelStorage == 1) ? round(value(MESS[:eHObjFixFomStoDis])) : 0.0
        cFixStoDis = cFixStoDisInv + cFixStoDisFom

        ## Investment and fixed maintainance costs of storage charge
        cFixStoChaInv =
            (ModelStorage == 1) ? round(value(MESS[:eHObjFixInvStoCha]); digits = 2) : 0.0
        if ModelStorage == 1
            cFixSunkStoChaInv =
                (IncludeExistingSto == 1) ? round(value(MESS[:eHObjFixSunkInvStoCha]); digits = 2) :
                0.0
            cFixStoChaInv += cFixSunkStoChaInv
        end
        cFixStoChaFom =
            (ModelStorage == 1) ? round(value(MESS[:eHObjFixFomStoCha]); digits = 2) : 0.0
        cFixStoCha = cFixStoChaInv + cFixStoChaFom

        ## Fixed costs of storage = costs of energy + costs of discharge (if any) + costs of charge
        cFixSto = cFixStoEne + cFixStoDis + cFixStoCha

        ## Investment costs of trucks
        cFixTruInv =
            ((NetworkExpansion == 1) && (ModelTrucks == 1)) ?
            round(value(MESS[:eHObjFixInvTru]); digits = 2) : 0.0
        cFixTruFom =
            ((NetworkExpansion == 1) && (ModelTrucks == 1)) ?
            round(value(MESS[:eHObjFixFomTru]); digits = 2) : 0.0
        cFixTru = cFixTruInv + cFixTruFom

        ## Investment and maintainance costs of truck compression
        cFixTruCompInv =
            ((NetworkExpansion == 1) && (ModelTrucks == 1)) ?
            round(value(MESS[:eHObjFixInvTruComp]); digits = 2) : 0.0
        cFixTruCompFom =
            (ModelTrucks == 1) ? round(value.(MESS[:eHObjFixFomTruComp]); digits = 2) : 0.0
        cFixTruComp = cFixTruCompInv + cFixTruCompFom

        ## Fixed costs = costs of generation + costs of storage + costs of trucks + costs of trucks compression
        cFix = cFixGen + cFixSto + cFixTru + cFixTruComp

        ## Variable costs
        cVarGen = round(value(MESS[:eHObjVarGen]); digits = 2)
        cVarStart = !isempty(COMMIT) ? round(value(MESS[:eHObjVarStart]); digits = 2) : 0.0
        cVarSto =
            (ModelStorage == 1) ?
            round(value(MESS[:eHObjVarStoCha]) + value(MESS[:eHObjVarStoDis]); digits = 2) : 0.0
        cVarNse = (AllowNse == 1) ? round(value(MESS[:eHObjVarNse]); digits = 2) : 0.0
        cVarEmi = in(4, CO2Policy) ? round(value(MESS[:eHObjVarEmission]); digits = 2) : 0.0
        cVarTru = (ModelTrucks == 1) ? round(value(MESS[:eHObjVarTru]); digits = 2) : 0.0
        cVarTruComp = (ModelTrucks == 1) ? round(value(MESS[:eHObjVarTruComp]); digits = 2) : 0.0
        cVarTransport =
            (SimpleTransport == 1) ? round(value(MESS[:eHObjTransportCosts]); digits = 2) : 0.0

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

        ## Network expansion costs
        cNetworkExpansion =
            (ModelPipelines == 1) ? round(value(MESS[:eHObjNetworkExpansion]); digits = 2) : 0.0
        if (ModelPipelines == 1)
            cNetworkExisting =
                IncludeExistingNetwork == 1 ?
                round(value(MESS[:eHObjNetworkExisting]); digits = 2) : 0.0
            cNetworkExpansion += cNetworkExisting
        end
        ## Pipeline compression costs
        cNetworkComp =
            (ModelPipelines == 1) ? round(value(MESS[:eHObjFixPipeComp]); digits = 2) : 0.0

        ## Feedstock expenses
        cFeedstock = round(value(MESS[:eHObjFeedStock]); digits = 2)

        ## CO2 Diposal Transport costs
        cCO2DiposalTransport =
            hydrogen_settings["CO2Disposal"] == 1 ?
            round(value(MESS[:eHObjCO2DisposalTransport]); digits = 2) : 0.0

        ## CO2 Diposal Storage costs
        cCO2DiposalStorage =
            hydrogen_settings["CO2Disposal"] == 1 ?
            round(value(MESS[:eHObjCO2DisposalStorage]); digits = 2) : 0.0

        ## Total cost = fixed costs + variable costs + network expansion costs + network compression costs + feedstock expense + CO2 disposal costs
        cTotal =
            cFix +
            cVar +
            cNetworkExpansion +
            cNetworkComp +
            cFeedstock +
            cCO2DiposalTransport +
            cCO2DiposalStorage

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
                    cNetworkExpansion,
                    cNetworkComp,
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
                    (g in NEW_GEN_CAP) ? round(value(MESS[:eHObjFixInvGenOG][g]); digits = 2) : 0.0
                if IncludeExistingGen > 0
                    tempcFixGenInv += round(value(MESS[:eHObjFixSunkInvGenOG][g]); digits = 2)
                end
                tempcFixGenFom += round(value(MESS[:eHObjFixFomGenOG][g]); digits = 2)

                tempcVarGen += round(value(MESS[:eHObjVarGenOG][g]); digits = 2)
                tempcVarStart +=
                    g in COMMIT ? round(value(MESS[:eHObjVarStartOG][g]); digits = 2) : 0.0
            end
            tempcFixGen += (tempcFixGenInv + tempcFixGenFom)

            for s in dfSto[dfSto.Zone .== Zones[z], :R_ID]
                tempcFixStoEneInv +=
                    ((ModelStorage == 1) && (s in NEW_STO_CAP)) ?
                    round(value(MESS[:eHObjFixInvStoEneOS][s]); digits = 2) : 0.0
                if ModelStorage == 1
                    tempcFixStoEneInv +=
                        (IncludeExistingSto == 1) ?
                        round(value(MESS[:eHObjFixSunkInvStoEneOS][s]); digits = 2) : 0.0
                end
                tempcFixStoEneFom +=
                    (ModelStorage == 1) ? round(value(MESS[:eHObjFixFomStoEneOS][s]); digits = 2) :
                    0.0

                tempcFixStoDisInv +=
                    ((ModelStorage == 1) && (s in NEW_STO_CAP)) ?
                    round(value(MESS[:eHObjFixInvStoDisOS][s]); digits = 2) : 0.0
                if ModelStorage == 1
                    tempcFixStoDisInv +=
                        (IncludeExistingSto == 1) ?
                        round(value(MESS[:eHObjFixSunkInvStoDisOS][s]); digits = 2) : 0.0
                end
                tempcFixStoDisFom +=
                    (ModelStorage == 1) ? round(value(MESS[:eHObjFixFomStoDisOS][s]); digits = 2) :
                    0.0

                tempcFixStoChaInv +=
                    ((ModelStorage == 1) && (s in NEW_STO_CAP)) ?
                    round(value(MESS[:eHObjFixInvStoChaOS][s]); digits = 2) : 0.0
                if ModelStorage == 1
                    tempcFixStoChaInv +=
                        (IncludeExistingSto == 1) ?
                        round(value(MESS[:eHObjFixSunkInvStoChaOS][s]); digits = 2) : 0.0
                end
                tempcFixStoChaFom +=
                    (ModelStorage == 1) ? round(value(MESS[:eHObjFixFomStoChaOS][s]); digits = 2) :
                    0.0

                tempcVarSto +=
                    (ModelStorage == 1) ?
                    round(
                        value(MESS[:eHObjVarStoChaOS][s]) + value(MESS[:eHObjVarStoDisOS][s]);
                        digits = 2,
                    ) : 0.0
            end
            tempcFixStoEne += (tempcFixStoEneInv + tempcFixStoEneFom)
            tempcFixStoDis += (tempcFixStoDisInv + tempcFixStoDisFom)
            tempcFixStoCha += (tempcFixStoChaInv + tempcFixStoChaFom)
            tempcFixSto += (tempcFixStoEne + tempcFixStoDis + tempcFixStoCha)

            tempcFixTruCompInv +=
                ((NetworkExpansion == 1) && (ModelTrucks == 1) && (Zones[z] in TRANSPORT_ZONES)) ?
                round(value(MESS[:eHObjFixInvTruCompOZ][Zones[z]]); digits = 2) : 0.0
            tempcFixTruCompFom +=
                ((ModelTrucks == 1) && (Zones[z] in TRANSPORT_ZONES)) ?
                round(value(MESS[:eHObjFixFomTruCompOZ][Zones[z]]); digits = 2) : 0.0
            tempcFixTruComp += (tempcFixTruCompInv + tempcFixTruCompFom)

            tempcVarNse += (AllowNse == 1) ? round(value(MESS[:eHObjVarNseOZ][z]); digits = 2) : 0.0
            tempcVarEmi +=
                in(4, CO2Policy) ? round(value(MESS[:eHObjVarEmissionOZ][z]); digits = 2) : 0.0

            ## Cost term for each zone
            tempcFix += (tempcFixGen + tempcFixSto + tempcFixTruComp)
            tempcVar += (tempcVarGen + tempcVarStart + tempcVarSto + tempcVarNse + tempcVarEmi)
            tempcFeedstock += round(value(MESS[:eHObjFeedStockOZ][z]); digits = 2)
            tempcCO2DiposalTransport +=
                hydrogen_settings["CO2Disposal"] == 1 ?
                round(value(MESS[:eHObjCO2DisposalTransportOZ][z]); digits = 2) : 0.0

            tempcCO2DiposalStorage +=
                hydrogen_settings["CO2Disposal"] == 1 ?
                round(value(MESS[:eHObjCO2DisposalStorageOZ][z]); digits = 2) : 0.0

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
