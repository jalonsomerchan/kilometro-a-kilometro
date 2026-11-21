class_name GameEvents
extends RefCounted

# Events own their affected road IDs, allowing closures to overlap safely.
static func start(state: GameState, kind: String, road_id: int, duration: float = 45.0) -> Dictionary:
 var road: Dictionary = state._road_by_id(road_id)
 if road.is_empty(): return {}
 var titles: Dictionary = {"snow":"Nevada","fire":"Incendio forestal","flood":"Crecida","landslide":"Desprendimiento","fair":"Feria local"}
 var closed: bool = kind in ["fire","flood","landslide"]
 if kind == "flood" and int(road.get("water",0)) == 0: return {}
 var event: Dictionary = {"kind":kind,"title":titles.get(kind,kind),"road_id":road_id,"started":state.elapsed,"remaining":duration,"duration":duration,"closed":closed,"damage":8.0 if kind == "fire" else (4.0 if kind == "flood" else 0.0)}
 state.events.append(event)
 if closed: road.event_closures = int(road.get("event_closures",0))+1
 if kind == "snow": road.snow_count = int(road.get("snow_count",0))+1
 state.route_cache.clear()
 state.latest_notice = "%s en el tramo %d: %s durante %.0f s." % [event.title,road_id,"corte" if closed else ("velocidad reducida" if kind == "snow" else "más demanda"),duration]
 state.notice_road = road_id
 return event

static func advance(state: GameState, dt: float) -> void:
 var finished: Array = []
 for event: Dictionary in state.events:
  event.remaining = maxf(0.0,float(event.remaining)-dt)
  if float(event.remaining) > 0.0: continue
  var road: Dictionary = state._road_by_id(int(event.road_id))
  if not road.is_empty():
   if bool(event.closed): road.event_closures = maxi(0,int(road.get("event_closures",0))-1)
   if event.kind == "snow": road.snow_count = maxi(0,int(road.get("snow_count",0))-1)
   road.condition = maxf(0.0,float(road.condition)-float(event.damage))
   if event.kind == "flood":
    for bridge: Dictionary in road.get("bridges",[]): bridge.condition = maxf(0.0,float(bridge.condition)-float(event.damage))
  state.latest_notice = "%s terminado en el tramo %d." % [event.title,event.road_id]
  state.notice_road = int(event.road_id)
  finished.append(event)
 for event: Dictionary in finished: state.events.erase(event)
 if not finished.is_empty(): state.route_cache.clear()
