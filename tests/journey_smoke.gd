extends SceneTree

func _initialize() -> void:
 var state := GameState.new(42)
 state.cities = [{"name":"A","x":0,"y":0,"population":1000,"completed":{}},{"name":"B","x":2,"y":2,"population":1000,"completed":{}}]
 state.roads = [
  {"id":1,"path":[[0,0],[1,0],[2,0]],"type":0,"length":2.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0},
  {"id":2,"path":[[2,0],[2,1],[2,2]],"type":0,"length":2.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 ]
 state._spawn()
 assert(state.vehicles.size() == 1)
 var before: float = state.money
 for i: int in range(5): state.step(0.25)
 var copy: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(state.data())))
 assert(copy.vehicles.size() == 1)
 copy.spawn_clock = -1000.0
 for i: int in range(30): copy.step(0.25)
 assert(copy.completed == 1)
 var received: float = copy.money - before
 for i: int in range(10): copy.step(0.25)
 assert(copy.completed == 1 and is_equal_approx(copy.money-before,received))
 assert(not copy.closure_impact(2).contains("No se pierde"))
 print("JOURNEY OK: varios tramos, reanudación y un solo ingreso")
 quit()
