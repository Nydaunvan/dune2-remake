extends SceneTree
## Logique de la mise à jour : comparaison de versions et lecture d'une release GitHub.
func _initialize() -> void:
	var ok := true
	var cases := [["0.23", "0.22", true], ["0.22", "0.22", false], ["0.9", "0.22", false], ["0.100", "0.99", true], ["v1.0", "0.99", true], ["0.22.1", "0.22", true], ["0.22", "0.22.0", false], ["0.21", "0.22", false]]
	for c in cases:
		var r := Updater.is_newer(c[0], c[1])
		if r != c[2]:
			ok = false
			print("ÉCHEC is_newer(%s, %s) = %s" % [c[0], c[1], r])
	var rel := {"tag_name": "v0.23", "draft": false, "prerelease": false, "body": "Notes",
			"assets": [{"name": "TheBuildingOfADynasty.exe", "browser_download_url": "x", "size": 1},
			{"name": "TheBuildingOfADynasty-Setup.exe", "browser_download_url": "https://example/Setup.exe", "size": 123}]}
	var i := Updater.parse_release(rel)
	if i.get("version", "") != "0.23" or i.get("url", "") != "https://example/Setup.exe" or i.get("size", 0) != 123:
		ok = false
		print("ÉCHEC parse_release: ", i)
	rel["prerelease"] = true
	if not Updater.parse_release(rel).is_empty():
		ok = false
		print("ÉCHEC prerelease")
	rel["prerelease"] = false
	rel["assets"] = [{"name": "autre.zip", "browser_download_url": "x", "size": 1}]
	if not Updater.parse_release(rel).is_empty():
		ok = false
		print("ÉCHEC sans installateur")
	print("Updater: ", "OK" if ok else "ÉCHEC", " version courante ", ChangelogData.current())
	quit(0 if ok else 1)
