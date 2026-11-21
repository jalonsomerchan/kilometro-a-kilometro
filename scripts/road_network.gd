class_name RoadNetwork
extends RefCounted

# Each road owns its own nodes. Transfers at a shared coordinate are explicit,
# so an elevated road cannot accidentally connect to the road underneath.
static func route(roads: Array, origin: Vector2i, destination: Vector2i, excluded_id: int = -1, traffic: Dictionary = {}, source_road_id: int = -1, source_index: int = -1, junction_delays: Dictionary = {}, roundabouts: Dictionary = {}, toll_value_of_time: float = 0.0) -> Array:
 var edges: Dictionary = {}
 var positions: Dictionary = {}
 var start_nodes: Array = []
 var source_road: Dictionary = {}
 if source_road_id >= 0:
  for existing: Dictionary in roads:
   if int(existing.id) == source_road_id: source_road = existing; break
  if source_road.is_empty() or source_index < 0 or source_index >= source_road.path.size(): return []
 var end_nodes: Array = []
 for road: Dictionary in roads:
  if int(road.id) == excluded_id or road_closed(road): continue
  var path: Array = road.path
  for i: int in range(path.size()):
   var key: String = "%d:%d" % [road.id,i]
   var coord := Vector2i(int(path[i][0]),int(path[i][1]))
   edges[key] = []
   if not positions.has(coord): positions[coord] = []
   positions[coord].append({"key":key,"road":road,"index":i})
   if coord == origin:
    var compatible: bool = source_road_id < 0 or int(road.id) == source_road_id
    if not compatible and int(road.type) <= 3 and int(source_road.type) <= 3:
     compatible = _level(road,i) == _level(source_road,source_index)
    if compatible: start_nodes.append(key)
   if coord == destination: end_nodes.append(key)
  for i: int in range(path.size()-1):
   var a: String = "%d:%d" % [road.id,i]
   var b: String = "%d:%d" % [road.id,i+1]
   var length: float = Vector2(float(path[i][0]-path[i+1][0]),float(path[i][1]-path[i+1][1])).length()
   var speed: float = maxf(1.0,float(road.speed_limit) * maxf(0.3,float(road.condition)/100.0))
   var load: float = float(traffic.get(int(road.id),0.0))
   var congestion: float = maxf(0.16, 1.0 / (1.0 + 2.0 * pow(maxf(0.0,load-0.65),2.0)))
   var weather: float = 0.55 if int(road.get("snow_count",0)) > 0 else 1.0
   var curvature: float = RoadGeometry.segment_speed_factor(path,i,int(road.get("type",0)))
   var weight: float = length * 25.0 / (speed * congestion * weather * curvature)
   if toll_value_of_time > 0.0 and int(road.get("type",0)) == 6:
    var road_length: float = maxf(length,float(road.get("length",float(path.size()-1))))
    weight += float(road.get("toll",0.0))/toll_value_of_time*length/road_length
   edges[a].append({"to":b,"weight":weight+_signal_delay(road,i+1,1,roundabouts)+float(junction_delays.get("%d,%d" % [path[i+1][0],path[i+1][1]],0.0)),"road":int(road.id),"from_index":i,"to_index":i+1})
   edges[b].append({"to":a,"weight":weight+_signal_delay(road,i,-1,roundabouts)+float(junction_delays.get("%d,%d" % [path[i][0],path[i][1]],0.0)),"road":int(road.id),"from_index":i+1,"to_index":i})
 for coord: Vector2i in positions:
  var entries: Array = positions[coord]
  for i: int in range(entries.size()):
   for j: int in range(i+1,entries.size()):
    var a: Dictionary = entries[i]
    var b: Dictionary = entries[j]
    if a.road.id == b.road.id: continue
    # Higher categories need explicit links, which are not yet implemented.
    if int(a.road.type) > 3 or int(b.road.type) > 3: continue
    if _level(a.road, int(a.index)) != _level(b.road, int(b.index)): continue
    edges[a.key].append({"to":b.key,"weight":0.0,"road":-1})
    edges[b.key].append({"to":a.key,"weight":0.0,"road":-1})
 if start_nodes.is_empty() or end_nodes.is_empty(): return []
 var distance: Dictionary = {}
 var previous: Dictionary = {}
 var open: Array = []
 for key: String in start_nodes:
  distance[key] = 0.0
  open.append(key)
 var final_key: String = ""
 while not open.is_empty():
  var best: int = 0
  for i: int in range(1,open.size()):
   if float(distance[open[i]]) < float(distance[open[best]]): best = i
  var current: String = open.pop_at(best)
  if end_nodes.has(current): final_key = current; break
  for edge: Dictionary in edges[current]:
   var next: String = edge.to
   var value: float = float(distance[current]) + float(edge.weight)
   if not distance.has(next) or value < float(distance[next]):
    distance[next] = value
    previous[next] = {"node":current,"edge":edge}
    if not open.has(next): open.append(next)
 if final_key.is_empty(): return []
 var result: Array = []
 while previous.has(final_key):
  var entry: Dictionary = previous[final_key]
  if int(entry.edge.road) >= 0: result.push_front(entry.edge.duplicate())
  final_key = entry.node
 return result

static func _level(road: Dictionary, index: int) -> int:
 for raised: Variant in road.get("raised_indices", []):
  if int(raised) == index: return 1
 return int(road.get("level",0))

static func road_closed(road: Dictionary) -> bool:
 if bool(road.get("manual_closed",false)): return true
 if float(road.work) > 0.0 or float(road.condition) < 10.0 or int(road.get("event_closures",0)) > 0: return true
 for bridge: Dictionary in road.get("bridges",[]):
  if float(bridge.condition) < 10.0: return true
 return false

static func closure_reasons(road: Dictionary, include_manual: bool = true) -> Array[String]:
 var reasons: Array[String] = []
 if include_manual and bool(road.get("manual_closed",false)): reasons.append("cierre manual")
 if float(road.get("work",0.0)) > 0.0: reasons.append("obras (%.0f s restantes)" % float(road.work))
 if int(road.get("event_closures",0)) > 0: reasons.append("evento activo")
 if float(road.get("condition",100.0)) < 10.0: reasons.append("conservación crítica")
 for bridge: Dictionary in road.get("bridges",[]):
  if float(bridge.condition) < 10.0:
   reasons.append("puente en estado crítico")
   break
 return reasons

static func _signal_delay(road: Dictionary, index: int, direction: int, roundabouts: Dictionary = {}) -> float:
 var point: Array = road.path[index]
 var key: String = "%d,%d" % [point[0],point[1]]
 if roundabouts.has(key) and float(roundabouts[key].get("work",0.0)) <= 0.0: return 0.0
 for signal_data: Dictionary in road.get("signals",[]):
  if int(signal_data.index) == index and int(signal_data.direction) == direction:
   return 1.5 if signal_data.type == "stop" else 0.0
 return 0.0
