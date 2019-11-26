module CurveIntersectHB
    using Plots
    include("LineIntersect.jl")
    include("CurveTools.jl")

    using .LineIntersect, .CurveTools
    export curveintersect_hb, runtests_hb

    # A box is defined by the x and y locations of the center
    # as well as the half width and half height.
    # The half-dimensions are stored to slightly improve performance
    struct Box
        x::Float64
        y::Float64
        halfwidth::Float64
        halfheight::Float64
    end

    # A box heirarchy contains a box and an array of sub-box heirarchies
    struct BoxHeirarchy
        box::Box
        curve::Array{Float64, 2}
        subboxes::Array{BoxHeirarchy, 1}
    end

    # checks if two box heirarchies are equal to eachother because julia is
    # kind of silly some times and the == operator won't do this for me.
    # recursively checks the equality of all Box objects within bh1 and bh2
    function isboxheirarchyequal(bh1::BoxHeirarchy, bh2::BoxHeirarchy)
        if bh1.box == bh2.box && bh1.curve == bh2.curve
            if isempty(bh1.subboxes) || isempty(bh2.subboxes)
                if isempty(bh1.subboxes) && isempty(bh2.subboxes)
                    return true
                else
                    return false
                end
            else
                equal1 = isboxheirarchyequal(bh1.subboxes[1], bh2.subboxes[1])
                equal2 = isboxheirarchyequal(bh1.subboxes[2], bh2.subboxes[2])
                equal3 = isboxheirarchyequal(bh1.subboxes[1], bh2.subboxes[2])
                equal4 = isboxheirarchyequal(bh1.subboxes[2], bh1.subboxes[1])
                return (equal1 && equal2) || (equal3 && equal4)
            end
        else
            return false
        end
    end


#using .MyTypes: Box, BoxHeirarchy, isboxheirarchyequal #hide


#draws a box object on the screen
function drawbox(box, lw = 0.5, lc=:black, fa = 0.0, fc = lc)
    rect(x, y, hw, hh) = Shape(x .+ [-hw,hw,hw,-hw], y .+ [-hh,-hh,hh,hh])
    plot!(rect(box.x, box.y, box.halfwidth, box.halfheight),
            linewidth = lw, linecolor = lc, fillalpha = fa, fillcolor = fc,
            label="")
end

#draws a bounding box heirarchy
function drawboxheirarchy(bheirarchy::BoxHeirarchy, lw = 2, lc = :black)
    drawbox(bheirarchy.box, lw, lc)
    if !isempty(bheirarchy.subboxes)
        drawboxheirarchy(bheirarchy.subboxes[1], 0.8*lw, lc)
        drawboxheirarchy(bheirarchy.subboxes[2], 0.8*lw, lc)
    end
end

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

# checks whether two box objects intersect/overlap
function boxintersect(box1::Box, box2::Box)
    return (abs(box1.x - box2.x) < (box1.halfwidth + box2.halfwidth)) &&
           (abs(box1.y - box2.y) < (box1.halfheight + box2.halfheight));
end

# creates a box object that surrounds a curve
function createboundingbox(curve::Array{Float64, 2})
    xpts = curve[:,1]
    ypts = curve[:,2]

    xmax = maximum(xpts)
    xmin = minimum(xpts)
    ymax = maximum(ypts)
    ymin = minimum(ypts)

    center_x =  (xmax+xmin)/2
    center_y = (ymax+ymin)/2
    halfwidth = (xmax-xmin)/2
    halfheight = (ymax-ymin)/2

    return Box(center_x, center_y, halfwidth, halfheight)
end

# creates a heirarchy of box objects from an initial curve
function createboxheirarchy(curve::Array{Float64, 2})
    npts = size(curve, 1)
    bbox = createboundingbox(curve)
    if npts == 2
        return BoxHeirarchy(bbox, curve, BoxHeirarchy[])
    else
        if npts == 3
            subcurve1 = curve[1:2, :]
            subcurve2 = curve[2:3, :]
            subbox1 = createboxheirarchy(subcurve1)
            subbox2 = createboxheirarchy(subcurve2)
        else
            midind = round(Int, npts/2)
            subcurve1 = curve[1:midind, :]
            subcurve2 = curve[midind:end, :]
            subbox1 = createboxheirarchy(subcurve1)
            subbox2 = createboxheirarchy(subcurve2)
        end
        return BoxHeirarchy(bbox, curve, [subbox1, subbox2])
    end
end

# finds the intersection point of two curves using the heirarchical bounding box method
function curveintersect_hb(curve1::Array{Float64, 2}, curve2::Array{Float64, 2})

    heirarchy1 = createboxheirarchy(curve1)
    heirarchy2 = createboxheirarchy(curve2)

    return findboxintersect_points(heirarchy1, heirarchy2)
end

