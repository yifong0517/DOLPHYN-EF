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
function generate_from_source(settings::Dict, inputs::Dict, OPTIMIZER::MOI.OptimizerWithAttributes)

    print_and_log(settings, "i", "Generating Macro Energy Synthesis System Model from Source")

    Z = inputs["Z"]
    T = inputs["T"]

    ## Create MESS model instance
    if inputs["LinearModel"] == 1 && settings["DirectModel"] == 1
        print_and_log(settings, "w", "Using Direct Model in JuMP")
        MESS = direct_model(OPTIMIZER)
    else
        print_and_log(settings, "i", "Using Model in JuMP")
        MESS = Model(OPTIMIZER)
    end

    ## Initialize model objective function
    @expression(MESS, eObj, AffExpr(0))

    ## Initialize model emissions expression
    @expression(MESS, eEmissions[z in 1:Z, t in 1:T], AffExpr(0))

    ## Initialize model captured carbon expression
    @expression(MESS, eCapture[z in 1:Z, t in 1:T], AffExpr(0))

    ## Initialize model directly captured carbon expression
    @expression(MESS, eDCapture[z in 1:Z, t in 1:T], AffExpr(0))

    ## Initialize model basic consumption expressions
    MESS = consumption_in_base(settings, inputs, MESS)

    ##TODO: Add multi energy sectors - natural gas and heat supply
    ## Power sector model
    if settings["ModelPower"] == 1
        MESS = generate_power(settings, inputs, MESS)
    end

    ## Hydrogen sector model
    if settings["ModelHydrogen"] == 1
        MESS = generate_hydrogen(settings, inputs, MESS)
    end

    ## Carbon sector model
    if settings["ModelCarbon"] == 1
        MESS = generate_carbon(settings, inputs, MESS)
    end

    ## Synfuels sector model
    if settings["ModelSynfuels"] == 1
        MESS = generate_synfuels(settings, inputs, MESS)
    end

    ## Ammonia sector model
    if settings["ModelAmmonia"] == 1
        MESS = generate_ammonia(settings, inputs, MESS)
    end

    ## Foodstuff sector model
    if settings["ModelFoodstuff"] == 1
        MESS = generate_foodstuff(settings, inputs, MESS)
    end

    ## Bioenergy sector model
    if settings["ModelBioenergy"] == 1
        MESS = generate_bioenergy(settings, inputs, MESS)
    end

    ## Feedstock consumption costs
    MESS = consumption(settings, inputs, MESS)

    ## Feedstock consumption availability
    if settings["ResourceAvailability"] == 1
        MESS = availability(settings, inputs, MESS)
    end

    ## Captured carbon summary from point source
    MESS = capture_psc(settings, inputs, MESS)

    ## Captured carbon disposal policy
    if settings["ModelCarbon"] == 0 &&
       haskey(settings, "CO2Disposal") &&
       settings["CO2Disposal"] >= 1
        MESS = capture_disposal(settings, inputs, MESS)
    end

    ## Emission policy - maximum emission amount
    if in(1, settings["CO2Policy"])
        MESS = emission_cap(settings, inputs, MESS)
    end

    ## Additional demand for each sector
    MESS = demand_additional(settings, inputs, MESS)

    ## Create MESS model balance constraints
    MESS = model_balance(settings, inputs, MESS)

    ## Define model objective function
    @objective(MESS, Min, settings["ObjScale"] * MESS[:eObj])

    print_and_log(settings, "i", "Minimizing Objective with Scaling Factor $(settings["ObjScale"])")

    ## Print model to file
    if settings["ModelFile"] != ""
        path = joinpath(settings["SavePath"], settings["ModelFile"])
        write_to_file(MESS, path)
        print_and_log(settings, "i", "MESS Model Instance Saved to $path")
    end

    return MESS
end
