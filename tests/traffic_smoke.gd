extends SceneTree

func _initialize() -> void:
 var direct: Dictionary = {"id":1,"path":[[0,0],[1,0],[2,0],[3,0],[4,0]],"type":0,"length":4.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 var alternative: Dictionary = {"id":2,"path":[[0,0],[0,1],[1,1],[2,1],[3,1],[4,1],[4,0]],"type":0,"length":6.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 var roads: Array = [direct,alternative]
 var normal: Array = RoadNetwork.route(roads,Vector2i(0,0),Vector2i(4,0),-1,{1:0.0,2:0.0})
 var busy: Array = RoadNetwork.route(roads,Vector2i(0,0),Vector2i(4,0),-1,{1:2.0,2:0.0})
 assert(int(normal[0].road)==1, "En condiciones normales debe elegirse la vía directa")
 assert(int(busy[0].road)==2, "La alternativa debe atraer tráfico con la vía directa saturada")
 var disconnected := GameState.new(43)
 disconnected.cities = [{"name":"A","x":0,"y":0,"population":5000,"completed":{}},{"name":"B","x":4,"y":0,"population":5000,"completed":{}}]
 disconnected._generate_demand(10.0)
 assert(disconnected.potential_demand > 0.0 and disconnected.unmet_demand > 0 and disconnected.started_trips == 0)
 disconnected.roads = roads
 disconnected.route_cache.clear()
 disconnected._generate_demand(10.0)
 assert(disconnected.started_trips > 0, "Una conexión debe permitir iniciar la demanda")
 var jam := GameState.new(44)
 jam.cities = disconnected.cities.duplicate(true)
 jam.roads = roads.duplicate(true)
 jam.spawn_clock = -1000.0
 var one_route: Array = RoadNetwork.route(jam.roads,Vector2i(0,0),Vector2i(4,0))
 for i: int in range(12):
  jam.vehicles.append({"route":one_route.duplicate(true),"route_index":0,"segment_progress":0.0,"origin":0,"destination":1,"direct_distance":4.0,"travel_time":0.0})
 jam.step(0.25)
 assert(float(jam.traffic_load[1])>1.0 and jam.congestion_fines>0.0)
 assert(jam.effective_speed(jam.roads[0]) < 25.0)
 jam.route_cache.clear()
 assert(jam._start_trip(0,1) and int(jam.vehicles[-1].route[0].road)==2)
 var state := GameState.new(42)
 state.cities = [{"name":"A","x":0,"y":0,"population":1000,"completed":{}},{"name":"B","x":4,"y":0,"population":1000,"completed":{}}]
 state.roads = roads
 state.traffic_load = {1:2.0}
 var money_before: float = state.money
 state._charge_congestion(4.0)
 assert(is_equal_approx(state.congestion_fines,10.0))
 assert(is_equal_approx(money_before-state.money,10.0))
 state.spawn_clock = -1000.0
 assert(state._start_trip(0,1))
 state.vehicles[0].travel_time = 40.0
 var resumed: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(state.data())))
 assert(is_equal_approx(resumed.congestion_fines,10.0))
 assert(float(resumed.vehicles[0].travel_time)==40.0)
 for i: int in range(80): resumed.step(0.25)
 assert(resumed.completed == 1)
 assert(resumed.late_trips == 1 and resumed.delay_fines > 0.0)
 var after: float = resumed.delay_fines
 for i: int in range(20): resumed.step(0.25)
 assert(is_equal_approx(after,resumed.delay_fines), "No se puede cobrar dos veces el mismo retraso")
 print("TRAFFIC OK: desvío, atascos, retraso y reanudación")
 quit()
