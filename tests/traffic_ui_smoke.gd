extends SceneTree

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.state = GameState.new(10)
 game.state.discover(Vector2i.ZERO)
 game.state.roads = [{"id":1,"path":[[2,4],[3,4]],"type":0,"length":1.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}]
 game.cursor = Vector2i(2,4)
 game.state._update_traffic()
 game._traffic_summary()
 assert(game.screen == "traffic_summary")
 game._inspector()
 assert(game.screen == "inspector")
 game.view_mode = "tráfico"
 assert(game._road_color(game.state.roads[0]) == Color("69b78e"))
 print("TRAFFIC UI OK: balance, inspector y vista")
 quit()
