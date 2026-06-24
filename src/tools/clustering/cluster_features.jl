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
    cluster_features(features::DataFrame, cluster_settings::Dict, v::Bool=false)

Get representative periods using cluster centers from kmeans or kmedoids.

K-Means:
https://juliastats.org/Clustering.jl/dev/kmeans.html

K-Medoids:
 https://juliastats.org/Clustering.jl/stable/kmedoids.html
"""
function cluster_features(features::DataFrame, settings::Dict, v::Bool = false)

    cluster_settings = settings["ClusterSettings"]

    ## Get clustering settings from dictionary
    ClusterMethod = cluster_settings["ClusterMethod"]
    NClusters = cluster_settings["NClusters"]
    nIters = cluster_settings["nIters"]

    ## Use kmeans clustering method
    if ClusterMethod == "kmeans"
        DistMatrix = pairwise(Euclidean(), Matrix(features), dims = 2)
        R = kmeans(Matrix(features), NClusters, init = :kmcen)

        for i in 1:nIters
            R_i = kmeans(Matrix(features), NClusters)

            if R_i.totalcost < R.totalcost
                R = R_i
            end
            if v && (i % (nIters / 10) == 0)
                print_and_log(
                    settings,
                    "i",
                    "$i : $(round(R_i.totalcost, digits=3)) $(round(R.totalcost, digits=3))",
                )
            end
        end

        A = R.assignments ## Get points to clusters mapping - A for Assignments
        W = R.counts ## Get the cluster sizes - W for Weights
        Centers = R.centers ## Get the cluster centers - M for Medoids

        M = []
        for i in 1:NClusters
            dists = [euclidean(Centers[:, i], features[!, j]) for j in names(features)]
            push!(M, argmin(dists))
        end
        ## Use kmedoids method to cluster
    elseif ClusterMethod == "kmedoids"
        DistMatrix = pairwise(Euclidean(), Matrix(features), dims = 2)
        R = kmedoids(DistMatrix, NClusters, init = :kmcen)

        for i in 1:nIters
            R_i = kmedoids(DistMatrix, NClusters)
            if R_i.totalcost < R.totalcost
                R = R_i
            end
            if v && (i % (nIters / 10) == 0)
                print_and_log(
                    settings,
                    "i",
                    "$i : $(round(R_i.totalcost, digits=3)) $(round(R.totalcost, digits=3))",
                )
            end
        end

        A = R.assignments # get points to clusters mapping - A for Assignments
        W = R.counts # get the cluster sizes - W for Weights
        M = R.medoids # get the cluster centers - M for Medoids
    else
        print_and_log(
            settings,
            "i",
            "Invalid ClusterMethod. Select Kmeans or Kmedoids. Running Kmeans Instead.",
        )
        cluster_settings["ClusterMethod"] = "kmeans"
        return cluster(features, cluster_settings)
    end

    return [R, A, W, M, DistMatrix]
end
