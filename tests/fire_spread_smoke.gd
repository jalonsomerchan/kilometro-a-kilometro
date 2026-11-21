extends SceneTree

func _initialize() -> void:
 var state := GameState.new(42)
 var forest := Vector2i.ZERO
 var found: bool = false
 for y: int in range(-80,81,4):
  for x: int in range(-80,81,4):
   if state.world.terrain(Vector2i(x,y))=="bosque": forest=Vector2i(x,y); found=true; break
  if found: break
 assert(found)
 var path: Array = [[forest.x,forest.y],[forest.x+1,forest.y]]
 var road1: Dictionary = {"id":1,"path":path,"type":0,"length":1.0,"water":0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 var road2: Dictionary = {"id":2,"path":path.duplicate(true),"type":0,"length":1.0,"water":0,"work":0.0,"condition":100.0,"speed_limit":25.0,"trips":0}
 state.roads = [road1,road2]
 var event: Dictionary = GameEvents.start(state,"fire",1,30.0)
 assert(event.affected.size()==1 and int(road1.event_closures)==1)
 state.elapsed = 15.0
 GameEvents.advance(state,15.0)
 assert(event.affected.size()==2 and int(road2.event_closures)==1)
 var copy: GameState = GameState.from_data(JSON.parse_string(JSON.stringify(state.data())))
 copy.elapsed = 30.0
 GameEvents.advance(copy,15.0)
 assert(copy.events.is_empty() and int(copy.roads[0].event_closures)==0 and int(copy.roads[1].event_closures)==0)
 assert(float(copy.roads[0].condition)==92.0 and float(copy.roads[1].condition)==92.0)
 print("FIRE OK: propagación, cierre, daño y reapertura")
 quit()
