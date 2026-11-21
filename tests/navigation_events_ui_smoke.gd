extends SceneTree

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 var options_button: Button
 for child: Node in game.column.get_children():
  if child is Button and child.text == "Opciones y controles": options_button = child
 assert(options_button != null)
 options_button.grab_focus()
 assert(str(game.focus_memory.get("title","")) == "Opciones y controles")
 game._options()
 game._back()
 await process_frame
 assert(root.gui_get_focus_owner() != null)
 assert(root.gui_get_focus_owner().text == "Opciones y controles")
 game.state = GameState.new(1)
 game.state.roads = [{"id":1,"path":[[0,0],[1,0]],"type":0,"length":1.0,"water":0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}]
 GameEvents.start(game.state,"snow",1,20.0)
 game._events_menu()
 assert(game.screen == "events")
 var found_clear: bool = false
 for child: Node in game.column.get_children():
  if child is Button and child.text.begins_with("Despejar tramo 1"): found_clear=true
 assert(found_clear)
 print("NAVIGATION OK: foco, opciones y aviso de evento")
 quit()
