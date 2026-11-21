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
 game.simulation_speed = 0
 var motion: CursorMotion = game.cursor_motion
 var right := InputEventKey.new()
 right.physical_keycode = KEY_RIGHT
 right.pressed = true
 assert(motion.handle_event(right))
 assert(motion.advance(0.016)==Vector2i.RIGHT)
 for i: int in range(20): assert(motion.advance(0.016)==Vector2i.ZERO)
 assert(motion.advance(0.11)==Vector2i.RIGHT)
 right.echo = true
 assert(motion.handle_event(right))
 assert(motion.advance(0.05)==Vector2i.ZERO)
 assert(motion.advance(0.14)==Vector2i.RIGHT)
 right.echo = false
 right.pressed = false
 assert(motion.handle_event(right))
 assert(motion.advance(1.0)==Vector2i.ZERO)
 # Even press and release received between two frames make exactly one step.
 right.pressed = true
 motion.handle_event(right)
 right.pressed = false
 motion.handle_event(right)
 assert(motion.advance(0.016)==Vector2i.RIGHT)
 assert(motion.advance(0.016)==Vector2i.ZERO)
 var dpad := InputEventJoypadButton.new()
 dpad.button_index = JOY_BUTTON_DPAD_UP
 dpad.pressed = true
 assert(motion.handle_event(dpad))
 assert(motion.advance(0.016)==Vector2i.UP)
 assert(motion.advance(0.43)==Vector2i.UP)
 dpad.pressed = false
 assert(motion.handle_event(dpad))
 assert(motion.advance(1.0)==Vector2i.ZERO)
 # A brief stick flick received entirely within a frame still moves once.
 var flick := InputEventJoypadMotion.new()
 flick.axis = JOY_AXIS_LEFT_X
 flick.axis_value = 0.8
 motion.handle_event(flick)
 flick.axis_value = 0.0
 motion.handle_event(flick)
 assert(motion.advance(0.016)==Vector2i.RIGHT)
 assert(motion.advance(0.016)==Vector2i.ZERO)
 var x := InputEventJoypadMotion.new()
 x.axis = JOY_AXIS_LEFT_X
 x.axis_value = 0.30
 motion.handle_event(x)
 assert(motion.advance(0.016)==Vector2i.ZERO)
 x.axis_value = 0.72
 motion.handle_event(x)
 assert(motion.advance(0.016)==Vector2i.RIGHT)
 var y := InputEventJoypadMotion.new()
 y.axis = JOY_AXIS_LEFT_Y
 y.axis_value = 0.80
 motion.handle_event(y)
 assert(motion.advance(0.016)==Vector2i.ZERO, "Una pequeña deriva perpendicular no debe mover el cursor")
 assert(motion.advance(0.42)==Vector2i.RIGHT, "Mantener el stick debe repetir")
 y.axis_value = 1.0
 motion.handle_event(y)
 assert(motion.advance(0.016)==Vector2i.DOWN)
 x.axis_value = 0.0
 y.axis_value = 0.0
 motion.handle_event(x)
 motion.handle_event(y)
 assert(motion.advance(1.0)==Vector2i.ZERO)
 # A long frame yields only one move and does not leave a repeat backlog.
 right.pressed = true
 motion.handle_event(right)
 assert(motion.advance(0.016)==Vector2i.RIGHT)
 assert(motion.advance(2.0)==Vector2i.RIGHT)
 assert(motion.advance(0.001)==Vector2i.ZERO)
 motion.reset()
 assert(motion.advance(1.0)==Vector2i.ZERO)
 # Map integration: movement works while paused and resets when a menu opens.
 game.cursor = Vector2i.ZERO
 game._unhandled_input(right)
 game._process(0.016)
 assert(game.cursor==Vector2i.RIGHT)
 game._process(0.45)
 assert(game.cursor==Vector2i(2,0))
 game._game_menu()
 game._close_panel()
 game._process(1.0)
 assert(game.cursor==Vector2i(2,0))
 game._unhandled_input(right)
 game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 game._process(1.0)
 assert(game.cursor==Vector2i(2,0), "Perder el foco no debe dejar teclas pulsadas")
 game.cursor = Vector2i.ZERO
 game.camera_cell = Vector2.ZERO
 game._update_camera(1.0)
 assert(game.camera_cell.is_equal_approx(Vector2.ZERO))
 game.cursor = Vector2i(100,0)
 game._update_camera(1.0)
 assert(game.camera_cell.x > 0.0)
 print("CURSOR OK: teclado, cruceta, stick, repetición, pausa y cámara")
 quit()
