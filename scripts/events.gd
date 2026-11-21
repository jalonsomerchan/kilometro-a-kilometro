class_name GameEvents
extends RefCounted

const TITLES: Dictionary = {"snow":"Nevada","fire":"Incendio forestal","flood":"Crecida","landslide":"Desprendimiento","fair":"Feria local"}
const RADIUS: float = 18.0

static func forecast(state: GameState, kind: String, road_id: int, delay: float = 30.0, duration: float = 45.0) -> void:
 var road: Dictionary = state._road_by_id(road_id)
 if road.is_empty(): return
 var point: Vector2i = _road_midpoint(road)
 state.forecasts.append({"kind":kind,"road_id":road_id,"start_at":state.elapsed+delay,"duration":duration,"x":point.x,"y":point.y})
 state.latest_notice = "Previsión: %s cerca de (%d,%d) en %.0f s." % [TITLES.get(kind,kind),point.x,point.y,delay]
 state.notice_road = road_id

static func start(state: GameState, kind: String, road_id: int, duration: float = 45.0) -> Dictionary:
 var road: Dictionary = state._road_by_id(road_id)
 if road.is_empty(): return {}
 if kind == "flood" and int(road.get("water",0)) == 0: return {}
 var center: Vector2i = _road_midpoint(road)
 var event: Dictionary = {"kind":kind,"title":TITLES.get(kind,kind),"road_id":road_id,"started":state.elapsed,"remaining":duration,"duration":duration,"center":[center.x,center.y],"radius":RADIUS,"affected":[],"spread_at":state.elapsed+15.0,"spread_done":false,"target_city":_nearest_city(state,center)}
 state.events.append(event)
 for candidate: Dictionary in state.roads:
  if kind == "landslide" and int(candidate.id) != road_id: continue
  if kind == "fire" and int(candidate.id) != road_id: continue
  if kind == "flood" and int(candidate.get("water",0)) == 0: continue
  if _distance_to_road(candidate,center) <= RADIUS:
   _affect(state,event,candidate)
 state.route_cache.clear()
 state.latest_notice = "%s en (%d,%d): %d tramos afectados durante %.0f s." % [event.title,center.x,center.y,event.affected.size(),duration]
 state.notice_road = road_id
 return event

static func _affect(state: GameState, event: Dictionary, road: Dictionary) -> void:
 for entry: Dictionary in event.affected:
  if int(entry.road_id) == int(road.id): return
 var kind: String = str(event.kind)
 var closed: bool = kind in ["fire","flood","landslide"]
 if kind == "snow":
  for p: Array in road.path:
   if state.world.terrain(Vector2i(int(p[0]),int(p[1]))) == "colina" and int(road.id) % 3 == 0: closed = true; break
 var damage: float = 8.0 if kind == "fire" else (4.0 if kind == "flood" else 0.0)
 var entry: Dictionary = {"road_id":int(road.id),"closed":closed,"snow":kind == "snow","damage":damage,"cleared":false}
 event.affected.append(entry)
 if closed: road.event_closures = int(road.get("event_closures",0))+1
 if kind == "snow": road.snow_count = int(road.get("snow_count",0))+1

static func _legacy_entries(event: Dictionary) -> void:
 if event.has("affected"): return
 event.affected = [{"road_id":int(event.road_id),"closed":bool(event.get("closed",false)),"snow":event.kind == "snow","damage":float(event.get("damage",0.0)),"cleared":false}]

static func clear_road(state: GameState, event: Dictionary, road_id: int) -> bool:
 _legacy_entries(event)
 for entry: Dictionary in event.affected:
  if int(entry.road_id) == road_id and not bool(entry.cleared):
   _release(state,event,entry,false)
   state.route_cache.clear()
   return true
 return false

static func _release(state: GameState, event: Dictionary, entry: Dictionary, apply_damage: bool) -> void:
 if bool(entry.cleared): return
 var road: Dictionary = state._road_by_id(int(entry.road_id))
 if not road.is_empty():
  if bool(entry.closed): road.event_closures = maxi(0,int(road.get("event_closures",0))-1)
  if bool(entry.snow): road.snow_count = maxi(0,int(road.get("snow_count",0))-1)
  if apply_damage:
   road.condition = maxf(0.0,float(road.condition)-float(entry.damage))
   if event.kind == "flood":
    for bridge: Dictionary in road.get("bridges",[]): bridge.condition = maxf(0.0,float(bridge.condition)-float(entry.damage))
 entry.cleared = true

static func advance(state: GameState, dt: float) -> void:
 var ready: Array = []
 for prediction: Dictionary in state.forecasts:
  if state.elapsed >= float(prediction.start_at): ready.append(prediction)
 for prediction: Dictionary in ready:
  state.forecasts.erase(prediction)
  start(state,str(prediction.kind),int(prediction.road_id),float(prediction.duration))
 var finished: Array = []
 for event: Dictionary in state.events:
  _legacy_entries(event)
  event.remaining = maxf(0.0,float(event.remaining)-dt)
  if event.kind == "fire" and not bool(event.get("spread_done",true)) and state.elapsed >= float(event.get("spread_at",0.0)):
   event.spread_done = true
   var center := Vector2i(int(event.center[0]),int(event.center[1]))
   for road: Dictionary in state.roads:
    if _distance_to_road(road,center) <= RADIUS*1.5 and _road_has_forest(state,road): _affect(state,event,road)
   state.route_cache.clear()
   state.latest_notice = "El incendio se extiende: %d tramos afectados." % event.affected.size()
  if float(event.remaining) > 0.0: continue
  for entry: Dictionary in event.affected: _release(state,event,entry,true)
  state.latest_notice = "%s terminado cerca del tramo %d." % [event.title,event.road_id]
  state.notice_road = int(event.road_id)
  finished.append(event)
 for event: Dictionary in finished: state.events.erase(event)
 if not finished.is_empty(): state.route_cache.clear()

static func _road_midpoint(road: Dictionary) -> Vector2i:
 var p: Array = road.path[int(road.path.size()/2)]
 return Vector2i(int(p[0]),int(p[1]))

static func _distance_to_road(road: Dictionary, center: Vector2i) -> float:
 var distance: float = INF
 for p: Array in road.path: distance = minf(distance,Vector2(center).distance_to(Vector2(float(p[0]),float(p[1]))))
 return distance

static func _road_has_forest(state: GameState, road: Dictionary) -> bool:
 for p: Array in road.path:
  if state.world.terrain(Vector2i(int(p[0]),int(p[1]))) == "bosque": return true
 return false

static func _nearest_city(state: GameState, point: Vector2i) -> int:
 var result: int = -1
 var distance: float = INF
 for i: int in range(state.cities.size()):
  var d: float = Vector2(point).distance_to(Vector2(state._city_position(i)))
  if d < distance: distance = d; result = i
 return result
