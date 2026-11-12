extends SceneTree
## Compare le cuisson des sprites avec 1 ou 2 attentes d'image (env WAITS).
var vp: SubViewport
func _initialize() -> void:
	var bank := SpriteBank.new()
	root.add_child(bank)
	bank.setup(null, ["solis"])
	var t0 := Time.get_ticks_msec()
	await bank.finished
	print("durée ms:", Time.get_ticks_msec() - t0, " total:", bank.total)
	var h := 0
	for k in bank._tex:
		for tx in bank._tex[k]:
			h = hash([h, tx.get_image().get_data().get_string_from_utf8().length(), hash(tx.get_image().get_data())])
	print("hash:", h)
	quit()
