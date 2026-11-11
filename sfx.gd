class_name Sfx
extends Node
## Sons et musique générés par code (aucun fichier audio) : tirs, explosions,
## alertes, interface et ambiance. Touche M : couper / remettre le son.

const RATE := 22050
const MUSIC_RATE := 11025
const MUSIC_LEN := 16.0
const VOICES := 20
const WORLD_DB := -11.0 # niveau général des sons du monde
const UI_DB := -12.0    # niveau des sons d'interface

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
	_music.volume_db = -27.0
	add_child(_music)
	AudioServer.set_bus_mute(0, muted)
	AudioServer.set_bus_volume_db(0, -3.0)


func start_music() -> void:
	if not enabled:
		return
	_music.stream = stream_of("music")
	_music.play()


## Génère tous les sons à l'avance (écran de chargement) : un son par image.
func warm_up(step: Callable) -> void:
	if not enabled:
		return
	var names := ["autocannon", "cannon", "rocket", "sonic", "acid", "control", "hit", "boom", "boom_big",
			"worm", "click", "ack", "place", "coin", "ready", "unit_ready", "upgrade", "rank", "alert",
			"error", "victory", "defeat", "music"]
	for i in names.size():
		stream_of(names[i])
		await step.call(float(i + 1) / names.size(), names[i])


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
			p.volume_db = vol_db + WORLD_DB
			p.pitch_scale = _rng.randf_range(0.92, 1.08)
			p.play()
			return


## Son d'interface (non positionnel).
func play_ui(name: String, vol_db := 0.0) -> void:
	if not enabled:
		return
	_ui.stream = stream_of(name)
	_ui.volume_db = vol_db + UI_DB
	_ui.play()


func stream_of(name: String) -> AudioStreamWAV:
	if not _cache.has(name):
		_cache[name] = _make(name)
	return _cache[name]


# --- Synthèse -----------------------------------------------------------------
# Sons construits par couches (bruit filtré, partiels harmoniques, réverbération
# simple) pour éviter le rendu « bip » à ondes carrées.

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


func _blank(dur: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(dur * RATE))
	return b


