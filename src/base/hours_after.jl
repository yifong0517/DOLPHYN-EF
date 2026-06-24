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
    hours_after(p::Int64, t::Int64, a::Union{Int64, UnitRange{Int64}})

Determines the time index ```a``` hours after index ```t``` in a landscape
starting from ```t=1``` which is separated into distinct periods of length ```p```.

For example, if p = 10,
1 hour after t=9 is t=10,
1 hour after t=10 is t=1,
1 hour after t=11 is t=12.

When ```a``` is a set of time indexes, to allow for example a=1:3 to return a
set of time indexes containing ```t+1, t+2, t+3```.
"""
function hours_after(p::Int64, t::Int64, a::Union{Int64, UnitRange{Int64}})
    period = div(t - 1, p)
    if typeof(a) == UnitRange{Int64}
        return period * p .+ mod1.(t .+ a, p)
    elseif typeof(a) == Int64
        return period * p + mod1(t + a, p)
    end
end

@doc raw"""
    hours_after(p::Int64, t::UnitRange{Int64}, a::Int64 = 1)

Determines the time delay ```a``` hours after index set ```t``` in a landscape
which is separated into distinct periods of length ```p```.

For example, if p = 10,
1 hour after t=1:10 is [2,3,4,5,6,7,8,9,10,1],
2 hour after t=1:10 is [3,4,5,6,7,8,9,10,1,2],
1 hour after t=11:20 is [12,13,14,15,16,17,18,19,20,11].
"""
function hours_after(p::Int64, t::UnitRange{Int64}, a::Int64 = 1)
    period = div.(t .- 1, p)
    return period .* p .+ mod1.(t .+ a, p)
end
