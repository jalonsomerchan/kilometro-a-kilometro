extends SceneTree

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var path: String = "/tmp/kaa-settings-test-%d.cfg" % OS.get_process_id()
 var settings: Dictionary = {"grid":false,"fullscreen":false,"ui_scale":1.2,"keys":{"move_up":KEY_T}}
 assert(SettingsStore.write_settings(settings,path)==OK)
 var restored: Dictionary = SettingsStore.read_settings(path)
 assert(not restored.grid and is_equal_approx(restored.ui_scale,1.2) and int(restored.keys.move_up)==KEY_T)
 DirAccess.remove_absolute(path)
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.settings.keys = {"move_up":KEY_T}
 game._configure_input()
 var key := InputEventKey.new()
 key.physical_keycode = KEY_T
 assert(InputMap.event_is_action(key,"move_up"))
 assert(InputMap.event_is_action(key,"ui_up"))
 game._options()
 game._controls_menu()
 assert(game.screen=="controls")
 game.settings.keys = {}
 game._configure_input()
 var w := InputEventKey.new()
 w.physical_keycode = KEY_W
 assert(InputMap.event_is_action(w,"move_up") and InputMap.event_is_action(w,"ui_up"))
 print("SETTINGS OK: archivo temporal, reasignación, navegación y valores por defecto")
 quit()
