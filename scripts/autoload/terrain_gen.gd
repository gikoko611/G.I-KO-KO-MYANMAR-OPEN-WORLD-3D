extends Node
# Deterministic terrain generator: the same world every run. Chunks are
# generated on demand around the player, so no data needs to be stored.

const WATER_Y = 0.7
const CHUNK = 48.0
const GRID = 12

# [x, z, radius, height] - flattened play areas
const FLAT_REGIONS = [
	[0.0, 60.0, 45.0, 3.0],
	[-110.0, 30.0, 40.0, 3.0],
	[160.0, 40.0, 50.0, 3.0],
	[120.0, 158.0, 18.0, 14.0],
	[-60.0, -95.0, 35.0, 0.4],
	[-85.0, -5.0, 30.0, 3.0],
	[-160.0, -100.0, 16.0, 1.2]
]

# road segments [ax, az, bx, bz]
const ROAD_SEGS = [
	[-110.0, 30.0, 0.0, 60.0],
	[0.0, 60.0, 160.0, 40.0],
	[160.0, 40.0, 120.0, 160.0],
	[-110.0, 30.0, -160.0, -84.0],
	[-160.0, -84.0, -160.0, -100.0],
	[-110.0, 30.0, -85.0, -5.0]
]

var n_base
var n_hill
var n_tree
var n_color

func _ready():
	randomize()
	n_base = OpenSimplexNoise.new()
	n_base.seed = 1337
	n_base.octaves = 3
	n_base.period = 90.0
	n_base.persistence = 0.5
	n_hill = OpenSimplexNoise.new()
	n_hill.seed = 777
	n_hill.octaves = 2
	n_hill.period = 45.0
	n_tree = OpenSimplexNoise.new()
	n_tree.seed = 9001
	n_tree.octaves = 1
	n_tree.period = 12.0
	n_color = OpenSimplexNoise.new()
	n_color.seed = 4242
	n_color.octaves = 1
	n_color.period = 18.0

func smoothstep01(t):
	t = clamp(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func river_z(x):
	return -55.0 + 30.0 * sin(x * 0.012)

func height(x, z):
	var h = 3.0 + n_base.get_noise_2d(x, z) * 2.2
	# rolling hills
	var hh = n_hill.get_noise_2d(x, z)
	if hh > 0.15:
		h += (hh - 0.15) * 22.0
	# mountain mass near the peak
	var mx = x - 230.0
	var mz = z - 150.0
	var md = sqrt(mx * mx + mz * mz)
	if md < 95.0:
		h += smoothstep01(1.0 - md / 95.0) * 36.0
	# flattened play regions
	for r in FLAT_REGIONS:
		var fdx = x - r[0]
		var fdz = z - r[1]
		var fd = sqrt(fdx * fdx + fdz * fdz)
		if fd < r[2] + 18.0:
			var ft = smoothstep01((r[2] + 18.0 - fd) / 18.0)
			h = lerp(h, r[3], ft)
	# river carve (skipped at the bridge causeway)
	var rz = river_z(x)
	var dr = abs(z - rz)
	if dr < 14.0 and abs(x + 160.0) > 8.0:
		var rt = smoothstep01(1.0 - dr / 14.0)
		h = lerp(h, -1.6, rt)
	# stream from the waterfall down to the river
	var sd = dist_to_seg(x, z, 40.0, 100.0, 30.0, -40.0)
	if sd < 7.0:
		var st = smoothstep01(1.0 - sd / 7.0)
		h = lerp(h, -1.2, st)
	# lake bowl
	var lx = x + 160.0
	var lz = z + 150.0
	var ld = sqrt(lx * lx + lz * lz)
	if ld < 60.0:
		var lt = smoothstep01(1.0 - ld / 60.0)
		h = lerp(h, -4.0, lt)
	# island in the lake
	var ix = x + 160.0
	var iz = z + 130.0
	var idist = sqrt(ix * ix + iz * iz)
	if idist < 9.0:
		var it = smoothstep01(1.0 - idist / 9.0)
		h = lerp(h, 1.6, it)
	# walkable causeway across the river at the old bridge
	if abs(x + 160.0) <= 8.0 and z > -100.0 and z < -64.0:
		var ct = smoothstep01(1.0 - abs(x + 160.0) / 8.0)
		h = lerp(h, max(h, 1.3), ct)
	return h

func dist_to_seg(px, pz, ax, az, bx, bz):
	var abx = bx - ax
	var abz = bz - az
	var denom = abx * abx + abz * abz
	if denom < 0.0001:
		var ddx = px - ax
		var ddz = pz - az
		return sqrt(ddx * ddx + ddz * ddz)
	var t = ((px - ax) * abx + (pz - az) * abz) / denom
	t = clamp(t, 0.0, 1.0)
	var cx = ax + abx * t
	var cz = az + abz * t
	var dx = px - cx
	var dz = pz - cz
	return sqrt(dx * dx + dz * dz)

func road_dist(x, z):
	var best = 99999.0
	for seg in ROAD_SEGS:
		var d = dist_to_seg(x, z, seg[0], seg[1], seg[2], seg[3])
		if d < best:
			best = d
	return best

func color_at(x, z, h):
	var n = n_color.get_noise_2d(x, z)
	var c = Color(0.36 + n * 0.08, 0.5 + n * 0.06, 0.22)
	if h < WATER_Y - 0.3:
		c = Color(0.2, 0.3, 0.35)
	elif h < WATER_Y + 0.35:
		c = Color(0.76, 0.7, 0.5)
	if h > 22.0:
		c = Color(0.55 + n * 0.1, 0.55 + n * 0.1, 0.58)
	var fx = x - 60.0
	var fz = z + 140.0
	if sqrt(fx * fx + fz * fz) < 60.0 and h > WATER_Y:
		c = c.darkened(0.18)
	var px = x + 60.0
	var pz = z + 95.0
	if sqrt(px * px + pz * pz) < 36.0:
		c = Color(0.55, 0.6, 0.3)
	if road_dist(x, z) < 4.5:
		c = Color(0.52, 0.45, 0.35)
	return c

func is_water(x, z):
	return height(x, z) < WATER_Y - 0.05

func in_flat_region(x, z, margin):
	for r in FLAT_REGIONS:
		var dx = x - r[0]
		var dz = z - r[1]
		if sqrt(dx * dx + dz * dz) < r[2] + margin:
			return true
	return false

func prop_at(x, z):
	var h = height(x, z)
	if h < 1.0 or h > 20.0:
		return ""
	if road_dist(x, z) < 6.0:
		return ""
	if in_flat_region(x, z, -8.0):
		return ""
	var n = n_tree.get_noise_2d(x, z)
	var rz = river_z(x)
	if abs(z - rz) < 26.0 and z > rz and n > 0.05:
		return "palm"
	if n > 0.35:
		return "tree"
	if n < -0.45 and h > 6.0:
		return "rock"
	if h > 1.2 and h < 6.0 and n > -0.1:
		return "grass"
	return ""

func rock_at(x, z):
	return prop_at(x, z) == "rock"
