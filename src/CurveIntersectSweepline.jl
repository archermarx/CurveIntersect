module CurveIntersectSweepline
    include("LineIntersect.jl")
    include("CurveTools.jl")

    using .LineIntersect, .CurveTools
    export curveintersect_sweepline, runtests_sweepline

    function curveintersect_sweepline(curve1::Array{Float64, 2}, curve2::Array{Float64, 2})
    end

    function runtests_sweepline()
        npassed = 0
        ntests = 0
        println("\n================================")
        println("Running sweepline intersection tests: ")
        println("================================")

        println("Sweepline intersect test summary")
        println("------------------------------")
        println("$npassed out of $ntests passed\n")
        return npassed, ntests
    end
end
