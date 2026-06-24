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
	hours_before(p::Int64, t::Int64, b::Union{Int64, UnitRange{Int64}})

Determines the time index ```b``` hours before index ```t``` in a landscape
starting from ```t=1``` which is separated into distinct periods of length ```p```.

For example, if p = 10,
1 hour before t=1 is t=10,
1 hour before t=10 is t=9,
1 hour before t=11 is t=20.

When ```b``` is a set of time indexes, to allow for example b=1:3 to return a
set of time indexes containing ```t-3, t-2, t-1```.
"""
function hours_before(p::Int64, t::Int64, b::Union{Int64, UnitRange{Int64}})
    period = div(t - 1, p)
    if typeof(b) == UnitRange{Int64}
        return period * p .+ mod1.(t .- sort(b, rev = true), p)
    elseif typeof(b) == Int64
        return period * p + mod1(t - b, p)
    end
end

@doc raw"""
	hours_before(p::Int64, t::UnitRange{Int64}, b::Int64 = 1)

Determines the time advance ```b``` hours before index set ```t``` in a landscape
which is separated into distinct periods of length ```p```.

For example, if p = 10,
1 hour before t=1:10 is [10,1,2,3,4,5,6,7,8,9],
2 hour before t=1:10 is [9,10,1,2,3,4,5,6,7,8],
1 hour before t=11:20 is [20,11,12,13,14,15,16,17,18,19].
"""
function hours_before(p::Int64, t::UnitRange{Int64}, b::Int64 = 1)
    period = div.(t .- 1, p)
    return period .* p .+ mod1.(t .- b, p)
end
