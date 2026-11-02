extends Node
# Audio synthesizer: every sound effect and music loop in the game is
# generated as raw PCM data (AudioStreamSample). No audio files needed.

const RATE = 22050

var _sfx = {}
var _pool = []
var _music_player = null
var _ambience_player = null
var _rain_player = null
var _engine_player = null
var _music_last = ""
var _amb_last = ""

func _ready():
	_setup_buses()
	for i in range(8):
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = "Ambience"
	add_child(_ambience_player)
	_rain_player = AudioStreamPlayer.new()
	_rain_player.bus = "Ambience"
	add_child(_rain_player)
	_engine_player = AudioStreamPlayer.new()
	_engine_player.bus = "SFX"
	add_child(_engine_player)

func _setup_buses():
	for bname in ["Music", "SFX", "Ambience"]:
		var idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bname)
		AudioServer.set_bus_send(idx, "Master")

func set_bus_volume(bname, linear):
	var idx = AudioServer.get_bus_index(bname)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear2db(clamp(linear, 0.0001, 1.0)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)

# ----------------------------- PCM building -----------------------------

func _bytes(samples):
	var data = PoolByteArray()
	for s in samples:
		var v = int(clamp(s, -1.0, 1.0) * 32000.0)
		data.append(v & 255)
		data.append((v >> 8) & 255)
	return data

func _make(samples, loop=false):
	var a = AudioStreamSample.new()
	a.data = _bytes(samples)
	a.format = AudioStreamSample.FORMAT_16_BITS
	a.mix_rate = RATE
	a.stereo = false
	if loop:
		a.loop_mode = AudioStreamSample.LOOP_FORWARD
		a.loop_end = samples.size()
	return a

func _tone(freq, dur, vol, wave):
	var n = int(dur * RATE)
	var out = []
	var attack = min(0.012, dur * 0.25)
	var release = min(0.06, dur * 0.35)
	for i in range(n):
		var t = float(i) / float(RATE)
		var ph = fmod(t * freq, 1.0)
		var v = 0.0
		if wave == 1:
			v = sign(sin(TAU * ph)) * 0.6
		elif wave == 2:
			v = ph * 2.0 - 1.0
		else:
			v = sin(TAU * ph)
		var env = vol
		if t < attack:
			env *= t / attack
		if t > dur - release:
			env *= max(0.0, (dur - t) / release)
		out.append(v * env)
	return out

func _noise(dur, vol, fade=true):
	var n = int(dur * RATE)
	var out = []
	for i in range(n):
		var t = float(i) / float(RATE)
		var env = vol
		if fade:
			env *= max(0.0, 1.0 - t / dur)
		out.append(rand_range(-1.0, 1.0) * env)
	return out

func _noise_loop(dur, vol, smoothing):
	var n = int(dur * RATE)
	var out = []
	var v = 0.0
	var edge = int(RATE * 0.15)
	for i in range(n):
		v = lerp(v, rand_range(-1.0, 1.0), smoothing)
		var e = 1.0
		if i < edge:
			e = float(i) / float(edge)
		elif i > n - edge:
			e = float(n - i) / float(edge)
		out.append(v * vol * e)
	return out

func _concat(parts):
	var out = []
	for p in parts:
		for s in p:
			out.append(s)
	return out

func _melody(notes, tempo, vol):
	var out = []
	for nt in notes:
		var seg = _tone(nt[0], nt[1] * tempo, vol, 0)
		for s in seg:
			out.append(s)
		for i in range(int(RATE * 0.03)):
			out.append(0.0)
	return out

func _engine():
	var n = int(1.2 * RATE)
	var out = []
	var v = 0.0
	for i in range(n):
		v = lerp(v, rand_range(-1.0, 1.0), 0.3)
		var t = float(i) / float(RATE)
		out.append(v * 0.35 + sin(TAU * 55.0 * t) * 0.35)
	return out

func _chirp():
	return _concat([_tone(950.0, 0.06, 0.28, 1), _tone(1200.0, 0.06, 0.28, 1), _tone(1050.0, 0.07, 0.24, 1)])

func _moo():
	var out = []
	var n = int(0.7 * RATE)
	for i in range(n):
		var t = float(i) / float(RATE)
		var f = 150.0 - t * 50.0
		var env = sin(PI * t / 0.7)
		out.append(sin(TAU * f * t) * 0.4 * env)
	return out

func _day_music():
	return _melody([[523.0, 1.0], [587.0, 0.5], [659.0, 1.0], [784.0, 1.5], [659.0, 0.5], [587.0, 0.5], [523.0, 1.5], [0.0, 1.0], [659.0, 0.5], [784.0, 0.5], [880.0, 1.5], [784.0, 0.5], [659.0, 1.0], [523.0, 2.0], [0.0, 1.0]], 0.32, 0.22)

func _night_music():
	return _melody([[392.0, 1.5], [440.0, 0.5], [523.0, 1.5], [440.0, 0.5], [392.0, 2.0], [0.0, 1.0], [329.0, 1.0], [392.0, 1.0], [523.0, 2.0], [0.0, 1.5]], 0.4, 0.18)

# ------------------------------ sound bank ------------------------------

