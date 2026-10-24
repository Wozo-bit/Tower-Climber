class_name DlcLoader
extends RefCounted
## Loads DLC content at startup.
##
## 1. Exported builds: every .pck in a "dlc" folder next to the game's .exe is
##    mounted (that's how a store like Steam would install DLC). Only that
##    folder is read, never user:// or save files, so a save can't run code.
## 2. Every res://dlc/<name>/content.gd is loaded and its register() called.
##    That's where a DLC adds routes, endings and other content, e.g.:
##
##        extends RefCounted
##        func register() -> void:
##            RouteLibrary.register_ending({ "id": &"lone_hero", "priority": 20,
##                "title": "...", "text": "...", "if": { "route": &"hero", "flag": &"friend_left" } })
##
## Returns the names of the DLC packs that registered content.

const DLC_RES_DIR := "res://dlc"


static func load_all(res_dir: String = DLC_RES_DIR) -> PackedStringArray:
	if not OS.has_feature("editor"):
		var pck_dir := OS.get_executable_path().get_base_dir().path_join("dlc")
		if DirAccess.dir_exists_absolute(pck_dir):
			for f in DirAccess.get_files_at(pck_dir):
				if f.get_extension() == "pck" and not ProjectSettings.load_resource_pack(pck_dir.path_join(f)):
					push_warning("DLC: couldn't load %s" % f)
	var loaded: PackedStringArray = []
	if not DirAccess.dir_exists_absolute(res_dir):
		return loaded
	var names := DirAccess.get_directories_at(res_dir)
	names.sort()
	for dlc_name in names:
		var path := res_dir.path_join(dlc_name).path_join("content.gd")
		if not ResourceLoader.exists(path):
			continue
		var script: Script = load(path)
		var content = script.new() if script else null
		if content and content.has_method("register"):
			content.register()
			loaded.append(dlc_name)
		else:
			push_warning("DLC: %s has no register()" % path)
	return loaded
