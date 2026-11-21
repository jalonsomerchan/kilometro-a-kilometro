extends SceneTree

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.state = GameState.new(1)
 game.screen = "game"
 var right := InputEventJoypadButton.new()
 right.button_index = JOY_BUTTON_PADDLE3
 right.pressed = true
 assert(InputMap.event_is_action(right,"tool_action"))
 game._unhandled_input(right)
 assert(game.tool=="Señalar" and game.selected_type==0)
 var left := InputEventJoypadButton.new()
 left.button_index = JOY_BUTTON_PADDLE4
 left.pressed = true
 assert(InputMap.event_is_action(left,"tool_previous"))
 game._unhandled_input(left)
 assert(game.tool=="Construir" and game.selected_type==0)
 game._unhandled_input(left)
 assert(game.tool=="Mejorar")
 var previous := InputEventKey.new()
 previous.physical_keycode = KEY_F8
 previous.pressed = true
 assert(InputMap.event_is_action(previous,"tool_previous"))
 print("PADDLES OK: R5 avanza, L5 retrocede y F8 alternativo")
 quit()
