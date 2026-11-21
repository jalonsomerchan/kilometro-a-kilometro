extends SceneTree

class FlatWorld extends WorldGenerator:
 func terrain(_p: Vector2i) -> String: return "pradera"

class RiverWorld extends WorldGenerator:
 func terrain(p: Vector2i) -> String: return "agua" if p.x == 2 else "pradera"

func _initialize() -> void:
 var flat := FlatWorld.new(1)
 var diagonal: Array[Vector2i] = [Vector2i(0,1),Vector2i(1,2),Vector2i(2,3),Vector2i(3,4),Vector2i(4,5),Vector2i(5,6)]
 var lower_diag: Dictionary = {"id":1,"path":[[2,4],[3,3]],"type":0,"work":0.0,"condition":100.0,"speed_limit":25.0}
 var rejected: Dictionary = RoadPlanner.add_crossings(flat,RoadPlanner._describe(flat,diagonal),[lower_diag],false,0)
 assert(rejected.has("error") and rejected.has("conflict_index"))
 var raised: Dictionary = RoadPlanner.add_crossings(flat,RoadPlanner._describe(flat,diagonal),[lower_diag],true,0)
 assert(not raised.has("error") and raised.raised_indices == [2,3] and raised.overpasses.size()==1)
 var upper_diag: Dictionary = {"id":2,"path":[[0,1],[1,2],[2,3],[3,4],[4,5],[5,6]],"type":0,"work":0.0,"condition":100.0,"speed_limit":25.0,"raised_indices":raised.raised_indices}
 assert(RoadNetwork.route([lower_diag,upper_diag],Vector2i(2,4),Vector2i(5,6)).is_empty())
 assert(not RoadNetwork.route([lower_diag,upper_diag],Vector2i(0,1),Vector2i(5,6)).is_empty())
 var invalid: Dictionary = RoadPlanner.add_crossings(flat,RoadPlanner._describe(flat,diagonal),[{"id":3,"path":[[2,4],[3,3]],"type":0,"raised_indices":[0,1]}],true,0)
 assert(invalid.has("error"))
 var world := RiverWorld.new(5)
 var path: Array[Vector2i] = []
 for x: int in range(13): path.append(Vector2i(x,0))
 var lower: Dictionary = {"id":10,"path":[[7,-2],[7,-1],[7,0],[7,1],[7,2]],"type":0,"length":4.0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 var proposal: Dictionary = RoadPlanner.add_crossings(world,RoadPlanner._describe(world,path),[lower],true,0)
 assert(not proposal.has("error") and proposal.water==1 and proposal.overpasses.size()==1)
 assert(proposal.overpasses[0].start == [6,0] and proposal.overpasses[0].end == [8,0])
 var state := GameState.new(5)
 state.world = world
 state.roads = [lower]
 state.next_id = 11
 state.cities = [{"name":"A","x":0,"y":0,"population":1000,"completed":{}},{"name":"B","x":12,"y":0,"population":1000,"completed":{}},{"name":"C","x":7,"y":-2,"population":1000,"completed":{}},{"name":"D","x":7,"y":2,"population":1000,"completed":{}}]
 var price: float = state.price(proposal,0)
 var duration: float = state.construction_time(proposal)
 state.build(proposal,0)
 assert(is_equal_approx(state.money,Balance.INITIAL_MONEY-price))
 assert(float(state.roads[1].work)==duration and state.roads[1].bridges.size()==1)
 assert(not RoadNetwork.route(state.roads,Vector2i(7,-2),Vector2i(7,2)).is_empty())
 assert(RoadNetwork.route(state.roads,Vector2i(0,0),Vector2i(12,0)).is_empty())
 var loaded: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(state.data())))
 assert(loaded.roads[1].overpasses.size()==1 and is_equal_approx(float(loaded.roads[1].work),duration))
 assert(loaded.roads[1].path.has([7,0]) and RoadNetwork._level(loaded.roads[1],7)==1)
 loaded.spawn_clock = -1000.0
 for i: int in range(ceili(duration/0.25)): loaded.step(0.25)
 assert(RoadNetwork.route(loaded.roads,Vector2i(7,-2),Vector2i(12,0)).is_empty())
 assert(loaded._start_trip(0,1) and loaded._start_trip(2,3))
 for i: int in range(100): loaded.step(0.25)
 assert(loaded.completed==2)
 assert(is_equal_approx(loaded.expenses,price))
 print("OVERPASS FULL OK: diagonal, río, rampas, guardado y tráfico independiente")
 quit()
