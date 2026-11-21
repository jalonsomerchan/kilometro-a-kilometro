extends SceneTree

func _initialize() -> void:
 var world := WorldGenerator.new(123)
 var path: Array[Vector2i] = [Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4)]
 var lower: Dictionary = {"id":1,"path":[[2,3],[2,4],[2,5]],"type":0,"work":0.0,"condition":100.0,"speed_limit":25.0}
 var proposal: Dictionary = RoadPlanner.add_crossings(world,{"path":path},[lower],true,0)
 assert(not proposal.has("error") and proposal.raised_indices == [2])
 var upper: Dictionary = {"id":2,"path":[[0,4],[1,4],[2,4],[3,4],[4,4]],"type":0,"work":0.0,"condition":100.0,"speed_limit":25.0,"raised_indices":proposal.raised_indices}
 assert(RoadNetwork.route([lower,upper],Vector2i(2,3),Vector2i(4,4)).is_empty())
 upper.raised_indices = []
 assert(not RoadNetwork.route([lower,upper],Vector2i(2,3),Vector2i(4,4)).is_empty())
 var short: Array[Vector2i] = [Vector2i(1,4),Vector2i(2,4),Vector2i(3,4)]
 assert(RoadPlanner.add_crossings(world,{"path":short},[lower],true,0).has("error"))
 print("OVERPASS OK: rampas y separación de niveles")
 quit()
