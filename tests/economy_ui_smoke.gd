extends SceneTree

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.state = GameState.new(1)
 game.state.discover(Vector2i.ZERO)
 game._economy_menu()
 assert(game.screen == "economy")
 game._offer_contract()
 assert(game.state.contract.get("status","") == "offered")
 game.state.accept_contract()
 game._economy_menu()
 assert(game.screen == "economy")
 print("ECONOMY UI OK: balance y contrato")
 quit()
