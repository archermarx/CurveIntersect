module CurveTools
    include("LineIntersect.jl")

    using .LineIntersect, Plots

    export testintersect, plotcurveintersects

    function plotcurveintersects(curve1, curve2, intersectfunc, lb = "Computed")
        intersects = intersectfunc(curve1, curve2)

        p = plot(curve1[:,1], curve1[:,2], label="")
        plot!(curve2[:,1], curve2[:,2], label="")

        scatter!(intersects[:,1], intersects[:,2], label=lb, markersize=6)
        nintersects = size(intersects,1)
        #println("nintersects = $nintersects")

        return intersects, p
    end

    function testintersect(intersectfunc)
        npassed = 0
        ntests = 0
        println("Curve intersection tests: ")

        x = 0:0.01:1
        y1 = x.^2
        y2 = 1 .- x.^2

        curve1 = [x y1]
        curve2 = [x y2]

        expected_x = 1/sqrt(2)
        expected_y = 0.5
        expected = [expected_x expected_y]

        intersects, p = plotcurveintersects(curve1, curve2, intersectfunc)
        intersect_x = intersects[1,1]
        intersect_y = intersects[1,2]
        scatter!([expected_x], [expected_y], markersize=3, label="Expected")
        display(p)

        ind = findfirst(p -> p>expected_x, x)

        l1 = [x[ind-1] y1[ind-1]; x[ind] y1[ind]]
        l2 = [x[ind-1] y2[ind-1]; x[ind] y2[ind]]

        expintersect = lineintersect(l1, l2)

        dist_x = intersect_x - expected_x
        dist_y = intersect_y - expected_y
        dist = sqrt(dist_x^2 + dist_y^2)

        expdist_x = expintersect[1] - expected_x
        expdist_y = expintersect[2] - expected_y
        expdist = sqrt(expdist_x^2 + expdist_y^2)

        println("Test 1: Curves intersect once")
        ntests +=1
        if dist<=expdist
            println("\t Test 1 passed")
            npassed+=1
        else
            println("\tTest 1 failed")
            println("\t\texpected = $expected")
            println("\t\texpected intersect = $expintersect")
            println("\t\tintersect = $intersect")
        end

        println("Test 2: Curves intersect more than once")
        ntests +=1

        x2 = range(0, stop = 2*pi+eps(Float64), length=100)
        y3 = sin.(x2)
        y4 = cos.(x2)
        curve3 = [x2 y3]
        curve4 = [x2 y4]

        expected_x = [pi/4; 5*pi/4]
        expected_y = sin.(expected_x)

        intersects, p = plotcurveintersects(curve3, curve4, intersectfunc)
        intersect_x = intersects[:,1]
        intersect_y = intersects[:,2]

        ind1 = findfirst(j -> j>expected_x[1], x2)
        ind2 = findfirst(j -> j>expected_x[2], x2)

        l31 = [x2[ind1-1] y3[ind1-1]; x2[ind1] y3[ind1]]
        l41 = [x2[ind1-1] y4[ind1-1]; x2[ind1] y4[ind1]]

        l32 = [x2[ind2-1] y3[ind2-1]; x2[ind2] y3[ind2]]
        l42 = [x2[ind2-1] y4[ind2-1]; x2[ind2] y4[ind2]]

        expintersect_1 = lineintersect(l31, l42)
        expintersect_2 = lineintersect(l32, l42)

        dist_x = intersect_x .- expected_x
        dist_y = intersect_y .- expected_y
        dist = sqrt.(dist_x.^2 .+ dist_y.^2)

        expdist_x1 = expintersect_1[1] - expected_x[1]
        expdist_y1 = expintersect_1[2] - expected_y[1]
        expdist_x2 = expintersect_2[1] - expected_x[2]
        expdist_y2 = expintersect_2[2] - expected_y[2]

        expdist = [sqrt(expdist_x1^2 + expdist_y1^2); sqrt(expdist_x2^2 + expdist_y2^2)];

        scatter!(expected_x, expected_y, markersize=3, label="Expected")
        display(p)

        if dist[1]<=expdist[1] && dist[2]<=expdist[2]
            println("\t Test 2 passed")
            npassed+=1
        else
            println("\tTest 2 failed")
            println("\t\texpected = $expected")
            println("\t\texpected intersect = $expintersect")
            println("\t\tintersect = $intersect")
        end
        println()
        return npassed, ntests
    end
end
