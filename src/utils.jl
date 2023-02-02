using LinearAlgebra
using Interpolations

# 3D Rotations Matrices

Rx(α) = [1 0 0; 0 cos(α) -sin(α); 0 sin(α) cos(α)]
Ry(β) = [cos(β) 0 sin(β); 0 1 0; -sin(β) 0 cos(β)]
Rz(γ) = [cos(γ) -sin(γ) 0; sin(γ) cos(γ) 0; 0 0 1]

"""
	rotate(x, y, z, a, b, c, u, v, w, θ)

Rotate point `(x,y,z)` around the line that passes through the point `(a,b,c)`
in the direction of `<u,v,w>` on the angle `θ`.
"""
function rotate(x, y, z, a, b, c, u, v, w, θ)
	(a*(v^2+w^2)-u*(b*v+c*w-u*x-v*y-w*z))*(1-cos(θ))+x*cos(θ)+(-c*v+b*w-w*y+v*z)*sin(θ),
	(b*(u^2+w^2)-v*(a*u+c*w-u*x-v*y-w*z))*(1-cos(θ))+y*cos(θ)+(c*u-a*w+w*x-u*z)*sin(θ),
	(c*(u^2+v^2)-w*(a*u+b*v-u*x-v*y-w*z))*(1-cos(θ))+z*cos(θ)+(-b*u+a*v-v*x+u*y)*sin(θ)
end


"""
	rotatevoxel(o::Vector, p::Vector) -> f(x,y,z,θ)

Return a function that perform rotation of the voxel with coordinates `(x,y,z)`
on the angle `θ` within XY-plane around the line started in an origin point `o`,
and passing through a point `p`.
"""
function rotatevoxel(origin, p)
	dir = p .- origin |> normalize
	(x,y,z,θ) -> rotate(x, y, z, origin..., dir..., θ)
end

"""
	simulated_coordinates(sz::Tuple, a::Vector, b::Vector, θ::Float64)

Generate simulated coordinate set of size `sz` by rotating voxels within
*xy*-plain on angle `θ` around the line passing through points `a` and `b`.
"""
function simulated_coordinates(sz::Tuple, a, b, θ::Float64)
	rvfn = rotatevoxel(a, b) # create rotation function
	[rvfn(i,j,k,θ) for i in 1:sz[1], j in 1:sz[2], k in 1:sz[3]]
end

"""
	simulated_coordinates_at_z(sz::Tuple, z, a::Vector, b::Vector, θ::Float64)

Generate simulated coordinate set of size `sz` at depth `z`, by rotating voxels within
*xy*-plain on angle `θ` around the line passing through points `a` and `b`.
"""
function simulated_coordinates_at_z(sz::Tuple, z, a, b, θ::Float64)
	rvfn = rotatevoxel(a, b) # create rotation function
	[rvfn(i,j,z,θ) for i in 1:sz[1], j in 1:sz[2]]
end

"""
    phantominterp(imgs::AbstractArray; itrptype = BSpline(Quadratic()))

Construct interpolation function from an image 3D tensor.
"""
function phantominterp(imgs::AbstractArray; itrptype = BSpline(Quadratic()))
    (r,c,h) = size(imgs),
    xs = 1:r
    ys = 1:c
    zs = 1:h
    return extrapolate(scale(interpolate(imgs, itrptype), xs, ys, zs), Line())
end