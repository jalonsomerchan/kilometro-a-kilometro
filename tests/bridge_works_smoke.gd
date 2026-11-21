extends SceneTree

func _initialize() -> void:
 var state := GameState.new(23)
 var water_x: int = 19
 while state.world.terrain(Vector2i(water_x,0)) != "agua": water_x += 1
 var left: int = water_x
 while state.world.terrain(Vector2i(left,0)) == "agua": left -= 1
 var right: int = water_x
 while state.world.terrain(Vector2i(right,0)) == "agua": right += 1
 var path: Array = []
 for x: int in range(left,right+1): path.append([x,0])
 var road: Dictionary = {"id":1,"path":path,"type":0,"length":float(right-left),"water":right-left-1,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 road.bridges = state._create_bridges(road)
 assert(road.bridges.size() == 1)
 road.bridges[0].condition = 9.0
 state.roads = [road]
 assert(RoadNetwork.route(state.roads,Vector2i(left,0),Vector2i(right,0)).is_empty())
 var old_money: float = state.money
 assert(state.start_work(road,{"kind":"bridge","target":0,"cost":100.0,"duration":2.0}))
 state.step(0.5)
 var copy: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(state.data())))
 assert(copy.roads[0].pending_bridge == 0 and is_equal_approx(copy.roads[0].work,1.5))
 for i: int in range(6): copy.step(0.25)
 assert(float(copy.roads[0].bridges[0].condition) == 100.0)
 assert(not RoadNetwork.route(copy.roads,Vector2i(left,0),Vector2i(right,0)).is_empty())
 assert(is_equal_approx(copy.money,old_money-100.0))
 print("BRIDGE OK: cierre, reparación, coste y obra guardada")
 quit()
