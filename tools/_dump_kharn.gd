extends SceneTree
func _gl(root: Node3D, n: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var c: Node = n
	while c != null and c != root:
		t = (c as Node3D).transform * t
		c = c.get_parent()
	return t
func _initialize() -> void:
	var dir := DirAccess.open("res://assets/kharn/models")
	var out := {}
	for f in dir.get_files():
		if not f.ends_with(".gltf"): continue
		var ps: PackedScene = load("res://assets/kharn/models/" + f)
		var inst := ps.instantiate() as Node3D
		var id := f.trim_prefix("kharn_").trim_suffix(".gltf")
		var d := {"tur": null, "muz": [], "door": [], "rotor": [], "arm": [], "conv": []}
		var mn := Vector3(1e9, 1e9, 1e9)
		var mx := -mn
		for n in inst.find_children("*", "Node3D", true, false):
			var nm := String(n.name)
			var t := _gl(inst, n as Node3D)
			if n is MeshInstance3D:
				var bb := (n as MeshInstance3D).get_aabb()
				for i in 8:
					var p := t * bb.get_endpoint(i)
					mn = mn.min(p)
					mx = mx.max(p)
			if nm.begins_with("TurretYaw") and not nm.ends_with("Geometry") and d["tur"] == null:
				d["tur"] = [snappedf(t.origin.x, 0.001), snappedf(t.origin.y, 0.001), snappedf(t.origin.z, 0.001)]
			elif nm.begins_with("Muzzle"):
				d["muz"].append([snappedf(t.origin.x, 0.001), snappedf(t.origin.y, 0.001), snappedf(t.origin.z, 0.001)])
			elif nm.begins_with("Door_"):
				if not nm.ends_with("Geometry"):
					d["door"].append([nm, snappedf(t.origin.x, 0.001), snappedf(t.origin.y, 0.001), snappedf(t.origin.z, 0.001)])
			elif nm.begins_with("Rotor") or nm.begins_with("TailRotor"):
				if not nm.ends_with("Geometry"):
					var ch := n.find_child("*Geometry", false, false)
					var sz := Vector3.ZERO
					if ch is MeshInstance3D: sz = (ch as MeshInstance3D).get_aabb().size
					d["rotor"].append([nm, snappedf(t.origin.x, 0.001), snappedf(t.origin.y, 0.001), snappedf(t.origin.z, 0.001), snappedf(sz.x, 0.001), snappedf(sz.y, 0.001), snappedf(sz.z, 0.001)])
			elif (nm.begins_with("Arm") or nm.begins_with("Conveyor")) and not nm.ends_with("Geometry"):
				d["arm"].append([nm, snappedf(t.origin.x, 0.001), snappedf(t.origin.y, 0.001), snappedf(t.origin.z, 0.001)])
		d["aabb"] = [snappedf(mn.x, 0.01), snappedf(mn.y, 0.01), snappedf(mn.z, 0.01), snappedf(mx.x, 0.01), snappedf(mx.y, 0.01), snappedf(mx.z, 0.01)]
		out[id] = d
		inst.free()
	var fa := FileAccess.open("/tmp/kharn_dump.json", FileAccess.WRITE)
	fa.store_string(JSON.stringify(out))
	fa.close()
	quit()
