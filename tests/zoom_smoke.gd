extends SceneTree

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.state = GameState.new(1)
 game.state.discover(Vector2i.ZERO)
 game.screen = "game"
 var key := InputEventKey.new()
 key.keycode = KEY_PLUS
 key.pressed = true
 Input.parse_input_event(key)
 await process_frame
 game._process(0.25)
 assert(game.zoom > 1.0, "El signo + debe acercar")
 key.pressed = false
 Input.parse_input_event(key)
 var previous: float = game.zoom
 var minus := InputEventKey.new()
 minus.keycode = KEY_MINUS
 minus.pressed = true
 Input.parse_input_event(minus)
 await process_frame
 game._process(0.25)
 assert(game.zoom < previous, "El signo - debe alejar")
 minus.pressed = false
 Input.parse_input_event(minus)
 print("ZOOM OK: + y − con el teclado lógico")
 quit()
