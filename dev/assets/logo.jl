using CairoMakie
using Makie.Colors

f = Figure(size=(500, 500), backgroundcolor=:transparent)

colors = [
    RGBf(0.251, 0.388, 0.847),
    RGBf(0.584, 0.345, 0.698),
    RGBf(0.796, 0.235, 0.200),
    RGBf(0.220, 0.596, 0.149),
]
colors = [
    RGBf(0.584, 0.345, 0.698),
    RGBf(0.251, 0.388, 0.847),
    RGBf(0.220, 0.596, 0.149),
    RGBf(0.796, 0.235, 0.200),
]
Axis(f[1, 1], aspect=0.9,
    backgroundcolor=:transparent, 
    leftspinevisible=false,
    rightspinevisible=false,
    bottomspinevisible=false,
    topspinevisible=false,
    xticklabelsvisible=false,
    yticklabelsvisible=false,
    xgridcolor=:transparent,
    ygridcolor=:transparent,
    xminorticksvisible=false,
    yminorticksvisible=false,
    xticksvisible=false,
    yticksvisible=false,
    xautolimitmargin=(0.1, 0.1),
    yautolimitmargin=(0.1, 0.1),)
for i in 1:4
    arc!(Point2f(0, 0), i - 1, -π/4, π/4; linecap=:round, linewidth=50, color=colors[i])
end

save("logo.png", f)
save("logo.svg", f)
f
