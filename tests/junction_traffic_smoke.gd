extends SceneTree

func make_state(mode: String) -> GameState:
 var s := GameState.new(9)
 s.cities = [{"name":"A","x":9,"y":5,"population":1000,"completed":{}},{"name":"B","x":11,"y":5,"population":1000,"completed":{}}]
 var horizontal: Dictionary = {"id":1,"path":[[9,5],[10,5],[11,5]],"type":0,"length":2.0,"water":0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 var vertical: Dictionary = {"id":2,"path":[[10,4],[10,5],[10,6]],"type":0,"length":2.0,"water":0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 if mode == "signals": horizontal.signals = [{"index":1,"direction":1,"type":"stop"}]
 s.roads = [horizontal,vertical]
 if mode == "roundabout": s.roundabouts["10,5"] = {"x":10,"y":5,"work":0.0,"road_id":1}
 s.spawn_clock = -10000.0
 var route: Array = RoadNetwork.route(s.roads,Vector2i(9,5),Vector2i(11,5))
 for i: int in range(12):
  s.vehicles.append({"route":route.duplicate(true),"route_index":0,"segment_progress":0.99,"origin":0,"destination":1,"direct_distance":2.0,"travel_time":0.0,"last_reroute":0.0})
 return s

func passed(state: GameState) -> int:
 var result: int = state.completed
 for vehicle: Dictionary in state.vehicles:
  if int(vehicle.route_index) >= 1 and not vehicle.has("signal_pending"): result += 1
 return result

func _initialize() -> void:
 var plain := make_state("plain")
 var signs := make_state("signals")
 var circle := make_state("roundabout")
 for i: int in range(24):
  plain.step(0.25)
  signs.step(0.25)
  circle.step(0.25)
 print("pasos ",passed(plain)," ",passed(signs)," ",passed(circle)," colas ",plain.junction_queue_counts," ",signs.junction_queue_counts," ",circle.junction_queue_counts)
 assert(passed(signs) > passed(plain), "Las señales deben mejorar la capacidad con demanda sostenida")
 assert(passed(circle) > passed(signs), "La rotonda debe admitir más tráfico")
 assert(plain.congestion_fines > 0.0 and plain.junction_fines > 0.0 and plain.junction_queue_counts.size() > 0)
 assert(plain.notice_point == [10,5])
 var s := make_state("plain")
 s.vehicles.clear()
 var before: float = s.money
 assert(s.build_roundabout(Vector2i(10,5)))
 assert(is_equal_approx(s.money,before-Balance.ROUNDABOUT_COST))
 assert(not s.build_roundabout(Vector2i(10,5)))
 var restored: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(s.data())))
 assert(float(restored.roundabouts["10,5"].work)==Balance.ROUNDABOUT_WORK_SECONDS)
 for i: int in range(48): restored.step(0.25)
 assert(float(restored.roundabouts["10,5"].work)==0.0)
 assert(is_equal_approx(restored._junction_headway("10,5"),Balance.JUNCTION_ROUNDABOUT_HEADWAY))
 restored.remove_road(restored.roads[0])
 assert(not restored.roundabouts.has("10,5"))
 print("JUNCTION OK: cola sin señal %d, señales %d, rotonda %d" % [passed(plain),passed(signs),passed(circle)])
 quit()
