module CurveIntersect
    include("LineIntersect.jl")
    include("CurveTools.jl")
    include("CurveIntersectNaive.jl")
    include("CurveIntersectHB.jl")
    include("CurveIntersectSweepline.jl")

    using .LineIntersect: runtests_line
    using .CurveIntersectNaive: curveintersect_naive, runtests_naive
    using .CurveIntersectHB: curveintersect_hb, runtests_hb
    using .CurveIntersectSweepline: curveintersect_sweepline, runtests_sweepline

    export runtests, curveintersect

    function curveintersect(curve1::Array{Float64, 2}, curve2::Array{Float64, 2}, method="hbb")
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

using .CurveIntersect

CurveIntersect.runtests()
