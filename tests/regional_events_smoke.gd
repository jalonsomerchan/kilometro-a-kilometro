extends SceneTree

func _initialize() -> void:
 var state := GameState.new(42)
 state.cities = [{"name":"A","x":0,"y":0,"population":1000,"completed":{}},{"name":"B","x":4,"y":0,"population":1000,"completed":{}}]
 var a: Dictionary = {"id":1,"path":[[0,0],[1,0]],"type":0,"length":1.0,"water":0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 var b: Dictionary = {"id":2,"path":[[4,0],[5,0]],"type":0,"length":1.0,"water":0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 var far: Dictionary = {"id":4,"path":[[80,0],[81,0]],"type":0,"length":1.0,"water":0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 state.roads = [a,b,far]
 GameEvents.forecast(state,"snow",1,2.0,5.0)
 var restored: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(state.data())))
 assert(restored.forecasts.size()==1)
 restored.elapsed = 2.0
 GameEvents.advance(restored,0.0)
 assert(restored.events.size()==1 and restored.forecasts.is_empty())
 var event: Dictionary = restored.events[0]
 assert(event.affected.size()==2)
 assert(int(restored.roads[0].snow_count)==1 and int(restored.roads[1].snow_count)==1)
 assert(GameEvents.clear_road(restored,event,1))
 assert(int(restored.roads[0].snow_count)==0 and int(restored.roads[1].snow_count)==1)
 var second: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(restored.data())))
 second.elapsed += 5.0
 GameEvents.advance(second,5.0)
 assert(second.events.is_empty())
 assert(int(second.roads[0].snow_count)==0 and int(second.roads[1].snow_count)==0)
 print("REGIONAL EVENTS OK: previsión, zona, despeje y reanudación")
 quit()
