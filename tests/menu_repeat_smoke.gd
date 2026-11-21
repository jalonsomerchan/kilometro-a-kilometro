extends SceneTree

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 await process_frame
 var first: Control = root.gui_get_focus_owner()
 assert(first != null)
 var down := InputEventJoypadButton.new()
 down.button_index = JOY_BUTTON_DPAD_DOWN
 down.pressed = true
 game._input(down)
 game._advance_menu_navigation(0.016)
 var second: Control = root.gui_get_focus_owner()
 assert(second != null and second != first, "Una pulsación mueve una opción")
 game._advance_menu_navigation(0.20)
 assert(root.gui_get_focus_owner()==second, "No debe saltar inmediatamente")
 game._advance_menu_navigation(0.23)
 var third: Control = root.gui_get_focus_owner()
 assert(third != null and third != second, "Al mantener debe repetir")
 down.pressed = false
 game._input(down)
 game._advance_menu_navigation(1.0)
 assert(root.gui_get_focus_owner()==third, "Al soltar debe parar")
 var axis := InputEventJoypadMotion.new()
 axis.axis = JOY_AXIS_LEFT_Y
 axis.axis_value = -0.8
 game._input(axis)
 game._advance_menu_navigation(0.016)
 assert(root.gui_get_focus_owner()!=third)
 axis.axis_value = 0.0
 game._input(axis)
 game.menu_motion.reset()
 var before_key: Control = root.gui_get_focus_owner()
 var key := InputEventKey.new()
 key.physical_keycode = KEY_DOWN
 key.pressed = true
 root.push_input(key)
 game._advance_menu_navigation(0.016)
 var after_key: Control = root.gui_get_focus_owner()
 assert(after_key == before_key.find_next_valid_focus(), "Una tecla debe avanzar solo un botón")
 key.pressed = false
 root.push_input(key)
 game._advance_menu_navigation(0.016)
 assert(root.gui_get_focus_owner() == after_key)
 print("MENU REPEAT OK: cruceta y stick, un paso y repetición")
 quit()
