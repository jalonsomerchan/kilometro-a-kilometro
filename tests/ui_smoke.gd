extends SceneTree

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game._new_menu()
 await process_frame
 var begin: Button
 for child: Node in game.column.get_children():
  if child is Button and child.text == "Comenzar": begin = child
 assert(begin != null)
 begin.pressed.emit()
 await process_frame
 assert(game.screen == "game")
 game._accept_map()
 game.cursor = Vector2i(10,5)
 game._refresh_proposal()
 game._accept_map()
 assert(game.screen == "review")
 var confirm: Button
 for child: Node in game.column.get_children():
  if child is Button and child.text == "Confirmar obra": confirm = child
 assert(confirm != null)
 confirm.pressed.emit()
 assert(game.state.roads.size() == 1)
 game._game_menu()
 game._inspector()
 print("UI SMOKE OK: nueva partida, trazado y confirmación")
 quit()
