using Plots
using Contour
include("lineintersect.jl") #hide

function plotcontours(cont, clr=:black)
    for cl in levels(cont)
        #lvl = level(cl) # the z-value of this contour level
        for line in lines(cl)
            xs, ys = coordinates(line) # coordinates of this line segment
            plot!(xs, ys, label = "", linecolor = clr)
        end
    end
end

x = range(0, stop=1, length=103)
y = range(0, stop=1, length=103)

xgrid = [xi-0.1*yi for xi in x, yi in y]
ygrid = [yi-0.1*xi for xi in x, yi in y]

#c = Plots.contour(x, y, xgrid, levels=11, color=:blue, colorbar=false)
#Plots.contour!(x, y, ygrid, levels=11, color=:red, colorbar=false)

x_new = range(minimum(xgrid)/1.1, stop=maximum(xgrid)*1.1, length=103)
y_new = range(minimum(ygrid)/1.1, stop=maximum(ygrid)*1.1, length=103)
ch = Contour.contours(x_new, y_new, xgrid, 11)
cv = Contour.contours(x_new, y_new, ygrid, 11)

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
c = plot()
plotcontours(ch, :blue)
plotcontours(cv, :red)

xgrid, ygrid = findmeshpoints(curvelist_h, curvelist_v)
scatter!(reshape(xgrid, nh*nv, 1), reshape(ygrid, nh*nv, 1), label="")


display(c)
