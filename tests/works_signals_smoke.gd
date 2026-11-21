extends SceneTree

func _initialize() -> void:
 var state := GameState.new(23)
 state.cities = [{"name":"A","x":0,"y":0,"population":1000,"completed":{}},{"name":"B","x":2,"y":0,"population":1000,"completed":{}}]
 var road: Dictionary = {"id":1,"path":[[0,0],[1,0],[2,0]],"type":0,"length":2.0,"water":0,"work":0.0,"condition":90.0,"speed_limit":25.0,"trips":0,"signals":[{"index":1,"direction":1,"type":"stop"}]}
 var alternate: Dictionary = {"id":2,"path":[[0,0],[0,1],[1,1],[2,1],[2,0]],"type":0,"length":4.0,"water":0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 state.roads = [road,alternate]
 state.spawn_clock = -1000.0
 assert(state._start_trip(0,1))
 for i: int in range(5): state.step(0.25)
 assert(state.vehicles.size()==1 and state.vehicles[0].has("signal_pending"))
 var held: float = float(state.vehicles[0].segment_progress)
 state.step(0.25)
 assert(is_equal_approx(held,float(state.vehicles[0].segment_progress)))
 var restored: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(state.data())))
 assert(restored.vehicles[0].has("signal_pending"))
 for i: int in range(16): restored.step(0.25)
 assert(restored.completed==1)
 state.vehicles.clear()
 var old_money: float = state.money
 state.schedule_work(road,"repair",0,200.0,15.0,state.elapsed+1.0)
 alternate.work = 100.0
 for i: int in range(4): state.step(0.25)
 assert(road.scheduled_work.status=="blocked" and float(road.work)==0.0)
 assert(is_equal_approx(state.money,old_money))
 var restored_job: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(state.data())))
 assert(restored_job.roads[0].scheduled_work.status=="blocked")
 var cross_road: Dictionary = {"id":3,"path":[[1,-1],[1,0],[1,1]],"type":0,"length":2.0,"water":0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 state.roads.append(cross_road)
 var waiting: Dictionary = {"route":[],"route_index":0,"segment_progress":0.0,"signal_pending":{"key":"1,0","ready_at":0.0,"level":0}}
 var priority: Dictionary = {"route":[{"road":3,"from_index":0,"to_index":1}],"route_index":0,"segment_progress":0.9}
 state.vehicles = [waiting,priority]
 assert(state._priority_approaching("1,0",waiting))
 priority.signal_pending = {"key":"1,0","ready_at":0.0}
 assert(not state._priority_approaching("1,0",waiting))
 var w := WorldGenerator.new(23)
 var via: Vector2i = Vector2i(6,5)
 var proposal: Dictionary = RoadPlanner.plan_via(w,Vector2i(2,4),via,Vector2i(10,5))
 assert(proposal.has("path") and proposal.path.has(via))
 print("WORKS OK: STOP, espera guardada, aislamiento y punto intermedio")
 quit()
