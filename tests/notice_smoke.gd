extends SceneTree

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.state = GameState.new(1)
 game.state.roads = [{"id":7,"path":[[10,20],[11,20],[12,20]],"type":0,"length":2.0,"water":0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}]
 game.screen = "game"
 var event: Dictionary = GameEvents.start(game.state,"snow",7,30.0)
 game._notify(game.state.latest_notice,game.state.notice_road)
 var go := InputEventJoypadButton.new()
 go.button_index = JOY_BUTTON_PADDLE1
 go.pressed = true
 assert(InputMap.event_is_action(go,"notice_go"))
 game._unhandled_input(go)
 assert(game.cursor == Vector2i(11,20) and game.camera_cell == Vector2(11,20))
 assert(game.notice_time == 0.0 and game.state.events.has(event))
 game._notify(game.state.latest_notice,game.state.notice_road)
 var dismiss := InputEventJoypadButton.new()
 dismiss.button_index = JOY_BUTTON_PADDLE2
 dismiss.pressed = true
 assert(InputMap.event_is_action(dismiss,"notice_dismiss"))
 game._unhandled_input(dismiss)
 assert(game.notice_time == 0.0 and game.state.events.has(event))
 game._notify("Cola en el cruce",7,[12,20])
 game._unhandled_input(go)
 assert(game.cursor == Vector2i(12,20), "Debe saltar al cruce, no al centro del tramo")
 game._notify("Cuota pagada")
 var old: Vector2i = game.cursor
 game._unhandled_input(go)
 assert(game.cursor == old and game.notice_time > 0.0)
 var key := InputEventKey.new()
 key.physical_keycode = KEY_F7
 key.pressed = true
 assert(InputMap.event_is_action(key,"notice_dismiss"))
 game._unhandled_input(key)
 assert(game.notice_time == 0.0)
 print("NOTICES OK: R4, L4, teclado y evento conservado")
 quit()
