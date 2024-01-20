module CurveIntersect

export curveintersect, getintersectpoints

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

# finds the intersection point of two curves using the heirarchical bounding box method
function curveintersect(curve1::Array{Float64, 2}, curve2::Array{Float64, 2})

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
function curveintersect(curvelist1::Array{Array{Float64, 2}, 1}, curvelist2::Array{Array{Float64, 2}, 1})

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

            intersectgrid[i,j] = intersectpts
        end
    end

    return intersectgrid
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
end
