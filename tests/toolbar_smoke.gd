extends SceneTree

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.state = GameState.new(1)
 game.screen = "game"
 var shoulder := InputEventJoypadButton.new()
 shoulder.button_index = JOY_BUTTON_RIGHT_SHOULDER
 shoulder.pressed = true
 game._input(shoulder)
 assert(game.tool == "Construir puente")
 shoulder.pressed = false
 game._input(shoulder)
 assert(game.tool == "Construir puente")
 shoulder.button_index = JOY_BUTTON_LEFT_SHOULDER
 shoulder.pressed = true
 game._input(shoulder)
 assert(game.tool == "Construir")
 game._tool_options()
 assert(game.screen == "action")
 game._close_panel()
 game.tool = "Construir rotonda"
 game._accept_map()
 assert(game.screen == "action")
 print("TOOLBAR OK")
 quit()
