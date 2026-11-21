extends SceneTree

func _initialize() -> void:
 var direct: Dictionary = {"id":1,"path":[[0,0],[1,0],[2,0],[3,0],[4,0]],"type":0,"length":4.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 var longer: Dictionary = {"id":2,"path":[[0,0],[0,1],[1,1],[2,1],[3,1],[4,1],[4,0]],"type":2,"length":6.0,"work":0.0,"condition":100.0,"speed_limit":60.0,"trips":0}
 var chosen: Array = RoadNetwork.route([direct,longer],Vector2i(0,0),Vector2i(4,0))
 assert(int(chosen[0].road)==2, "Una carretera más larga pero más rápida debe ser preferida")
 longer.speed_limit = 25.0
 chosen = RoadNetwork.route([direct,longer],Vector2i(0,0),Vector2i(4,0))
 assert(int(chosen[0].road)==1)
 chosen = RoadNetwork.route([direct,longer],Vector2i(0,0),Vector2i(4,0),-1,{1:2.0})
 assert(int(chosen[0].road)==2, "El tráfico debe afectar al tiempo estimado")
 var under: Dictionary = {"id":3,"path":[[2,-1],[2,0],[2,1]],"type":0,"work":0.0,"condition":100.0,"speed_limit":25.0,"level":1}
 assert(RoadNetwork.route([direct,under],Vector2i(2,0),Vector2i(2,1),-1,{},1,2).is_empty(), "No se puede cambiar de nivel en una reevaluación")
 var entry: Dictionary = {"id":4,"path":[[-1,0],[0,0]],"type":0,"length":1.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 var state := GameState.new(1)
 state.cities = [{"name":"A","x":-1,"y":0,"population":1000,"completed":{}},{"name":"B","x":4,"y":0,"population":1000,"completed":{}}]
 state.roads = [entry,direct,longer]
 var original: Array = RoadNetwork.route(state.roads,Vector2i(-1,0),Vector2i(4,0))
 var vehicle: Dictionary = {"route":original,"route_index":0,"segment_progress":0.9,"origin":0,"destination":1,"direct_distance":5.0,"travel_time":10.0,"last_reroute":0.0}
 state.elapsed = 11.0
 state.traffic_load = {1:2.0}
 state.reroute_budget = 2
 assert(not state._advance_route_vehicle(vehicle,0.25))
 assert(int(vehicle.route[0].road)==2, "El vehículo debe reevaluar en el cruce")
 print("FASTEST ROUTE OK: velocidad, atasco, niveles y reevaluación")
 quit()