function findboxintersect_points(heirarchy1::BoxHeirarchy, heirarchy2::BoxHeirarchy)
    boxlist1 = BoxHeirarchy[]
    boxlist2 = BoxHeirarchy[]
    boxlist1, boxlist2 = findboxintersections(heirarchy1, heirarchy2, boxlist1, boxlist2)

    nintersect = length(boxlist1)
    intersectpts = Array{Float64, 2}(undef, nintersect, 2)

    if nintersect > 0
        for i = 1:nintersect
            I = lineintersect(boxlist1[i].curve, boxlist2[i].curve)
            intersectpts[i,:] = I
        end
    end

    # remove all infinite entries from intersectpts. infinite entries represent
    # where low-level boxes intersected but their consituent line segments did not

    intersectpts = [filter(i->!isinf(i), intersectpts[:,1]) filter(i->!isinf(i), intersectpts[:,2])]

    return intersectpts
end

# loops through all m curves in curvelist 1, cataloguing all intersections with
# all n curves in curvelist 2.
# returns intersectgrid, an m by n grid of Array{Float64, 2}, where
# intersectgrid[i,j] contains an array of all x and y points of intersection of
# curve i with curve j
function curveintersect_hb(curvelist1::Array{Array{Float64, 2}, 1}, curvelist2::Array{Array{Float64, 2}, 1})

    nc1 = length(curvelist1)
    nc2 = length(curvelist2)
    intersectgrid = Array{Array{Float64, 2}, 2}(undef, nc1, nc2)

    # transform curves into bounding box heirarchies
    bboxlist1 = Array{BoxHeirarchy, 1}(undef, nc1)
    for i = 1:nc1
        bboxlist1[i] = createboxheirarchy(curvelist1[i])
    end
    bboxlist2 = Array{BoxHeirarchy, 1}(undef, nc2)
    for j = 1:nc2
        bboxlist2[j] = createboxheirarchy(curvelist2[j])
    end

    for i = 1:nc1
        heirarchy_i = bboxlist1[i]
        for j = 1:nc2
            heirarchy_j = bboxlist2[j]
            intersectpts = findboxintersect_points(heirarchy_i, heirarchy_j)
            @show intersectpts
            intersectgrid[i,j] = intersectpts
        end
    end

    return intersectgrid
end

#given two box heirarchies, return list of lowest-level boxes that overlap
function findboxintersections(heirarchy1::BoxHeirarchy, heirarchy2::BoxHeirarchy, boxlist1::Array{BoxHeirarchy, 1}, boxlist2::Array{BoxHeirarchy, 1})
    # 1. check if top-level boxes intersect

    if boxintersect(heirarchy1.box, heirarchy2.box)
        # 2. if they do, see if they are both single boxes.
        if isempty(heirarchy1.subboxes) && isempty(heirarchy2.subboxes)
            # 2a. If they both are, add them both to the list
            if isempty(boxlist1)
                boxlist1 = [heirarchy1]
                boxlist2 = [heirarchy2]
            else
                push!(boxlist1, heirarchy1)
                push!(boxlist2, heirarchy2)
            end

        # 2b. If one is, recursively check it against the other's subboxes
        elseif isempty(heirarchy1.subboxes)
            boxlist1, boxlist2 = findboxintersections(heirarchy1, heirarchy2.subboxes[1], boxlist1, boxlist2)
            boxlist1, boxlist2 = findboxintersections(heirarchy1, heirarchy2.subboxes[2], boxlist1, boxlist2)

        elseif isempty(heirarchy2.subboxes)
            boxlist1, boxlist2 = findboxintersections(heirarchy1.subboxes[1], heirarchy2, boxlist1, boxlist2)
            boxlist1, boxlist2 = findboxintersections(heirarchy1.subboxes[2], heirarchy2, boxlist1, boxlist2)

        # 3. If neither are single boxes, recursively check their subboxes against
        #   eachother, i.e 1-1 vs 2-1, 1-1 vs 2-2, 1-2 vs 2-1 and 1-2 vs 2-2
        else
            boxlist1, boxlist2 = findboxintersections(heirarchy1.subboxes[1], heirarchy2.subboxes[1], boxlist1, boxlist2)
            boxlist1, boxlist2 = findboxintersections(heirarchy1.subboxes[1], heirarchy2.subboxes[2], boxlist1, boxlist2)
            boxlist1, boxlist2 = findboxintersections(heirarchy1.subboxes[2], heirarchy2.subboxes[1], boxlist1, boxlist2)
            boxlist1, boxlist2 = findboxintersections(heirarchy1.subboxes[2], heirarchy2.subboxes[2], boxlist1, boxlist2)
        end
    end
    return boxlist1, boxlist2
end

function testboxintersect()
    npassed = 0
    ntests = 0
    println("Box intersection tests: ")
    b1 = Box(0.5, 0.5, 0.5, 0.5)
    b2 = Box(1.0, 1.0, 0.5, 0.5)
    b3 = Box(-10.0, -10.0, 0.5, 0.5)

    println("Test 1: Boxes intersect")
    ntests+=1
    intersect1 = boxintersect(b1, b2)
    if intersect1
        npassed+=1
        println("\tTest 1 passed")
    else
        println("\tTest 1 failed")
    end

    println("Test 2: Boxes don't intersect")
    ntests+=1
    intersect2 = boxintersect(b1, b3)
    if !intersect2
        npassed+=1
        println("\tTest 2 passed\n")
    else
        println("\tTest 2 failed\n")
    end

    return npassed, ntests
