module LineIntersect
    export lineintersect, runtests_line

    # finds the intesection point of two line segments
    # the first line segment is defined by points p11 and p12
    # the second is defined by p21 and p22

    function lineintersect(l1::Array{Float64, 2}, l2::Array{Float64, 2})
        p1x = l1[1,1]; p1y = l1[1,2]
        p2x = l1[2,1]; p2y = l1[2,2]
        p3x = l2[1,1]; p3y = l2[1,2]
        p4x = l2[2,1]; p4y = l2[2,2]

        s1x = p2x - p1x; s1y = p2y-p1y
        s2x = p4x - p3x; s2y = p4y-p3y

        δ = -s2x*s1y + s1x*s2y

        if δ == 0
            return [Inf64 Inf64]
        end

        s = (-s1y*(p1x - p3x) + s1x*(p1y - p3y))/δ
        t = (s2x*(p1y - p3y) - s2y*(p1x - p3x))/δ

        if s>=0 && s<=1 && t>=0 && t<=1
            ix = p1x + (t * s1x)
            iy = p1y + (t * s1y)
            return [ix iy]
        else
            return [Inf64 Inf64]
        end
    end

    function testlineintersect()
        println("Line intersection tests: ")
        npassed = 0
        ntests = 0

        l1 = [-1.0 0.0; 1.0 0.0]
        l2 = [0.0 -1.0; 0.0 1.0]

        expected = [0.0 0.0]

        println("Test 1: First line vertical")
        ntests+=1
        intersect1 = lineintersect(l1, l2)
        if abs(sum(intersect1 .- expected)) < eps(Float64)
            npassed+=1
            println("\tTest 1 passed")
        else
            println("\tTest 1 failed")
            println("\t\texpected = $expected")
            println("\t\tintersect = $intersect1")
        end

        println("Test 2: Second line vertical")
        ntests+=1
        intersect2 = lineintersect(l2, l1)
        if abs(sum(intersect2 .- expected)) < eps(Float64)
            npassed+=1
            println("\tTest 2 passed")
        else
            println("\tTest 2 failed")
            println("\t\texpected = $expected")
            println("\t\tintersect = $intersect2")
        end

        l3 = [-1.0 -1.0; 1.0 1.0]
        l4 = [-1.0 1.0;1.0 -1.0]

        println("Test 3: Two non-vertical lines")
        ntests+=1
        intersect3 = lineintersect(l3, l4)
        if abs(sum(intersect3 .- expected)) < eps(Float64)
            npassed+=1
            println("\tTest 3 passed")
        else
            println("\tTest 3 failed")
            println("\t\texpected = $expected")
            println("\t\tintersect = $intersect3")
        end

        l5 = [0.0 0.0; 1.0 1.0]
        l6 = [0.0 -1.0; 1.0 0.0]

        println("Test 4: Two lines of same slope")
        ntests+=1
        intersect4 = lineintersect(l5, l6)
        if isinf(intersect4[1]) && isinf(intersect4[2])
            npassed+=1
            println("\tTest 4 passed\n")
        else
            println("\tTest 4 failed")
            println("\t\texpected = $expected")
            println("\t\tintersect = $intersect4")
            println("")
        end

        return npassed, ntests
    end

    function runtests_line()
        println("Running line intersection tests...")
        npassed = 0
        ntests = 0
        np, nt = testlineintersect()
        npassed += np
        ntests += nt

        println("Line intersection test summary")
        println("------------------------------")
        println("$npassed out of $ntests passed\n")
        return npassed, ntests
    end
end
