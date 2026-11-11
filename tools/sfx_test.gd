extends SceneTree
## Génère tous les sons (affichage requis pour activer Sfx) et mesure le temps.
func _initialize() -> void:
	var s := Sfx.new()
	root.add_child(s)
	s.enabled = true
	var t0 := Time.get_ticks_msec()
	for n in ["autocannon","cannon","rocket","sonic","acid","control","hit","boom","boom_big","worm","click","ack","place","coin","ready","unit_ready","upgrade","rank","alert","error","victory","defeat","music"]:
		var w: AudioStreamWAV = s.stream_of(n)
		var peak := 0
		for i in range(0, w.data.size(), 2):
			peak = maxi(peak, absi(w.data.decode_s16(i)))
		print("%s: %.2fs pic=%d" % [n, float(w.data.size()) / 2.0 / w.mix_rate, peak])
	print("total ms=", Time.get_ticks_msec() - t0)
	quit()
