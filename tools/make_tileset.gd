extends SceneTree
## Génère experiments/tilemap/world_tileset.tres (essai TileMapLayer).
## godot --headless --path . --import ; godot --headless --path . -s res://tools/make_tileset.gd
const KINDS := [
	["sable", true, 1.0], ["sable", true, 1.0], ["roche", true, 0.7], ["epice", true, 0.9],
	["dune", false, 0.6], ["dune", false, 0.6], ["roche_profonde", false, 0.0], ["sable_sombre", true, 1.0],
]

func _initialize() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "kind")
	ts.set_custom_data_layer_type(0, TYPE_STRING)
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(1, "buildable")
	ts.set_custom_data_layer_type(1, TYPE_BOOL)
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(2, "speed")
	ts.set_custom_data_layer_type(2, TYPE_FLOAT)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = load("res://experiments/tilemap/tiles.png")
	atlas.texture_region_size = Vector2i(32, 32)
	ts.add_source(atlas, 0)
	for i in KINDS.size():
		var c := Vector2i(i % 4, i / 4)
		atlas.create_tile(c)
		var d := atlas.get_tile_data(c, 0)
		d.set_custom_data("kind", KINDS[i][0])
		d.set_custom_data("buildable", KINDS[i][1])
		d.set_custom_data("speed", KINDS[i][2])
	var err := ResourceSaver.save(ts, "res://experiments/tilemap/world_tileset.tres")
	print("tileset : ", error_string(err))
	quit(0 if err == OK else 1)
