extends SceneTree

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.state = GameState.new(9)
 game.state.roads = [
  {"id":1,"path":[[9,5],[10,5],[11,5]],"type":0,"length":2.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0},
  {"id":2,"path":[[10,4],[10,5],[10,6]],"type":0,"length":2.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 ]
 game.cursor = Vector2i(10,5)
 game.tool = "Señalar"
 game._road_action()
 var button: Button
 for child: Node in game.column.get_children():
  if child is Button and child.text == "Construir rotonda": button = child
 assert(button != null)
 button.pressed.emit()
 var confirm: Button
 for child: Node in game.column.get_children():
  if child is Button and child.text == "Confirmar construcción": confirm = child
 assert(confirm != null)
 confirm.pressed.emit()
 assert(game.state.roundabouts.has("10,5"))
 assert(game.state.money == Balance.INITIAL_MONEY-Balance.ROUNDABOUT_COST)
 print("ROUNDABOUT UI OK: señalizar, presupuesto y construcción")
 quit()
