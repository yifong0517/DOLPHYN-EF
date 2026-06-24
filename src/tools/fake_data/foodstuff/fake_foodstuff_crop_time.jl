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
function fake_foodstuff_crop_time(
    path::AbstractString,
    zones::Integer,
    time_length::Integer,
    CropType::AbstractVector{String},
)

    ## Generate zone list
    Zones = string.(1:zones)

    ## Crop time dataframe
    ## Create time index
    dfCropTime = DataFrame(Time_Index = 1:time_length)

    ## Create crop type identifier as columns
    dfCropTime = hcat(
        dfCropTime,
        DataFrame(
            [
                i = [
                    repeat([0], rand(2190:2400))
                    repeat([1], rand(2190:2400))
                    repeat([2], rand(2190:2400))
                    repeat([3], rand(2190:2400))
                ][1:8760] for i in ["$(z)_$(c)" for z in Zones for c in CropType]
            ],
            :auto,
        ),
    )
    rename!(dfCropTime, vcat(["Time_Index"], ["$(z)_$(c)" for z in Zones for c in CropType]))

    CSV.write(joinpath(path, "Crop_Time.csv"), dfCropTime)
end
