extends SceneTree
## Essai TileMapLayer : le TileSet porte les données, la carte se remplit, lecture par case, temps de génération.
func _initialize() -> void:
	var failed := 0
	var demo = load("res://experiments/tilemap/tilemap_demo.gd").new()
	root.add_child(demo)
	await process_frame
	var layer: TileMapLayer = demo.layer
	var counts := {}
	for y in 192:
		for x in 192:
			var d := layer.get_cell_tile_data(Vector2i(x, y))
			if d == null:
				failed += 1
				continue
			var k: String = d.get_custom_data("kind")
			counts[k] = int(counts.get(k, 0)) + 1
	print("cases par type : ", counts)
	if layer.get_used_cells().size() != 192 * 192:
		failed += 1
		push_error("cases remplies : %d" % layer.get_used_cells().size())
	var ms: float = demo.generate(256, 99)
	print("génération 256x256 : %.0f ms" % ms)
	print("Résultat : %d échec(s)" % failed)
	quit(1 if failed > 0 else 0)
