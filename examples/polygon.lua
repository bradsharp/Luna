local class = require"lib/luna"

return class {
	Points = {get = function (this) return this.points end},
	__construct = function (this, ...)
		this.points = {...}
	end,
	Contains = function (this, point)
		local x, z = point.X, point.Z
		local function cut_ray(p, q)
			return ((p.Z > z and q.z < z) or (p.Z < z and q.z > z))
				and (x - p.X < (z - p.Z) * (q.x - p.X) / (q.z - p.Z))
		end
		local function cross_boundary(p,q)
			return (p.Z == z and p.X > x and q.z < z)
				or (q.z == z and q.x > x and p.Z < z)
		end
		local v = this.points
		local in_polygon = false
		local p, q = v[#v], v[#v]
		for i = 1, #v do
			p, q = q, v[i]
			if cut_ray(p, q) or cross_boundary(p, q) then
				in_polygon = not in_polygon
			end
		end
		return in_polygon
	end
}
