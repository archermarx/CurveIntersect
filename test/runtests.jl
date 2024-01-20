#using Revise
using Test
using CurveIntersect

function testintersect(intersectfunc)

    # single intersection
    x = 0:0.01:1
    y1 = x.^2
    y2 = 1 .- x.^2

    curve1 = [x y1]
    curve2 = [x y2]

    expected_x = 1/sqrt(2)
    expected_y = 0.5

    intersects = intersectfunc(curve1, curve2)
    intersect_x = intersects[1,1]
    intersect_y = intersects[1,2]

    ind = findfirst(p -> p>expected_x, x)

    l1 = [x[ind-1] y1[ind-1]; x[ind] y1[ind]]
    l2 = [x[ind-1] y2[ind-1]; x[ind] y2[ind]]

    expintersect = CurveIntersect.lineintersect(l1, l2)

    dist_x = intersect_x - expected_x
    dist_y = intersect_y - expected_y
    dist = sqrt(dist_x^2 + dist_y^2)

    expdist_x = expintersect[1] - expected_x
    expdist_y = expintersect[2] - expected_y
    expdist = sqrt(expdist_x^2 + expdist_y^2)
    @test dist<=expdist

    # multiple intersects
    x2 = range(0, stop = 2*pi+eps(Float64), length=100)
    y3 = sin.(x2)
    y4 = cos.(x2)
    curve3 = [x2 y3]
    curve4 = [x2 y4]

    expected_x = [pi/4; 5*pi/4]
    expected_y = sin.(expected_x)

    intersects = intersectfunc(curve3, curve4)
    intersect_x = intersects[:,1]
    intersect_y = intersects[:,2]

    ind1 = findfirst(j -> j>expected_x[1], x2)
    ind2 = findfirst(j -> j>expected_x[2], x2)

    l31 = [x2[ind1-1] y3[ind1-1]; x2[ind1] y3[ind1]]
    l41 = [x2[ind1-1] y4[ind1-1]; x2[ind1] y4[ind1]]

    l32 = [x2[ind2-1] y3[ind2-1]; x2[ind2] y3[ind2]]
    l42 = [x2[ind2-1] y4[ind2-1]; x2[ind2] y4[ind2]]

    expintersect_1 = CurveIntersect.lineintersect(l31, l42)
    expintersect_2 = CurveIntersect.lineintersect(l32, l42)

    dist_x = intersect_x .- expected_x
    dist_y = intersect_y .- expected_y
    dist = sqrt.(dist_x.^2 .+ dist_y.^2)

    expdist_x1 = expintersect_1[1] - expected_x[1]
    expdist_y1 = expintersect_1[2] - expected_y[1]
    expdist_x2 = expintersect_2[1] - expected_x[2]
    expdist_y2 = expintersect_2[2] - expected_y[2]

    expdist = [sqrt(expdist_x1^2 + expdist_y1^2); sqrt(expdist_x2^2 + expdist_y2^2)];

    @test dist[1]<=expdist[1] && dist[2]<=expdist[2]

    # self-intersection test
    curve1 = [0.0 0.0; 1.0 1.0; 1.0 0.0; 0.0 1.0]
    expintersect = [0.5, 0.5]
    intersectpts = CurveIntersect.curveintersect(curve1, curve1)

    @test expintersect == intersectpts[1,:]
end

@testset "Line intersect tests" begin
    l1 = [-1.0 0.0; 1.0 0.0]
    l2 = [0.0 -1.0; 0.0 1.0]
    expected = [0.0 0.0]
    intersect1 = CurveIntersect.lineintersect(l1, l2)
    @test abs(sum(intersect1 .- expected)) < eps(Float64)

    intersect2 = CurveIntersect.lineintersect(l2, l1)
    @test abs(sum(intersect2 .- expected)) < eps(Float64)

    l3 = [-1.0 -1.0; 1.0 1.0]
    l4 = [-1.0 1.0;1.0 -1.0]
    intersect3 = CurveIntersect.lineintersect(l3, l4)
    @test abs(sum(intersect3 .- expected)) < eps(Float64)

    l5 = [0.0 0.0; 1.0 1.0]
    l6 = [0.0 -1.0; 1.0 0.0]
    intersect4 = CurveIntersect.lineintersect(l5, l6)
    @test isinf(intersect4[1]) && isinf(intersect4[2])
end

@testset "Heirarchical bounding box method tests" begin
    @testset "Box intersection tests" begin
        b1 = CurveIntersect.Box(0.5, 0.5, 0.5, 0.5)
        b2 = CurveIntersect.Box(1.0, 1.0, 0.5, 0.5)
        b3 = CurveIntersect.Box(-10.0, -10.0, 0.5, 0.5)
        @test CurveIntersect.boxintersect(b1, b2)
        @test CurveIntersect.boxintersect(b1, b3) == false

    end
    @testset "Bounding box tests" begin
        l1 = [0.0 0.0; 1.0 1.0]
        l2 = [1.0 1.0; 0.0 0.0]
        expected = CurveIntersect.Box(0.5, 0.5, 0.5, 0.5)
        result_1 = CurveIntersect.createboundingbox(l1)
        result_2 = CurveIntersect.createboundingbox(l2)
        @test expected == result_1
        @test expected == result_2
    end
    @testset "Bounding box heirarchy tests" begin
        curve = [-1.0 -1.0
                  0.0 0.0
                  1.0 1.0 ]
        box1 = CurveIntersect.Box(0.0, 0.0, 1.0, 1.0)
        subbox1 = CurveIntersect.Box(0.5, 0.5, 0.5, 0.5)
        subbox2 = CurveIntersect.Box(-0.5, -0.5, 0.5, 0.5)

        subheirarchy1 = CurveIntersect.BoxHeirarchy(subbox1, curve[2:3, :], CurveIntersect.BoxHeirarchy[])
        subheirarchy2 = CurveIntersect.BoxHeirarchy(subbox2, curve[1:2, :], CurveIntersect.BoxHeirarchy[])
        expected = CurveIntersect.BoxHeirarchy(box1, curve, [subheirarchy2, subheirarchy1])
        result = CurveIntersect.createboxheirarchy(curve)
        @test CurveIntersect.isboxheirarchyequal(expected, result)

        curve = [-1.0 -1.0
                  0.0 0.0
                  1.0 1.0
                  2.0 2.0]
        box2 = CurveIntersect.createboundingbox(curve)
        subbox3 = CurveIntersect.Box(1.5, 1.5, 0.5, 0.5)
        subheirarchy3 = CurveIntersect.BoxHeirarchy(subbox3, curve[3:end,:], CurveIntersect.BoxHeirarchy[])
        subbox4 = CurveIntersect.Box(1.0, 1.0, 1.0, 1.0)
        subheirarchy4 = CurveIntersect.BoxHeirarchy(subbox4, curve[2:end, :], [subheirarchy1, subheirarchy3])
        expected = CurveIntersect.BoxHeirarchy(box2, curve, [subheirarchy2, subheirarchy4])
        result = CurveIntersect.createboxheirarchy(curve)
        @test CurveIntersect.isboxheirarchyequal(expected, result)
    end
    @testset "Curve intersection tests" begin
        testintersect(curveintersect)
    end
end
