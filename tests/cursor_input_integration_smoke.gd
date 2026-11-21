extends SceneTree

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.state = GameState.new(1)
 game.simulation_speed = 0
 game.cursor = Vector2i.ZERO
 game._close_panel()
 await process_frame
 var down := InputEventJoypadButton.new()
 down.button_index = JOY_BUTTON_DPAD_DOWN
 down.pressed = true
 root.push_input(down)
 game._process(0.016)
 assert(game.cursor==Vector2i(0,1), "La cruceta debe llegar al mapa a través del sistema de entrada")
 game._process(0.45)
 assert(game.cursor==Vector2i(0,2), "Mantener la cruceta debe repetir")
 down.pressed = false
 root.push_input(down)
 game._process(0.45)
 assert(game.cursor==Vector2i(0,2), "Soltar debe detener la repetición")
 var key := InputEventKey.new()
 key.physical_keycode = KEY_LEFT
 key.pressed = true
 root.push_input(key)
 game._process(0.016)
 assert(game.cursor==Vector2i(-1,2), "La flecha debe mover una casilla")
 game._process(0.45)
 assert(game.cursor==Vector2i(-2,2), "Mantener una tecla debe repetir")
 key.pressed = false
 root.push_input(key)
 game._process(0.45)
 assert(game.cursor==Vector2i(-2,2))
 var axis := InputEventJoypadMotion.new()
 axis.axis = JOY_AXIS_LEFT_X
 axis.axis_value = 0.8
 root.push_input(axis)
 game._process(0.016)
 assert(game.cursor==Vector2i(-1,2), "El stick debe mover una casilla")
 game._process(0.45)
 assert(game.cursor==Vector2i(0,2), "Mantener el stick debe repetir")
 axis.axis_value = 0.0
 root.push_input(axis)
 game._process(0.45)
 assert(game.cursor==Vector2i(0,2))
 print("CURSOR INPUT OK: eventos reales con partida en pausa")
 quit()
