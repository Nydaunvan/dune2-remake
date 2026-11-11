class_name Sfx
extends Node
## Sons et musique générés par code (aucun fichier audio) : tirs, explosions,
## alertes, interface et ambiance. Touche M : couper / remettre le son.

const RATE := 22050
const MUSIC_RATE := 11025
const MUSIC_LEN := 16.0
const VOICES := 20

static var _cache := {}
static var muted := false

var enabled := true
var _voices: Array[AudioStreamPlayer2D] = []
var _ui: AudioStreamPlayer
var _music: AudioStreamPlayer
var _last := {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		enabled = false
		return
	_rng.randomize()
	for i in VOICES:
		var p := AudioStreamPlayer2D.new()
		p.max_distance = 1700.0
		p.attenuation = 1.6
		add_child(p)
		_voices.append(p)
	_ui = AudioStreamPlayer.new()
	add_child(_ui)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -15.0
	add_child(_music)
	AudioServer.set_bus_mute(0, muted)


func start_music() -> void:
	if not enabled:
		return
	_music.stream = stream_of("music")
	_music.play()


func toggle_mute() -> bool:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	return muted


## Son positionnel dans le monde.
func play(name: String, pos: Vector2, vol_db := 0.0) -> void:
	if not enabled:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(name, -1.0)) < 0.045:
		return
	_last[name] = now
	for p in _voices:
		if not p.playing:
			p.stream = stream_of(name)
			p.position = pos
			p.volume_db = vol_db
			p.pitch_scale = _rng.randf_range(0.92, 1.08)
			p.play()
			return


## Son d'interface (non positionnel).
func play_ui(name: String, vol_db := 0.0) -> void:
	if not enabled:
		return
	_ui.stream = stream_of(name)
	_ui.volume_db = vol_db
	_ui.play()


func stream_of(name: String) -> AudioStreamWAV:
	if not _cache.has(name):
		_cache[name] = _make(name)
	return _cache[name]


# --- Synthèse -----------------------------------------------------------------

