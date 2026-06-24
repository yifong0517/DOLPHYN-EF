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
function write_power_balance_shadow_price(settings::Dict, inputs::Dict, MESS::Model)

    if settings["WriteLevel"] >= 3
        power_settings = settings["PowerSettings"]
        path = power_settings["SavePath"]

        Z = inputs["Z"]
        Zones = inputs["Zones"]

        T = inputs["T"]
        Time_Index = inputs["Time_Index"]
        weights = inputs["weights"]
        tsymbols = [Symbol("$t") for t in 1:T]

        ## Shadow price dataframe
        ## Electricity price: Dual variable of hourly power balance constraint = hourly price in $/MWh
        dfPrice = DataFrame(Zone = Zones)

        dfPrice = hcat(
            dfPrice,
            DataFrame(round.(dual.(MESS[:cPBalance]) ./ transpose(weights); digits = 2), :auto),
        )

        auxNew_Names = [Symbol("Zone (\$/MWh)"); tsymbols]
        rename!(dfPrice, auxNew_Names)

        ## CSV writing
        CSV.write(
            joinpath(path, "power_balance_shadow_prices.csv"),
            permutedims(dfPrice, "Zone (\$/MWh)"),
        )
    end
end
