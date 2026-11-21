extends SceneTree

func _initialize() -> void:
 var state := GameState.new(42)
 state.cities = [{"name":"A","x":0,"y":0,"population":1000,"completed":{}},{"name":"B","x":2,"y":0,"population":1000,"completed":{}}]
 state.roads = [{"id":1,"path":[[0,0],[1,0],[2,0]],"type":0,"length":2.0,"water":1,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}]
 GameEvents.start(state,"snow",1,4.0)
 assert(int(state.roads[0].snow_count)==1)
 GameEvents.start(state,"fire",1,3.0)
 assert(RoadNetwork.route(state.roads,Vector2i(0,0),Vector2i(2,0)).is_empty())
 state.step(1.0)
 var copy: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(state.data())))
 assert(copy.events.size()==2 and int(copy.roads[0].event_closures)==1)
 copy.step(3.0)
 assert(copy.events.is_empty())
 assert(int(copy.roads[0].event_closures)==0 and int(copy.roads[0].snow_count)==0)
 assert(float(copy.roads[0].condition)<100.0)
 assert(not RoadNetwork.route(copy.roads,Vector2i(0,0),Vector2i(2,0)).is_empty())
 print("EVENTS OK: nevada, incendio, persistencia y reapertura")
 quit()
