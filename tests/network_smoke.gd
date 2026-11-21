extends SceneTree

func _initialize() -> void:
 var roads: Array = [
  {"id":1,"path":[[0,0],[1,0],[2,0]],"type":0,"work":0.0,"condition":100.0,"speed_limit":25.0},
  {"id":2,"path":[[1,-1],[1,0],[1,1]],"type":0,"work":0.0,"condition":100.0,"speed_limit":25.0}
 ]
 var origin := Vector2i(0,0)
 var destination := Vector2i(1,1)
 var connected: Array = RoadNetwork.route(roads,origin,destination)
 assert(connected.size() == 2, "El cruce a nivel debe conectar ambas vías")
 roads[1]["level"] = 1
 assert(RoadNetwork.route(roads,origin,destination).is_empty(), "Un paso elevado no debe conectar")
 roads[1]["level"] = 0
 roads[1]["work"] = 5.0
 assert(RoadNetwork.route(roads,origin,destination).is_empty(), "Una vía en obras debe estar cerrada")
 print("NETWORK OK: cruce, altura y cierre")
 quit()
