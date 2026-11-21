extends SceneTree

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 var down := InputEventKey.new()
 down.physical_keycode = KEY_DOWN
 down.pressed = true
 assert(not game._limit_menu_navigation(down,1000))
 assert(game._limit_menu_navigation(down,1050))
 assert(not game._limit_menu_navigation(down,1200))
 down.pressed = false
 assert(not game._limit_menu_navigation(down,1210))
 var stick := InputEventJoypadMotion.new()
 stick.axis = JOY_AXIS_LEFT_Y
 stick.axis_value = 1.0
 assert(game._limit_menu_navigation(stick,1250))
 assert(not game._limit_menu_navigation(stick,1400))
 print("MENU NAVIGATION SMOKE OK")
 quit()