func _wav(data: PackedFloat32Array, rate := RATE, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(tanh(data[i] * 0.9) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = data.size()
	return w


## Bruit filtré (passe-bas à un pôle : k proche de 1 = grave).
func _noise(n: int, k: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(n)
	var y := 0.0
	for i in n:
		y = y * k + (rng.randf() * 2.0 - 1.0) * (1.0 - k)
		out[i] = y / maxf(1.0 - k, 0.05) * 0.5
	return out


func _add_tone(buf: PackedFloat32Array, t0: float, dur: float, f0: float, f1: float, amp: float,
		decay: float, vib := 0.0, square := 0.0) -> void:
	var n := int(dur * RATE)
	var start := int(t0 * RATE)
	var ph := 0.0
	for i in n:
		if start + i >= buf.size():
			break
		var t := float(i) / RATE
		var f := lerpf(f0, f1, float(i) / n) * (1.0 + vib * sin(t * 40.0))
		ph += TAU * f / RATE
		var s := sin(ph)
		if square > 0.0:
			s = lerpf(s, signf(s), square)
		var env := exp(-t * decay) * minf(t * 400.0, 1.0)
		buf[start + i] += s * amp * env


func _blank(dur: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(dur * RATE))
	return b


func _add_noise(buf: PackedFloat32Array, t0: float, dur: float, k: float, amp: float, decay: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 + int(t0 * 1000.0)
	var n := int(dur * RATE)
	var nz := _noise(n, k, rng)
	var start := int(t0 * RATE)
	for i in n:
		if start + i >= buf.size():
			break
		var t := float(i) / RATE
		buf[start + i] += nz[i] * amp * exp(-t * decay) * minf(t * 300.0, 1.0)


func _make(name: String) -> AudioStreamWAV:
	var b: PackedFloat32Array
	match name:
		"autocannon":
			b = _blank(0.12)
			_add_noise(b, 0.0, 0.1, 0.35, 0.5, 35.0)
			_add_tone(b, 0.0, 0.08, 1400.0, 500.0, 0.25, 40.0, 0.0, 0.6)
		"cannon":
			b = _blank(0.45)
			_add_noise(b, 0.0, 0.3, 0.8, 0.9, 12.0)
			_add_tone(b, 0.0, 0.35, 170.0, 55.0, 0.8, 9.0)
		"rocket":
			b = _blank(0.6)
			_add_noise(b, 0.0, 0.55, 0.7, 0.6, 5.0)
			_add_tone(b, 0.0, 0.5, 220.0, 520.0, 0.18, 4.0, 0.02, 0.4)
		"sonic":
			b = _blank(0.5)
			_add_tone(b, 0.0, 0.45, 240.0, 1100.0, 0.35, 4.0, 0.06)
			_add_tone(b, 0.0, 0.45, 120.0, 550.0, 0.25, 4.0, 0.04)
		"acid":
			b = _blank(0.4)
			_add_noise(b, 0.0, 0.35, 0.5, 0.45, 8.0)
			_add_tone(b, 0.0, 0.3, 380.0, 180.0, 0.3, 8.0, 0.25)
		"control":
			b = _blank(0.8)
			_add_tone(b, 0.0, 0.75, 520.0, 380.0, 0.35, 2.5, 0.12)
			_add_tone(b, 0.0, 0.75, 780.0, 570.0, 0.2, 2.5, 0.1)
		"hit":
			b = _blank(0.2)
			_add_noise(b, 0.0, 0.15, 0.6, 0.6, 22.0)
			_add_tone(b, 0.0, 0.12, 220.0, 100.0, 0.3, 25.0)
		"boom":
			b = _blank(0.9)
			_add_noise(b, 0.0, 0.8, 0.88, 1.0, 5.0)
			_add_tone(b, 0.0, 0.7, 95.0, 38.0, 0.8, 4.5)
		"boom_big":
			b = _blank(1.7)
			_add_noise(b, 0.0, 1.6, 0.93, 1.2, 2.6)
			_add_noise(b, 0.0, 0.5, 0.5, 0.5, 10.0)
			_add_tone(b, 0.0, 1.4, 80.0, 28.0, 1.0, 2.2)
		"worm":
			b = _blank(2.4)
			_add_noise(b, 0.0, 2.3, 0.94, 1.1, 1.3)
			_add_tone(b, 0.0, 2.2, 52.0, 34.0, 0.7, 1.0, 0.12)
			_add_tone(b, 0.2, 1.6, 90.0, 60.0, 0.3, 1.6, 0.2, 0.5)
		"click":
			b = _blank(0.06)
			_add_tone(b, 0.0, 0.05, 1200.0, 900.0, 0.4, 60.0)
		"ack":
			b = _blank(0.09)
			_add_tone(b, 0.0, 0.08, 660.0, 760.0, 0.3, 30.0, 0.0, 0.3)
		"place":
			b = _blank(0.35)
			_add_noise(b, 0.0, 0.25, 0.85, 0.7, 12.0)
			_add_tone(b, 0.0, 0.25, 140.0, 70.0, 0.6, 12.0)
		"coin":
			b = _blank(0.3)
			_add_tone(b, 0.0, 0.12, 1320.0, 1320.0, 0.3, 14.0)
			_add_tone(b, 0.07, 0.2, 1760.0, 1760.0, 0.3, 12.0)
		"ready":
			b = _blank(0.7)
			_add_tone(b, 0.0, 0.25, 523.0, 523.0, 0.3, 7.0, 0.0, 0.2)
			_add_tone(b, 0.12, 0.25, 659.0, 659.0, 0.3, 7.0, 0.0, 0.2)
			_add_tone(b, 0.24, 0.4, 784.0, 784.0, 0.3, 5.0, 0.0, 0.2)
		"unit_ready":
			b = _blank(0.4)
			_add_tone(b, 0.0, 0.2, 587.0, 587.0, 0.3, 9.0, 0.0, 0.2)
			_add_tone(b, 0.1, 0.3, 880.0, 880.0, 0.3, 7.0, 0.0, 0.2)
		"upgrade":
			b = _blank(0.9)
			for i in 4:
				_add_tone(b, i * 0.1, 0.4, 440.0 * pow(1.2599, i), 440.0 * pow(1.2599, i), 0.28, 6.0, 0.0, 0.15)
		"rank":
			b = _blank(0.6)
			_add_tone(b, 0.0, 0.2, 660.0, 660.0, 0.3, 8.0)
			_add_tone(b, 0.1, 0.4, 990.0, 990.0, 0.3, 6.0)
		"alert":
			b = _blank(0.7)
			for i in 3:
				_add_tone(b, i * 0.2, 0.15, 880.0 if i % 2 == 0 else 620.0, 880.0 if i % 2 == 0 else 620.0,
						0.35, 6.0, 0.0, 0.7)
		"error":
			b = _blank(0.3)
			_add_tone(b, 0.0, 0.25, 180.0, 130.0, 0.4, 8.0, 0.0, 0.8)
		"victory":
			b = _blank(2.2)
			var notes := [392.0, 494.0, 587.0, 784.0, 988.0]
			for i in notes.size():
				_add_tone(b, i * 0.16, 1.2, notes[i], notes[i], 0.22, 2.2, 0.0, 0.2)
		"defeat":
			b = _blank(2.6)
			var dn := [440.0, 392.0, 349.0, 294.0]
			for i in dn.size():
				_add_tone(b, i * 0.3, 1.5, dn[i], dn[i] * 0.98, 0.25, 1.8, 0.01, 0.3)
		"music":
			return _make_music()
		_:
			b = _blank(0.05)
	return _wav(b)


## Ambiance : bourdon grave, nappe lente et quelques notes pentatoniques.
## Toutes les fréquences sont des multiples de 1/16 Hz : la boucle est parfaite.
func _make_music() -> AudioStreamWAV:
	var n := int(MUSIC_LEN * MUSIC_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var snap := func(f: float) -> float: return roundf(f * 16.0) / 16.0
	var drones: Array = [[snap.call(55.0), 0.30], [snap.call(82.5), 0.16], [snap.call(110.0), 0.10],
			[snap.call(130.8), 0.07], [snap.call(164.8), 0.05]]
	for i in n:
		var t := float(i) / MUSIC_RATE
		var s := 0.0
		for j in drones.size():
			var d: Array = drones[j]
			var lfo := 0.65 + 0.35 * sin(TAU * t * (1.0 / MUSIC_LEN) * float(j + 1))
			s += sin(TAU * d[0] * t) * d[1] * lfo
		buf[i] = s
	# Notes éparses (gamme mineure pentatonique), enveloppe en cloche
	var scale := [220.0, 261.6, 293.7, 329.6, 392.0, 440.0, 523.3]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var tn := 1.0
	while tn < MUSIC_LEN - 3.0:
		var f: float = snap.call(scale[rng.randi() % scale.size()])
		var start := int(tn * MUSIC_RATE)
		var len := int(2.6 * MUSIC_RATE)
		for i in len:
			if start + i >= n:
				break
			var t := float(i) / MUSIC_RATE
			buf[start + i] += (sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.0 * t)) * 0.07 * exp(-t * 1.6) * minf(t * 60.0, 1.0)
		tn += rng.randf_range(1.6, 3.2)
	return _wav(buf, MUSIC_RATE, true)