## Bruit filtré (passe-bas à un pôle : k proche de 1 = grave), modulable en amplitude.
func _add_noise(buf: PackedFloat32Array, t0: float, dur: float, k: float, amp: float, decay: float,
		attack := 0.004, am := 0.0, am_depth := 0.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 + int(t0 * 1000.0) + int(k * 100.0)
	var n := int(dur * RATE)
	var start := int(t0 * RATE)
	var y := 0.0
	var gain := 1.0 / maxf(sqrt(1.0 - k * k), 0.1) * 0.55
	for i in n:
		if start + i >= buf.size():
			break
		var t := float(i) / RATE
		y = y * k + (rng.randf() * 2.0 - 1.0) * (1.0 - k)
		var env := exp(-t * decay) * minf(t / attack, 1.0)
		var mod := 1.0 - am_depth * (0.5 + 0.5 * sin(TAU * am * t)) if am > 0.0 else 1.0
		buf[start + i] += y * gain * amp * env * mod


## Son tonal à partiels harmoniques (harm = amplitude de chaque harmonique).
func _add_tone(buf: PackedFloat32Array, t0: float, dur: float, f0: float, f1: float, amp: float,
		decay: float, harm := [1.0], vib := 0.0, attack := 0.006) -> void:
	var n := int(dur * RATE)
	var start := int(t0 * RATE)
	var ph := 0.0
	for i in n:
		if start + i >= buf.size():
			break
		var t := float(i) / RATE
		var f := lerpf(f0, f1, float(i) / n) * (1.0 + vib * sin(t * 28.0))
		ph += TAU * f / RATE
		var s := 0.0
		for k in harm.size():
			s += sin(ph * float(k + 1)) * float(harm[k])
		buf[start + i] += s * amp * exp(-t * decay) * minf(t / attack, 1.0)


func _lowpass(buf: PackedFloat32Array, k: float) -> void:
	var y := 0.0
	for i in buf.size():
		y = y * k + buf[i] * (1.0 - k)
		buf[i] = y


## Écho simple : quelques répétitions atténuées (donne de l'espace).
func _reverb(buf: PackedFloat32Array, taps: Array, amp: float) -> void:
	var src := buf.duplicate()
	for j in taps.size():
		var d := int(float(taps[j]) * RATE)
		var g := amp * pow(0.7, j)
		for i in range(d, buf.size()):
			buf[i] += src[i - d] * g


func _make(name: String) -> AudioStreamWAV:
	var b: PackedFloat32Array
	match name:
		"autocannon":
			b = _blank(0.3)
			_add_noise(b, 0.0, 0.08, 0.55, 0.9, 40.0)
			_add_tone(b, 0.0, 0.07, 170.0, 95.0, 0.35, 45.0, [1.0, 0.5])
			_lowpass(b, 0.35)
			_reverb(b, [0.03, 0.07], 0.25)
		"cannon":
			b = _blank(0.9)
			_add_noise(b, 0.0, 0.4, 0.86, 1.0, 9.0)
			_add_noise(b, 0.0, 0.05, 0.4, 0.5, 60.0)
			_add_tone(b, 0.0, 0.4, 125.0, 45.0, 0.9, 8.0, [1.0, 0.4])
			_lowpass(b, 0.55)
			_reverb(b, [0.08, 0.17, 0.3], 0.3)
		"rocket":
			b = _blank(1.0)
			_add_noise(b, 0.0, 0.7, 0.65, 0.7, 4.0, 0.14)
			_add_tone(b, 0.0, 0.6, 90.0, 190.0, 0.3, 4.0, [1.0, 0.4], 0.01, 0.1)
			_lowpass(b, 0.5)
			_reverb(b, [0.1, 0.22], 0.25)
		"sonic":
			b = _blank(0.9)
			_add_tone(b, 0.0, 0.7, 85.0, 250.0, 0.45, 3.0, [1.0, 0.6, 0.3], 0.05, 0.08)
			_add_noise(b, 0.0, 0.6, 0.7, 0.2, 4.0, 0.1, 22.0, 0.6)
			_lowpass(b, 0.55)
			_reverb(b, [0.07, 0.15], 0.3)
		"acid":
			b = _blank(0.7)
			_add_noise(b, 0.0, 0.5, 0.45, 0.8, 6.0, 0.03, 26.0, 0.8)
			_add_tone(b, 0.0, 0.3, 240.0, 130.0, 0.2, 9.0, [1.0, 0.3], 0.15)
			_lowpass(b, 0.4)
			_reverb(b, [0.05, 0.11], 0.2)
		"control":
			b = _blank(1.4)
			_add_tone(b, 0.0, 1.0, 220.0, 165.0, 0.28, 2.2, [1.0, 0.5, 0.25], 0.06, 0.15)
			_add_tone(b, 0.0, 1.0, 223.0, 168.0, 0.28, 2.2, [1.0, 0.4, 0.2], 0.05, 0.15)
			_lowpass(b, 0.6)
			_reverb(b, [0.12, 0.26, 0.4], 0.35)
		"hit":
			b = _blank(0.3)
			_add_noise(b, 0.0, 0.12, 0.65, 0.8, 28.0)
			_add_tone(b, 0.0, 0.1, 150.0, 70.0, 0.4, 30.0)
			_lowpass(b, 0.45)
			_reverb(b, [0.04], 0.2)
		"boom":
			b = _blank(1.6)
			_add_noise(b, 0.0, 1.1, 0.92, 1.0, 3.5)
			_add_noise(b, 0.0, 0.15, 0.5, 0.5, 25.0)
			_add_tone(b, 0.0, 0.9, 70.0, 32.0, 0.8, 3.5, [1.0, 0.3])
			_lowpass(b, 0.62)
			_reverb(b, [0.1, 0.22, 0.38], 0.32)
		"boom_big":
			b = _blank(2.8)
			_add_noise(b, 0.0, 2.0, 0.95, 1.2, 2.0)
			_add_noise(b, 0.0, 0.25, 0.55, 0.6, 14.0)
			_add_tone(b, 0.0, 1.6, 62.0, 26.0, 0.9, 2.0, [1.0, 0.35])
			_lowpass(b, 0.68)
			_reverb(b, [0.13, 0.29, 0.5], 0.35)
		"worm":
			b = _blank(3.6)
			_add_noise(b, 0.0, 3.2, 0.96, 1.0, 1.1, 0.4)
			_add_noise(b, 0.3, 2.4, 0.8, 0.5, 1.4, 0.5, 14.0, 0.7)
			_add_tone(b, 0.0, 3.0, 46.0, 30.0, 0.7, 1.0, [1.0, 0.6, 0.3], 0.08, 0.3)
			_lowpass(b, 0.7)
			_reverb(b, [0.2, 0.45], 0.3)
		"click":
			b = _blank(0.1)
			_add_noise(b, 0.0, 0.03, 0.3, 0.5, 90.0)
			_add_tone(b, 0.0, 0.04, 800.0, 600.0, 0.12, 80.0, [1.0, 0.3])
		"ack":
			b = _blank(0.14)
			_add_tone(b, 0.0, 0.1, 480.0, 520.0, 0.14, 35.0, [1.0, 0.35])
			_lowpass(b, 0.5)
		"place":
			b = _blank(0.6)
			_add_noise(b, 0.0, 0.3, 0.88, 0.9, 12.0)
			_add_tone(b, 0.0, 0.3, 95.0, 50.0, 0.7, 11.0, [1.0, 0.3])
			_lowpass(b, 0.55)
			_reverb(b, [0.06, 0.13], 0.25)
		"coin":
			b = _blank(0.5)
			_add_tone(b, 0.0, 0.3, 1568.0, 1568.0, 0.1, 14.0, [1.0, 0.0, 0.35])
			_add_tone(b, 0.06, 0.4, 2093.0, 2093.0, 0.08, 12.0, [1.0, 0.0, 0.3])
			_reverb(b, [0.07], 0.2)
		"ready":
			b = _blank(1.6)
			var rn := [523.3, 659.3, 784.0]
			for i in rn.size():
				_add_tone(b, i * 0.14, 1.0, rn[i], rn[i], 0.16, 4.5, [1.0, 0.4, 0.15], 0.0, 0.004)
			_lowpass(b, 0.6)
			_reverb(b, [0.14, 0.3], 0.3)
		"unit_ready":
			b = _blank(1.0)
			_add_tone(b, 0.0, 0.6, 587.3, 587.3, 0.15, 6.0, [1.0, 0.4, 0.15])
			_add_tone(b, 0.12, 0.7, 880.0, 880.0, 0.13, 6.0, [1.0, 0.35, 0.1])
			_lowpass(b, 0.6)
			_reverb(b, [0.12], 0.3)
		"upgrade":
			b = _blank(1.8)
			for i in 4:
				var f := 440.0 * pow(1.2599, i)
				_add_tone(b, i * 0.11, 0.9, f, f, 0.14, 4.0, [1.0, 0.4, 0.15])
			_lowpass(b, 0.6)
			_reverb(b, [0.15, 0.32], 0.3)
		"rank":
			b = _blank(1.2)
			_add_tone(b, 0.0, 0.6, 659.3, 659.3, 0.14, 5.0, [1.0, 0.4, 0.15])
			_add_tone(b, 0.1, 0.8, 987.8, 987.8, 0.13, 5.0, [1.0, 0.35, 0.1])
			_lowpass(b, 0.6)
			_reverb(b, [0.13], 0.3)
		"alert":
			b = _blank(1.4)
			for i in 3:
				var f := 330.0 if i % 2 == 0 else 247.0
				_add_tone(b, i * 0.28, 0.26, f, f * 0.98, 0.3, 4.0, [1.0, 0.7, 0.5, 0.35, 0.2], 0.0, 0.02)
			_lowpass(b, 0.62)
			_reverb(b, [0.1, 0.22], 0.25)
		"error":
			b = _blank(0.4)
			_add_tone(b, 0.0, 0.2, 130.0, 100.0, 0.35, 10.0, [1.0, 0.5, 0.3])
			_lowpass(b, 0.55)
		"victory":
			b = _blank(4.0)
			var notes := [196.0, 246.9, 293.7, 392.0]
			for i in notes.size():
				_add_tone(b, i * 0.22, 2.2, notes[i], notes[i], 0.2, 1.4, [1.0, 0.6, 0.4, 0.25, 0.15], 0.004, 0.04)
			_add_tone(b, 0.9, 2.8, 392.0, 392.0, 0.18, 1.0, [1.0, 0.5, 0.3, 0.2], 0.004, 0.08)
			_add_tone(b, 0.9, 2.8, 587.3, 587.3, 0.12, 1.0, [1.0, 0.4, 0.2], 0.004, 0.08)
			_lowpass(b, 0.6)
			_reverb(b, [0.15, 0.32, 0.5], 0.3)
		"defeat":
			b = _blank(4.2)
			var dn := [220.0, 196.0, 175.0, 147.0]
			for i in dn.size():
				_add_tone(b, i * 0.5, 2.2, dn[i], dn[i] * 0.99, 0.22, 1.3, [1.0, 0.55, 0.3, 0.15], 0.004, 0.08)
			_lowpass(b, 0.62)
			_reverb(b, [0.18, 0.4], 0.3)
		"music":
			return _make_music()
		_:
			b = _blank(0.05)
	return _wav(b)


## Ambiance : nappe grave et lente, quelques notes douces. Toutes les fréquences
## sont des multiples de 1/16 Hz : la boucle est parfaite.
func _make_music() -> AudioStreamWAV:
	var n := int(MUSIC_LEN * MUSIC_RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var snap := func(f: float) -> float: return roundf(f * 16.0) / 16.0
	var drones: Array = [[snap.call(55.0), 0.30], [snap.call(82.5), 0.14], [snap.call(110.0), 0.08],
			[snap.call(130.8), 0.05]]
	for i in n:
		var t := float(i) / MUSIC_RATE
		var s := 0.0
		for j in drones.size():
			var d: Array = drones[j]
			var lfo := 0.6 + 0.4 * sin(TAU * t * (1.0 / MUSIC_LEN) * float(j + 1))
			s += sin(TAU * d[0] * t) * d[1] * lfo
		buf[i] = s
	var scale := [220.0, 261.6, 293.7, 329.6, 392.0, 440.0]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var tn := 1.0
	while tn < MUSIC_LEN - 3.5:
		var f: float = snap.call(scale[rng.randi() % scale.size()])
		var start := int(tn * MUSIC_RATE)
		var len := int(3.0 * MUSIC_RATE)
		for i in len:
			if start + i >= n:
				break
			var t := float(i) / MUSIC_RATE
			buf[start + i] += (sin(TAU * f * t) + 0.15 * sin(TAU * f * 2.0 * t)) * 0.045 * exp(-t * 1.3) * minf(t * 8.0, 1.0)
		tn += rng.randf_range(2.0, 3.8)
	return _wav(buf, MUSIC_RATE, true)
