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

module Geo

export haversine
export baidu_route_distance
export bing_route_distance
export subzone

### Data structures
using DataFrames
using DataFramesMeta
using DataFrameMacros

### Revision
using Revise

## Geographic distance calculation
include("haversine.jl")

## Map API - Baidu Map API
include("api/baidu_map/baidu_map_api_key.jl")
include("api/baidu_map/baidu_route_distance.jl")

## Map API - Bing Map API
include("api/bing_map/bing_map_api_key.jl")
include("api/bing_map/bing_route_distance.jl")

## Subzone identification
include("subzone.jl")

end # module Geo
