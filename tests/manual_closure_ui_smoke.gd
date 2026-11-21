extends SceneTree

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.state = GameState.new(4)
 game.state.cities = [{"name":"A","x":0,"y":0,"population":1000,"completed":{}},{"name":"B","x":2,"y":0,"population":1000,"completed":{}}]
 game.state.roads = [{"id":1,"road_name":"C1","path":[[0,0],[1,0],[2,0]],"type":0,"length":2.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}]
 game.cursor = Vector2i(1,0)
 game.screen = "game"
 game._game_menu()
 var choose: Button
 for child: Node in game.column.get_children():
  if child is Button and child.text == "Cerrar/Abrir": choose = child
 assert(choose != null)
 choose.pressed.emit()
 assert(game.tool=="Cerrar/Abrir" and game.screen=="game")
 game._accept_map()
 var text: String = ""
 var close: Button
 var detour: Button
 for child: Node in game.column.get_children():
  if child is Label: text += child.text
  if child is Button and child.text=="Cerrar y asumir aislamiento": close=child
  if child is Button and child.text=="Preparar desvío": detour=child
 assert(text.contains("A ↔ B") and close != null and detour != null)
 detour.pressed.emit()
 assert(not bool(game.state.roads[0].get("manual_closed",false)))
 game._accept_map()
 for child: Node in game.column.get_children():
  if child is Button and child.text=="Cerrar y asumir aislamiento": close=child
 close.pressed.emit()
 assert(bool(game.state.roads[0].manual_closed))
 game._inspector()
 var open: Button
 text = ""
 for child: Node in game.column.get_children():
  if child is Label: text += child.text
  if child is Button and child.text=="Abrir carretera": open=child
 assert(open != null and text.contains("cierre manual"))
 open.pressed.emit()
 var confirm: Button
 for child: Node in game.column.get_children():
  if child is Button and child.text=="Confirmar apertura": confirm=child
 assert(confirm != null)
 confirm.pressed.emit()
 assert(not RoadNetwork.road_closed(game.state.roads[0]))
 print("MANUAL CLOSURE UI OK: herramienta, aislamiento, inspector y apertura")
 quit()