end

function testboundingboxes()
    npassed = 0
    ntests = 0
    println("Bounding box tests")
    l1 = [0.0 0.0; 1.0 1.0]
    l2 = [1.0 1.0; 0.0 0.0]

    println("Test 1: Single segment bounding box")
    expected = Box(0.5, 0.5, 0.5, 0.5)
    result_1 = createboundingbox(l1)
    ntests+=1
    if result_1 == expected
        println("\tTest 1 passed")
        npassed+=1
    else
        println("\tTest 1 failed")
        @show expected
        @show result_1
    end

    println("Test 2: Single segment bounding box, point order reversed")
    result_2 = createboundingbox(l2)
    ntests+=1
    if result_2 == expected
        println("\tTest 2 passed")
        npassed+=1
    else
        println("\tTest 2 failed")
        @show expected
        @show result_2
    end

    println()
    return npassed, ntests
end

function testboxheirarchy()
    npassed = 0
    ntests = 0

    println("Testing bounding box heirarchy construction")

    println("Test 1: Even number of segments")
    curve = [-1.0 -1.0
              0.0 0.0
              1.0 1.0 ]
    ntests+=1
    box1 = Box(0.0, 0.0, 1.0, 1.0)
    subbox1 = Box(0.5, 0.5, 0.5, 0.5)
    subbox2 = Box(-0.5, -0.5, 0.5, 0.5)

    subheirarchy1 = BoxHeirarchy(subbox1, curve[2:3, :], BoxHeirarchy[])
    subheirarchy2 = BoxHeirarchy(subbox2, curve[1:2, :], BoxHeirarchy[])
    expected = BoxHeirarchy(box1, curve, [subheirarchy2, subheirarchy1])
    result = createboxheirarchy(curve)

    if isboxheirarchyequal(expected, result)
        println("Test 1 passed")
        npassed+=1
    else
        println("Test 1 failed")
        @show expected
        @show result
    end

    println("Test 2: Odd number of segments")
    ntests +=1
    curve = [-1.0 -1.0
              0.0 0.0
              1.0 1.0
              2.0 2.0]

    box2 = createboundingbox(curve)
    subbox3 = Box(1.5, 1.5, 0.5, 0.5)
    subheirarchy3 = BoxHeirarchy(subbox3, curve[3:end,:], BoxHeirarchy[])
    subbox4 = Box(1.0, 1.0, 1.0, 1.0)
    subheirarchy4 = BoxHeirarchy(subbox4, curve[2:end, :], [subheirarchy1, subheirarchy3])
    expected = BoxHeirarchy(box2, curve, [subheirarchy2, subheirarchy4])
    result = createboxheirarchy(curve)

    if isboxheirarchyequal(expected, result)
        println("Test 2 passed")
        npassed+=1
    else
        println("Test 2 failed")
        @show expected
        @show result
    end

    println()

    return npassed, ntests
end

function testdrawboxheirarchy(curve1, curve2)
    #x1 = 0:0.01:1
    #x2 = 0:0.01:1
    #f1(x) = x^2
    #f2(x) = 1-x^2

    #y1 = f1.(x1)
    #y2 = f2.(x2)

    p = plot(curve1[:,1], curve1[:,2], label="")
    plot!(curve2[:,1], curve2[:,2], label="")

    bheirarchy1 = createboxheirarchy(curve1)
    bheirarchy2 = createboxheirarchy(curve2)
    drawboxheirarchy(bheirarchy1, 2.0, :blue)
    drawboxheirarchy(bheirarchy2, 2.0, :orange)

    boxlist1 = BoxHeirarchy[]
    boxlist2 = BoxHeirarchy[]

    boxlist1, boxlist2 = findboxintersections(bheirarchy1, bheirarchy2, boxlist1, boxlist2)
    for i = 1:length(boxlist1)
        drawbox(boxlist1[i].box, 2.0, :blue, 1.0)
        drawbox(boxlist2[i].box, 2.0, :orange, 1.0)
    end

    display(p)
    return boxlist1, boxlist2
end

function runtests_hb()
    println("\n================================")
    println("Running HB intersection tests: ")
    println("================================")
    npassed = 0
    ntests = 0

    np, nt = testboxintersect()
    ntests += nt
    npassed += np

    np, nt = testboundingboxes()
    ntests += nt
    npassed += np

    np, nt = testboxheirarchy()
    ntests += nt
    npassed += np

    np, nt = CurveTools.testintersect(curveintersect_hb)
    ntests += nt
    npassed += np

    println("HB test summary")
    println("------------------------------")
    println("$npassed out of $ntests passed\n")

    return ntests, npassed
end

end
