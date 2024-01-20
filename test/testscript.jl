using Revise
using CurveIntersect
using Plots
using Contour

function plotcontours(cont, clr=:black)
    for cl in levels(cont)
        #lvl = level(cl) # the z-value of this contour level
        for line in lines(cl)
            xs, ys = coordinates(line) # coordinates of this line segment
            plot!(xs, ys, label = "", linecolor = clr)
        end
    end
end

function plotcurvelist(curvelist, clr=:black)
    for c in curvelist
        plot!(c[1,:], c[2,:], linecolor=clr, label="")
    end
end

xrange = (-0.1, 1.2)
yrange = (-0.1, 1.2)

x = range(xrange[1], stop=xrange[2], length=1000)
y = range(yrange[1], stop=yrange[2], length=1000)

xgrid = [xi-yi^2 for xi in x, yi in y]
ygrid = [xi+yi^2 for xi in x, yi in y]

#c = Plots.contour(x, y, xgrid, levels=11, color=:blue, colorbar=false)
#Plots.contour!(x, y, ygrid, levels=11, color=:red, colorbar=false)

ch = Contour.contours(x, y, xgrid, 15)
cv = Contour.contours(x, y, ygrid, 15)

nh = length(levels(ch))
nv = length(levels(cv))
curvelist_h = Array{Array{Float64, 2}, 1}(undef, nh)
curvelist_v = Array{Array{Float64, 2}, 1}(undef, nv)

levels_h = levels(ch)
levels_v = levels(cv)

for i = 1:nh
    xs, ys = coordinates(lines(levels_h[i])[1])
    curve = [xs ys]
    curvelist_h[i] = curve
end

for i = 1:nv
    xs, ys = coordinates(lines(levels_v[i])[1])
    curve = [xs ys]
    curvelist_v[i] = curve
end

intersectgrid = curveintersect(curvelist_h, curvelist_v)
intersectpts = getintersectpoints(intersectgrid)

boundarycurve1 = [x, yrange[1]*ones(Float64, length(x))]
boundarycurve2 = [x, yrange[2]*ones(Float64, length(x))]
boundarycurve3 = [xrange[1]*ones(Float64, length(x)), y]
boundarycurve4 = [xrange[2]*ones(Float64, length(x)), y]
boundarycurves = [boundarycurve1, boundarycurve2, boundarycurve3, boundarycurve4]

c = plot()
plotcontours(ch, :blue)
plotcontours(cv, :red)
plotcurvelist(boundarycurves)
scatter!(intersectpts[:,1], intersectpts[:,2], label="")
#mesh =  createmeshfromcontours(curvelist_h, curvelish_v)
display(c)
