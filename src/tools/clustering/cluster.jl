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
function cluster(settings::Dict, inputs::Dict)

    ## Parse profiles dataframe from inputs
    profiles = merge_inputs(settings, inputs)

    ## Remove constant columns from profiles dataframe
    profiles = remove_const_cols(profiles, settings, true)

    ## Load time aggregation settings
    settings = load_time_aggregation_settings(settings)

    ## Clustering settings
    cluster_settings = settings["ClusterSettings"]
    TimestepsPerRepPeriod = cluster_settings["TimestepsPerRepPeriod"]
    WeightTotal = cluster_settings["WeightTotal"]

    MinPeriods = cluster_settings["MinPeriods"]
    MaxPeriods = cluster_settings["MaxPeriods"]

    Iterate = cluster_settings["IterativelyAddPeriods"]
    IterateMethod = cluster_settings["IterateMethod"]
    Threshold = cluster_settings["Threshold"]

    ScalingMethod = cluster_settings["ScalingMethod"]

    ## Normalize profiles dataframe before clustering
    profiles = normalize_profiles(profiles, settings)

    ## Stack profiles dataframe into features dataframe
    features = stack_profiles(profiles, settings)

    cluster_results = []

    # Iteratively add worst periods as extreme periods OR increment number of clusters k
    if (Iterate == 1)
        print_and_log(settings, "i", "Start Iteratively Adding Periods from $MinPeriods")
        cluster_settings["NClusters"] = MinPeriods
        settings["ClusterSettings"] = cluster_settings
        # Cluster once regardless of iteration decisions
        push!(cluster_results, cluster_features(features, settings, true))
        while (
            !check_condition(
                Threshold,
                last(cluster_results)[1],
                names(profiles)[2:end],
                ScalingMethod,
                TimestepsPerRepPeriod,
            )
        )
            if IterateMethod == "cluster"
                print_and_log(settings, "i", "Adding a New Cluster!")
                settings["ClusterSettings"]["NClusters"] += 1
                push!(cluster_results, cluster_features(features, settings, true))
                if settings["ClusterSettings"]["NClusters"] == MaxPeriods
                    print_and_log(settings, "i", "Reaching Maximum Periods. Aborting Iterating")
                    break
                end
            else
                print_and_log(
                    settings,
                    "e",
                    "Invalid IterateMethod $IterateMethod. Choose 'cluster' or 'extreme' (not implemented).",
                )
            end
        end
    else
        print_and_log(settings, "i", "Using $MaxPeriods Clusters in Time Aggregation")
        cluster_settings["NClusters"] = MaxPeriods
        settings["ClusterSettings"] = cluster_settings
        push!(cluster_results, cluster_features(features, settings, true))
    end

    ## Interpret Final Clustering Result
    A = last(cluster_results)[2]  ## Assignments
    W = last(cluster_results)[3]  ## Weights
    M = last(cluster_results)[4]  ## Centers or Medoids

    M = [parse(Int64, string(names(features)[i])) for i in M]

    ## Keep cluster version of weights stored as N, number of periods represented by RP
    N = W

    ## Rescale weights to total user-specified number of hours
    W = [float(w) / sum(W) * WeightTotal for w in W]

    ## Order representative periods chronologically
    ##   SORT A W M in conjunction, chronologically by M, before handling them elsewhere to be consistent
    ##   A points to an index of M. We need it to point to a new index of sorted M. Hence, AssignMap.
    old_M = M
    df_sort = DataFrame(Weights = W, NumPeriods = N, Rep_Period = M)
    sort!(df_sort, [:Rep_Period])
    W = df_sort[!, :Weights]
    N = df_sort[!, :NumPeriods]
    M = df_sort[!, :Rep_Period]
    AssignMap = Dict(i => findall(x -> x == old_M[i], M)[1] for i in eachindex(M))
    A = [AssignMap[a] for a in A]

    # Make PeriodMap, maps each period to its representative period
    PeriodMap = DataFrame(
        Period_Index = 1:length(A),
        Rep_Period = [M[a] for a in A],
        Rep_Period_Index = [a for a in A],
    )

    return PeriodMap
end