func _get_sfx(name):
	if _sfx.has(name):
		return _sfx[name]
	var samples = null
	var loop = false
	if name == "click":
		samples = _tone(700.0, 0.05, 0.25, 1)
	elif name == "accept":
		samples = _concat([_tone(520.0, 0.07, 0.3, 0), _tone(780.0, 0.1, 0.3, 0)])
	elif name == "deny":
		samples = _concat([_tone(220.0, 0.12, 0.3, 2), _tone(160.0, 0.15, 0.3, 2)])
	elif name == "notify":
		samples = _concat([_tone(880.0, 0.08, 0.2, 0), _tone(1100.0, 0.1, 0.2, 0)])
	elif name == "complete":
		samples = _concat([_tone(523.0, 0.1, 0.3, 0), _tone(659.0, 0.1, 0.3, 0), _tone(784.0, 0.18, 0.3, 0)])
	elif name == "fail":
		samples = _concat([_tone(392.0, 0.1, 0.25, 1), _tone(330.0, 0.1, 0.25, 1), _tone(262.0, 0.2, 0.25, 1)])
	elif name == "harvest":
		samples = _concat([_noise(0.08, 0.3), _tone(440.0, 0.1, 0.25, 0), _tone(660.0, 0.1, 0.25, 0)])
	elif name == "plant":
		samples = _concat([_noise(0.06, 0.25), _tone(330.0, 0.08, 0.2, 0)])
	elif name == "plow":
		samples = _concat([_noise(0.15, 0.35), _noise(0.1, 0.2)])
	elif name == "water":
		samples = _noise(0.25, 0.3)
	elif name == "chop":
		samples = _concat([_noise(0.05, 0.4), _tone(180.0, 0.08, 0.3, 2)])
	elif name == "dig":
		samples = _concat([_noise(0.1, 0.35), _noise(0.1, 0.25)])
	elif name == "splash":
		samples = _concat([_tone(200.0, 0.06, 0.2, 0), _noise(0.2, 0.35)])
	elif name == "bite":
		samples = _concat([_tone(900.0, 0.05, 0.3, 1), _noise(0.06, 0.3)])
	elif name == "eat":
		samples = _concat([_noise(0.08, 0.25), _noise(0.08, 0.2), _tone(520.0, 0.08, 0.2, 0)])
	elif name == "coin":
		samples = _concat([_tone(988.0, 0.06, 0.3, 0), _tone(1319.0, 0.12, 0.3, 0)])
	elif name == "step":
		samples = _noise(0.05, 0.12)
	elif name == "jump":
		samples = _tone(300.0, 0.15, 0.2, 0)
	elif name == "chirp":
		samples = _chirp()
	elif name == "moo":
		samples = _moo()
	elif name == "cluck":
		samples = _concat([_tone(600.0, 0.05, 0.25, 1), _tone(500.0, 0.05, 0.2, 1), _tone(700.0, 0.06, 0.2, 1)])
	elif name == "bark":
		samples = _concat([_tone(400.0, 0.08, 0.35, 2), _tone(300.0, 0.1, 0.3, 2)])
	elif name == "race_start":
		samples = _concat([_tone(440.0, 0.2, 0.35, 1), _tone(440.0, 0.2, 0.35, 1), _tone(880.0, 0.4, 0.4, 1)])
	elif name == "rain":
		samples = _noise_loop(3.0, 0.3, 0.25)
		loop = true
	elif name == "river":
		samples = _noise_loop(4.0, 0.28, 0.18)
		loop = true
	elif name == "village":
		samples = _noise_loop(5.0, 0.12, 0.08)
		loop = true
	elif name == "forest":
		samples = _concat([_noise_loop(4.0, 0.1, 0.06), _chirp()])
		loop = true
	elif name == "engine":
		samples = _engine()
		loop = true
	elif name == "music_day":
		samples = _day_music()
		loop = true
	elif name == "music_night":
		samples = _night_music()
		loop = true
	if samples == null:
		samples = _tone(440.0, 0.1, 0.2, 0)
	var s = _make(samples, loop)
	_sfx[name] = s
	return s

# -------------------------------- public --------------------------------

func play(name, vol_db=0.0):
	for p in _pool:
		if not p.playing:
			p.stream = _get_sfx(name)
			p.volume_db = vol_db
			p.play()
			return

func play_music(name):
	if _music_last == name and _music_player.playing:
		return
	_music_last = name
	_music_player.stream = _get_sfx(name)
	_music_player.play()

func play_ambience(name):
	if _amb_last == name and _ambience_player.playing:
		return
	_amb_last = name
	_ambience_player.stream = _get_sfx(name)
	_ambience_player.play()

func set_rain(on):
	if on and not _rain_player.playing:
		_rain_player.stream = _get_sfx("rain")
		_rain_player.play()
	elif not on and _rain_player.playing:
		_rain_player.stop()

func set_engine(on, throttle=0.0):
	if on:
		if not _engine_player.playing:
			_engine_player.stream = _get_sfx("engine")
			_engine_player.play()
		_engine_player.pitch_scale = clamp(0.7 + throttle * 0.6, 0.7, 1.4)
	elif _engine_player.playing:
		_engine_player.stop()
