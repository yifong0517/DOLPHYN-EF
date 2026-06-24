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
function write_carbon_costs(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 2
        carbon_settings = settings["CarbonSettings"]
        path = carbon_settings["SavePath"]

        ## Model flags
        ModelDAC = carbon_settings["ModelDAC"]
        IncludeExistingCap = carbon_settings["IncludeExistingCap"]

        SimpleTransport = carbon_settings["SimpleTransport"]
        NetworkExpansion = carbon_settings["NetworkExpansion"]
        IncludeExistingNetwork = carbon_settings["IncludeExistingNetwork"]
        ModelPipelines = carbon_settings["ModelPipelines"]
        ModelTrucks = carbon_settings["ModelTrucks"]

        ModelStorage = carbon_settings["ModelStorage"]
        IncludeExistingSto = carbon_settings["IncludeExistingSto"]
        AllowDis = carbon_settings["AllowDis"]

        AllowNse = carbon_settings["AllowNse"]
        CO2Policy = carbon_settings["CO2Policy"]

        ## Basic zonal and temporal resolution of the model
        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]

        carbon_inputs = inputs["CarbonInputs"]

        ## Generation related inputs
        if ModelDAC == 1
            G = carbon_inputs["G"]
            NEW_CAPTURE_CAP = carbon_inputs["NEW_CAPTURE_CAP"]
            dfGen = carbon_inputs["dfGen"]
            COMMIT = carbon_inputs["COMMIT"]
        end

        ## Storage related inputs
        if ModelStorage == 1
            S = carbon_inputs["S"]
            NEW_STO_CAP = carbon_inputs["NEW_STO_CAP"]
            dfSto = carbon_inputs["dfSto"]
        end

        if ModelTrucks == 1
            TRUCK_TYPES = carbon_inputs["TRUCK_TYPES"]
            TRANSPORT_ZONES = carbon_inputs["TRANSPORT_ZONES"]
        end

        if AllowNse == 1
            SEG = carbon_inputs["SEG"]
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
            ],
        )

        ## Investment and fixed maintainance costs of generation
        cFixGenInv = (ModelDAC == 1) ? round(value(MESS[:eCObjFixInvCap]); digits = 2) : 0.0
        if IncludeExistingCap > 0
            cFixSunkGenInv =
                (ModelDAC == 1) ? round(value(MESS[:eCObjFixSunkInvCap]); digits = 2) : 0.0
            cFixGenInv += cFixSunkGenInv
        end
        cFixGenFom = (ModelDAC == 1) ? round(value(MESS[:eCObjFixFomCap]); digits = 2) : 0.0
        cFixGen = cFixGenInv + cFixGenFom

        ## Investment and fixed maintainance costs of storage energy
        cFixStoEneInv =
            (ModelStorage == 1) ? round(value(MESS[:eCObjFixInvStoEne]); digits = 2) : 0.0
        if ModelStorage == 1
            cFixSunkStoEneInv =
                (IncludeExistingSto == 1) ? round(value(MESS[:eCObjFixSunkInvStoEne]); digits = 2) :
                0.0
            cFixStoEneInv += cFixSunkStoEneInv
        end
        cFixStoEneFom =
            (ModelStorage == 1) ? round(value(MESS[:eCObjFixFomStoEne]); digits = 2) : 0.0
        cFixStoEne = cFixStoEneInv + cFixStoEneFom

        ## Investment and fixed maintainance costs of storage discharge
        cFixStoDisInv =
            ((ModelStorage == 1) && (AllowDis == 1)) ?
            round(value(MESS[:eCObjFixInvStoDis]); digits = 2) : 0.0
        if ModelStorage == 1
            cFixSunkStoDisInv =
                ((IncludeExistingSto == 1) && (AllowDis == 1)) ?
                round(value(MESS[:eCObjFixSunkInvStoDis]); digits = 2) : 0.0
            cFixStoDisInv += cFixSunkStoDisInv
        end
        cFixStoDisFom =
            ((ModelStorage == 1) && (AllowDis == 1)) ?
            round(value(MESS[:eCObjFixFomStoDis]); digits = 2) : 0.0
        cFixStoDis = cFixStoDisInv + cFixStoDisFom

        ## Investment and fixed maintainance costs of storage charge
        cFixStoChaInv =
            (ModelStorage == 1) ? round(value(MESS[:eCObjFixInvStoCha]); digits = 2) : 0.0
        if IncludeExistingSto == 1
            cFixSunkStoChaInv =
                (IncludeExistingSto == 1) ? round(value(MESS[:eCObjFixSunkInvStoCha]); digits = 2) :
                0.0
            cFixStoChaInv += cFixSunkStoChaInv
        end
        cFixStoChaFom =
            (ModelStorage == 1) ? round(value(MESS[:eCObjFixFomStoCha]); digits = 2) : 0.0
        cFixStoCha = cFixStoChaInv + cFixStoChaFom

        ## Fixed costs of storage = costs of energy + costs of discharge + costs of charge (if any)
        cFixSto = cFixStoEne + cFixStoDis + cFixStoCha

        ## Investment costs of trucks
        cFixTruInv =
            ((NetworkExpansion == 1) && (ModelTrucks == 1)) ?
            round(value(MESS[:eCObjFixInvTru]); digits = 2) : 0.0
        cFixTru = cFixTruInv

        ## Investment and maintainance costs of truck compression
        cFixTruCompInv =
            ((NetworkExpansion == 1) && (ModelTrucks == 1)) ?
            round(value(MESS[:eCObjFixInvTruComp]); digits = 2) : 0.0
        cFixTruCompFom = (ModelTrucks == 1) ? value(MESS[:eCObjFixFomTruComp]) : 0.0
        cFixTruComp = cFixTruCompInv + cFixTruCompFom

        ## Fixed costs = costs of generation + costs of storage + costs of trucks + costs of trucks compression
        cFix = cFixGen + cFixSto + cFixTru + cFixTruComp

        ## Variable costs
        cVarGen = (ModelDAC == 1) ? round(value(MESS[:eCObjVarCap]); digits = 2) : 0.0
        cVarStart =
            ((ModelDAC == 1) && !isempty(COMMIT)) ? round(value(MESS[:eCObjVarStart]); digits = 2) :
            0.0
        cVarSto =
            ((ModelStorage == 1) && (AllowDis == 1)) ?
            round(value(MESS[:eCObjVarStoDis]) + value(MESS[:eCObjVarStoCha]); digits = 2) : 0.0
        cVarNse = (AllowNse == 1) ? round(value(MESS[:eCObjVarNse]); digits = 2) : 0.0
        cVarEmi = in(4, CO2Policy) ? round(value(MESS[:eCObjVarEmission]); digits = 2) : 0.0
        cVarTru = (ModelTrucks == 1) ? round(value(MESS[:eCObjVarTru]); digits = 2) : 0.0
        cVarTruComp = (ModelTrucks == 1) ? round(value(MESS[:eCObjVarTruComp]); digits = 2) : 0.0
        cVarTransport =
            (SimpleTransport == 1) ? round(value(MESS[:eCObjTransportCosts]); digits = 2) : 0.0

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
            (ModelPipelines == 1) ? round(value(MESS[:eCObjNetworkExpansion]); digits = 2) : 0.0
        if (ModelPipelines == 1)
            cNetworkExisting =
                IncludeExistingNetwork == 1 ?
                round(value(MESS[:eCObjNetworkExisting]); digits = 2) : 0.0
            cNetworkExpansion += cNetworkExisting
        end
        ## Pipeline compression costs
        cNetworkComp =
            (ModelPipelines == 1) ? round(value(MESS[:eCObjFixPipeComp]); digits = 2) : 0.0

        ## Feedstock expenses
        cFeedstock = round(value(MESS[:eCObjFeedStock]); digits = 2)

        ## Total cost = fixed costs + variable costs + network expansion costs + feedstock costs
        cTotal = cFix + cVar + cNetworkExpansion + cNetworkComp + cFeedstock

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

            if ModelDAC == 1
                for g in dfGen[dfGen.Zone .== Zones[z], :R_ID]
                    tempcFixGenInv +=
                        g in NEW_CAPTURE_CAP ?
                        round(value(MESS[:eCObjFixInvCapOG][g]); digits = 2) : 0.0
                    if IncludeExistingCap > 0
                        tempcFixGenInv += round(value(MESS[:eCObjFixSunkInvCapOG][g]); digits = 2)
                    end
                    tempcFixGenFom += round(value(MESS[:eCObjFixFomCapOG][g]); digits = 2)

                    tempcVarGen += round(value(MESS[:eCObjVarCapOG][g]); digits = 2)
                    tempcVarStart +=
                        g in COMMIT ? round(value(MESS[:eCObjVarStartOG][g]); digits = 2) : 0.0
                end
                tempcFixGen += (tempcFixGenInv + tempcFixGenFom)
            end

            if ModelStorage == 1
                for s in dfSto[dfSto.Zone .== Zones[z], :R_ID]
                    tempcFixStoEneInv +=
                        (s in NEW_STO_CAP) ?
                        round(value(MESS[:eCObjFixInvStoEneOS][s]); digits = 2) : 0.0
                    if IncludeExistingSto == 1
                        tempcFixStoEneInv +=
                            round(value(MESS[:eCObjFixSunkInvStoEneOS][s]); digits = 2)
                    end
                    tempcFixStoEneFom += round(value(MESS[:eCObjFixFomStoEneOS][s]); digits = 2)

                    tempcFixStoDisInv +=
                        (AllowDis == 1 && s in NEW_STO_CAP) ?
                        round(value(MESS[:eCObjFixInvStoDisOS][s]); digits = 2) : 0.0
                    if IncludeExistingSto == 1
                        tempcFixStoDisInv +=
                            AllowDis == 1 ?
                            round(value(MESS[:eCObjFixSunkInvStoDisOS][s]); digits = 2) : 0.0
                    end
                    tempcFixStoDisFom +=
                        AllowDis == 1 ? round(value(MESS[:eCObjFixFomStoDisOS][s]); digits = 2) :
                        0.0

                    tempcFixStoChaInv +=
                        (s in NEW_STO_CAP) ?
                        round(value(MESS[:eCObjFixInvStoChaOS][s]); digits = 2) : 0.0
                    if IncludeExistingSto == 1
                        tempcFixStoChaInv +=
                            round(value(MESS[:eCObjFixSunkInvStoChaOS][s]); digits = 2)
                    end
                    tempcFixStoChaFom += round(value(MESS[:eCObjFixFomStoChaOS][s]); digits = 2)

                    tempcVarSto +=
                        (AllowDis == 1) ? round(value(MESS[:eCObjVarStoDisOS][s]); digits = 2) :
                        0.0 + round(value(MESS[:eCObjVarStoChaOS][s]); digits = 2)
                end
                tempcFixStoEne += (tempcFixStoEneInv + tempcFixStoEneFom)
                tempcFixStoDis += (tempcFixStoDisInv + tempcFixStoDisFom)
                tempcFixStoCha += (tempcFixStoChaInv + tempcFixStoChaFom)
                tempcFixSto += (tempcFixStoEne + tempcFixStoDis + tempcFixStoCha)
            end

            if (ModelTrucks == 1)
                if (NetworkExpansion == 1)
                    tempcFixTruCompInv +=
                        (Zones[z] in TRANSPORT_ZONES) ?
                        round(value(MESS[:eCObjFixInvTruCompOZ][Zones[z]]); digits = 2) : 0.0
                end
                tempcFixTruCompFom +=
                    (Zones[z] in TRANSPORT_ZONES) ?
                    round(value(MESS[:eCObjFixFomTruCompOZ][Zones[z]]); digits = 2) : 0.0
                tempcFixTruComp += (tempcFixTruCompInv + tempcFixTruCompFom)
            end

            tempcVarNse += (AllowNse == 1) ? round(value(MESS[:eCObjVarNseOZ][z]); digits = 2) : 0.0
            tempcVarEmi +=
                in(4, CO2Policy) ? round(value(MESS[:eCObjVarEmissionOZ][z]); digits = 2) : 0.0

            ## Cost term for each zone
            tempcFix += (tempcFixGen + tempcFixSto + tempcFixTruComp)
            tempcVar += (tempcVarGen + tempcVarStart + tempcVarSto + tempcVarNse + tempcVarEmi)
            tempcFeedstock += round(value(MESS[:eCObjFeedStockOZ][z]); digits = 2)

            tempcTotal += tempcFix + tempcVar + tempcFeedstock
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
            ]
        end

        ## CSV writing
        CSV.write(joinpath(path, "costs.csv"), df)
    end
end
