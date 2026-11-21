extends SceneTree

func _initialize() -> void:
 var s := GameState.new(4)
 s.cities = [{"name":"A","x":0,"y":0,"population":1000,"completed":{}},{"name":"B","x":3,"y":0,"population":1000,"completed":{}},{"name":"C","x":1,"y":0,"population":1000,"completed":{}}]
 var entry: Dictionary = {"id":1,"path":[[0,0],[1,0]],"type":0,"length":1.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 var main: Dictionary = {"id":2,"path":[[1,0],[2,0],[3,0]],"type":0,"length":2.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 var detour: Dictionary = {"id":3,"path":[[1,0],[1,1],[2,1],[3,1],[3,0]],"type":0,"length":4.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 s.roads = [entry,main,detour]
 s.spawn_clock = -1000.0
 assert(s._start_trip(0,1))
 assert(s._start_trip(2,1))
 assert(int(s.vehicles[0].route[1].road)==2)
 assert(int(s.vehicles[1].route[0].road)==2)
 assert(s.set_manual_closed(2,true))
 assert(RoadNetwork.road_closed(main) and s.route_cache.is_empty())
 var selected: Array = RoadNetwork.route(s.roads,Vector2i(0,0),Vector2i(3,0))
 assert(selected.any(func(edge: Dictionary) -> bool: return int(edge.road)==3))
 assert(not selected.any(func(edge: Dictionary) -> bool: return int(edge.road)==2))
 var restored: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(s.data())))
 assert(bool(restored.roads[1].manual_closed))
 for i: int in range(100): restored.step(0.25)
 assert(restored.completed==2 and restored.interrupted==0)
 assert(restored.set_manual_closed(2,false))
 assert(not RoadNetwork.road_closed(restored.roads[1]))
 assert(not RoadNetwork.route(restored.roads,Vector2i(1,0),Vector2i(3,0)).is_empty())
 restored.roads[1].work = 4.0
 assert(restored.set_manual_closed(2,true) and restored.set_manual_closed(2,false))
 assert(RoadNetwork.road_closed(restored.roads[1]))
 assert(RoadNetwork.closure_reasons(restored.roads[1],false).size()==1)
 restored.roads[1].work = 0.0
 restored.roads[1].event_closures = 1
 assert(restored.set_manual_closed(2,true) and restored.set_manual_closed(2,false))
 assert(RoadNetwork.road_closed(restored.roads[1]))
 assert(not restored.set_manual_closed(999,false))
 print("MANUAL CLOSURE OK: desvío, salida, guardado y reapertura segura")
 quit()
