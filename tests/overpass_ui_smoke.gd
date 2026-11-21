extends SceneTree

class FlatWorld extends WorldGenerator:
 func terrain(_p: Vector2i) -> String: return "pradera"

func _initialize() -> void:
 call_deferred("run_test")

func run_test() -> void:
 var game: Node = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.state = GameState.new(9)
 game.state.world = FlatWorld.new(9)
 game.state.roads = [{"id":1,"path":[[5,-2],[5,-1],[5,0],[5,1],[5,2]],"type":0,"length":4.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}]
 game.state.next_id = 2
 game.screen = "game"
 game.start = Vector2i(0,0)
 game.cursor = Vector2i(10,0)
 game.drawing = true
 game._refresh_proposal()
 game.tool = "Construir puente"
 game._refresh_proposal()
 assert(game.proposal.has("overpasses") and game.proposal.overpasses.size()==1)
 game._accept_map()
 assert(game.screen=="review")
 var details: String = ""
 var confirm: Button
 for child: Node in game.column.get_children():
  if child is Label: details += child.text
  if child is Button and child.text=="Confirmar obra": confirm=child
 assert(details.contains("Rampas") and details.contains("vías inferiores siguen abiertas"))
 assert(confirm != null)
 var cost: float = game.state.price(game.proposal,0)
 confirm.pressed.emit()
 assert(game.state.roads.size()==2 and game.state.roads[1].overpasses.size()==1)
 assert(is_equal_approx(game.state.money,Balance.INITIAL_MONEY-cost))
 var diagonal_path: Array[Vector2i] = [Vector2i(0,1),Vector2i(1,2),Vector2i(2,3),Vector2i(3,4),Vector2i(4,5),Vector2i(5,6)]
 var lower: Dictionary = {"id":20,"path":[[2,4],[3,3]],"type":0,"work":0.0,"condition":100.0,"speed_limit":25.0}
 var diagonal: Dictionary = RoadPlanner.add_crossings(game.state.world,RoadPlanner._describe(game.state.world,diagonal_path),[lower],true,0)
 assert(not diagonal.has("error"))
 var upper: Dictionary = {"id":21,"path":[[0,1],[1,2],[2,3],[3,4],[4,5],[5,6]],"type":0,"work":0.0,"condition":100.0,"speed_limit":25.0,"raised_indices":diagonal.raised_indices,"overpasses":diagonal.overpasses}
 game.state.roads = [lower,upper]
 var anchors: Dictionary = game._geometry_anchors()
 assert(RoadGeometry.point(lower.path,0,0.5,anchors).is_equal_approx(RoadGeometry.point(upper.path,2,0.5,anchors)))
 print("OVERPASS UI OK: selección, presupuesto y construcción")
 quit()
