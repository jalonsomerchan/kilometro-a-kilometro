extends SceneTree

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.state = GameState.new(1)
 game.screen = "game"
 var left := InputEventJoypadButton.new()
 left.button_index = JOY_BUTTON_LEFT_SHOULDER
 left.pressed = true
 var right := InputEventJoypadButton.new()
 right.button_index = JOY_BUTTON_RIGHT_SHOULDER
 right.pressed = true
 game._input(left)
 assert(game.selected_type==0 and game.tool=="Construir")
 game._input(right)
 assert(game.selected_type==0 and game.tool=="Señalar")
 left.pressed = false
 right.pressed = false
 game._input(left)
 game._input(right)
 assert(game.selected_type==0 and game.tool=="Señalar")
 right.pressed = true
 game._input(right)
 right.pressed = false
 game._input(right)
 assert(game.selected_type==1)
 print("CONTROLLER OK: LB+RB y pulsación individual")
 quit()
