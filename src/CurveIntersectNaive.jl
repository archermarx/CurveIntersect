module CurveIntersectNaive
    include("LineIntersect.jl")
    include("CurveTools.jl")

    using .LineIntersect, .CurveTools
    export curveintersect_naive, runtests_naive

    function curveintersect_naive(curve1::Array{Float64, 2}, curve2::Array{Float64, 2})
    end
    function runtests_naive()
        npassed = 0
        ntests = 0
        println("\n================================")
        println("Running naive intersection tests: ")
        println("================================")
        println("Naive intersect test summary")
        println("------------------------------")
        println("$npassed out of $ntests passed\n")
        return npassed, ntests
    end
end
