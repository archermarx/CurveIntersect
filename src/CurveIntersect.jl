module CurveIntersect
    include("LineIntersect.jl")
    include("CurveTools.jl")
    include("CurveIntersectNaive.jl")
    include("CurveIntersectHB.jl")
    include("CurveIntersectSweepline.jl")

    using Plots
    using .LineIntersect: runtests_line
    using .CurveIntersectNaive: curveintersect_naive, runtests_naive
    using .CurveIntersectHB: curveintersect_hb, runtests_hb
    using .CurveIntersectSweepline: curveintersect_sweepline, runtests_sweepline

    export runtests, curveintersect, getintersectpoints

    function curveintersect(args, verbose::Bool=false, method::String="none")
        println("You are using the most up-to-date version of this code")

        if lowercase(method) ==  "none"
            verbose ? println("No algorithm selected. Choosing default...") : 0
            method = "hbb"
        end
        if lowercase(method) == "naive"
            verbose ? println("Naive (O(n²)) method selected.") : 0
            return curveintersect_naive(args...)

        elseif lowercase(method) == "hbb"
            verbose ? println("Heirarchical bounding box method selected.") : 0
            return curveintersect_hb(args...)

        elseif lowercase(method) == "sweepline"
            verbose ? println("Sweepline method selected.") : 0
            return curveintersect_sweepline(args...)

        else
            error("Invalid curve intersection algorithm. Select \"naive\", \"hbb\", or \"sweepline\"")
        end
    end

    function getintersectpoints(intersectgrid)
        xpts = Float64[]
        ypts = Float64[]

        for i in eachindex(intersectgrid)
            if !isempty(intersectgrid[i])
                append!(xpts, intersectgrid[i][:,1])
                append!(ypts, intersectgrid[i][:,2])
            end
        end

        return [xpts ypts]
    end

    function runtests()
        npassed = 0; ntests = 0;
        println("Running curve intersection tests...\n")

        np, nt = runtests_line()
        npassed += np
        ntests += nt

        np,nt = runtests_naive()
        npassed += np
        ntests += nt

        np, nt = runtests_hb()
        npassed += np
        ntests += nt

        np, nt = runtests_sweepline()
        npassed += np
        ntests += nt

        println("Curve intersection test summary")
        println("------------------------------")
        println("$npassed out of $ntests passed")
    end
end
