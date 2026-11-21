extends SceneTree

func _initialize() -> void:
 var s := GameState.new(8)
 s.cities = [{"name":"Oeste","x":9,"y":5,"population":1000,"completed":{}},{"name":"Este","x":11,"y":5,"population":1000,"completed":{}},{"name":"Norte","x":10,"y":4,"population":1000,"completed":{}},{"name":"Sur","x":10,"y":6,"population":1000,"completed":{}}]
 s.roads = [
  {"id":1,"path":[[9,5],[10,5],[11,5]],"type":0,"length":2.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0},
  {"id":2,"path":[[10,4],[10,5],[10,6]],"type":0,"length":2.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 ]
 s.spawn_clock = -10000.0
 var horizontal: Array = RoadNetwork.route(s.roads,Vector2i(9,5),Vector2i(11,5))
 var vertical: Array = RoadNetwork.route(s.roads,Vector2i(10,4),Vector2i(10,6))
 for i: int in range(8):
  var origin: int = 0 if i%2==0 else 2
  s.vehicles.append({"route":(horizontal if i%2==0 else vertical).duplicate(true),"route_index":0,"segment_progress":0.99,"origin":origin,"destination":origin+1,"direct_distance":2.0,"travel_time":0.0,"last_reroute":0.0})
 for i: int in range(8): s.step(0.25)
 var resumed: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(s.data())))
 assert(resumed.junction_queue_serial == s.junction_queue_serial)
 assert(resumed.vehicles.any(func(v: Dictionary) -> bool: return v.has("signal_pending")))
 for i: int in range(100): resumed.step(0.25)
 assert(resumed.completed==8)
 assert(int(resumed.cities[0].completed.get("Este",0))==4)
 assert(int(resumed.cities[2].completed.get("Sur",0))==4)
 print("JUNCTION FAIRNESS OK: dos accesos, cola guardada y sin interbloqueo")
 quit()
