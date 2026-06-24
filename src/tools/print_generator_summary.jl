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
function print_generator_summary(sector_settings::Dict, sector_inputs::Dict)

    G = sector_inputs["G"]
    dfGen = sector_inputs["dfGen"]
    Zones = sector_inputs["Zones"]
    GenResourceType = sector_inputs["GenResourceType"]

    print_and_log(
        sector_settings,
        "i",
        "Total Modeled Generators: $G. Types Include $GenResourceType",
    )

    zone_summary = countmap(dfGen[!, :Zone])
    zone_info =
        "Zonal Generator Resources Distribution:\n" *
        join(["Zone $z: $(zone_summary[z])\n" for z in Zones])
    print_and_log(sector_settings, "i", zone_info)

    resource_type_summary = sort(countmap(dfGen[!, :Resource_Type]))
    resource_type_info =
        "Generator Resources Distribution:\n" *
        join(["Resource Type $type: $value\n" for (type, value) in resource_type_summary])

    print_and_log(sector_settings, "i", resource_type_info)
end
