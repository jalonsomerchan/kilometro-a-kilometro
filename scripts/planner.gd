class_name RoadPlanner
extends RefCounted

# A bounded A* keeps proposals responsive; each state retains its incoming direction.
static func plan(world: WorldGenerator, start: Vector2i, finish: Vector2i) -> Dictionary:
 if start.distance_to(finish) > 110.0: return {"error":"Destino demasiado lejano; construye por etapas."}
 var open: Array[Vector2i] = [start]
 var came: Dictionary = {}
 var cost: Dictionary = {start: 0.0}
 var score: Dictionary = {start: start.distance_to(finish)}
 var dirs: Array[Vector2i] = [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)]
 var iterations: int = 0
 while not open.is_empty() and iterations < 16000:
  iterations += 1
  var best: int = 0
  for i: int in range(1, open.size()):
   if float(score[open[i]]) < float(score[open[best]]): best = i
  var current: Vector2i = open.pop_at(best)
  if current == finish:
   var path: Array[Vector2i] = [current]
   while came.has(current):
    current = came[current]
    path.push_front(current)
   return _describe(world, path)
  for d: Vector2i in dirs:
   var next: Vector2i = current + d
   if next.distance_to(start) > 125.0: continue
   if d.x != 0 and d.y != 0 and world.terrain(current + Vector2i(d.x,0)) == "roca" and world.terrain(current + Vector2i(0,d.y)) == "roca": continue
   var terrain: String = world.terrain(next)
   var weight: float = 1.0
   if terrain == "bosque": weight = 1.5
   if terrain == "colina": weight = 1.7
   if terrain == "roca": weight = 3.5
   if terrain == "agua": weight = 3.0
   var turn: float = 0.0
   if came.has(current) and current - Vector2i(came[current]) != d: turn = 0.18
   var next_cost: float = float(cost[current]) + Vector2(d).length() * weight + turn
   if not cost.has(next) or next_cost < float(cost[next]):
    came[next] = current
    cost[next] = next_cost
    score[next] = next_cost + next.distance_to(finish)
    if not open.has(next): open.append(next)
 return {"error":"No se ha encontrado un trazado viable."}

static func plan_via(world: WorldGenerator, start: Vector2i, via: Vector2i, finish: Vector2i) -> Dictionary:
 var first: Dictionary = plan(world,start,via)
 if first.has("error"): return first
 var second: Dictionary = plan(world,via,finish)
 if second.has("error"): return second
 var path: Array[Vector2i] = []
 for point: Vector2i in first.path: path.append(point)
 for i: int in range(1,second.path.size()): path.append(second.path[i])
 return _describe(world,path)

static func _describe(world: WorldGenerator, path: Array[Vector2i]) -> Dictionary:
 var length: float = 0.0
 var terrain_cost: float = 0.0
 var water: int = 0
 var max_water: int = 0
 var run: int = 0
 for i: int in range(path.size()):
  if i > 0: length += Vector2(path[i] - path[i-1]).length()
  var t: String = world.terrain(path[i])
  if t == "agua":
   water += 1
   run += 1
   max_water = maxi(max_water, run)
  else: run = 0
  if t == "bosque": terrain_cost += 25.0
  if t == "colina": terrain_cost += 45.0
  if t == "roca": terrain_cost += 150.0
 if world.terrain(path[0]) == "agua" or world.terrain(path[-1]) == "agua": return {"error":"El puente necesita desembarcos en tierra."}
 if max_water > Balance.MAX_BRIDGE: return {"error":"El puente supera la longitud máxima."}
 return {"path":path, "length":length, "terrain_cost":terrain_cost, "water":water}

# A crossing may occur at a shared cell or halfway along two diagonals. Both
# forms have real ground-level ramps and a raised deck in the road graph.
static func add_crossings(world: WorldGenerator, proposal: Dictionary, roads: Array, elevated: bool, road_type: int) -> Dictionary:
 if proposal.has("error"): return proposal
 var path: Array = proposal.path
 var crossings: Array = []
 var spans: Array = []
 var raised: Array = []
 for i: int in range(1,path.size()-1):
  var point: Vector2i = path[i]
  var overlaps: Array = []
  for road: Dictionary in roads:
   if road.path.has([point.x,point.y]): overlaps.append(road)
  if overlaps.is_empty(): continue
  var require_grade: bool = road_type >= 4
  for road: Dictionary in overlaps:
   var index: int = road.path.find([point.x,point.y])
   if int(road.type) >= 4: require_grade = true
   if elevated and RoadNetwork._level(road,index) != 0:
    return _crossing_error(proposal,"Ya hay una vía elevada en (%d, %d); no hay altura libre." % [point.x,point.y],i)
  if not elevated and require_grade:
   return _crossing_error(proposal,"La categoría exige un paso elevado en (%d, %d). Actívalo en el menú." % [point.x,point.y],i)
  if elevated:
   var reason: String = _validate_overpass(world,path,roads,i,i)
   if not reason.is_empty(): return _crossing_error(proposal,reason,i)
   if not _span_available(spans,i,i): return _crossing_error(proposal,"Los cruces están demasiado próximos para colocar rampas separadas.",i)
   raised.append(i)
   spans.append(_make_span(path,i,i))
  crossings.append({"index":i,"x":point.x,"y":point.y,"elevated":elevated})
 # Detect the X formed by diagonal segments that cross between tile centres.
 for i: int in range(path.size()-1):
  var a: Vector2i = path[i]
  var b: Vector2i = path[i+1]
  if absi(b.x-a.x) != 1 or absi(b.y-a.y) != 1: continue
  for road: Dictionary in roads:
   var old_path: Array = road.path
   for j: int in range(old_path.size()-1):
    var c := Vector2i(int(old_path[j][0]),int(old_path[j][1]))
    var d := Vector2i(int(old_path[j+1][0]),int(old_path[j+1][1]))
    if absi(d.x-c.x) != 1 or absi(d.y-c.y) != 1: continue
    if a+b != c+d or (b-a) == (d-c) or (b-a) == (c-d): continue
    if not elevated: return _crossing_error(proposal,"Dos diagonales se cruzan entre casillas. Usa un paso elevado o cambia el trazado.",i)
    if RoadNetwork._level(road,j) != 0 or RoadNetwork._level(road,j+1) != 0:
     return _crossing_error(proposal,"Ya hay una vía elevada bajo este cruce diagonal.",i)
    var reason: String = _validate_overpass(world,path,roads,i,i+1)
    if not reason.is_empty(): return _crossing_error(proposal,reason,i)
    if not _span_available(spans,i,i+1): return _crossing_error(proposal,"Los cruces están demasiado próximos para colocar rampas separadas.",i)
    raised.append(i)
    raised.append(i+1)
    var span: Dictionary = _make_span(path,i,i+1)
    span["lower_road_id"] = int(road.id)
    span["lower_first"] = j
    span["lower_last"] = j+1
    spans.append(span)
 proposal["crossings"] = crossings
 proposal["overpasses"] = spans
 proposal["raised_indices"] = raised
 proposal["overpass_cost"] = float(spans.size()) * Balance.OVERPASS_COST
 return proposal

static func _validate_overpass(world: WorldGenerator, path: Array, roads: Array, first: int, last: int) -> String:
 if first < 2 or last > path.size()-3: return "Falta espacio para las rampas del paso elevado."
 var start: Vector2i = path[first-1]
 var finish: Vector2i = path[last+1]
 for ramp: Vector2i in [start,finish]:
  if world.terrain(ramp) in ["agua","roca"]: return "Las rampas necesitan apoyos en tierra firme."
  for road: Dictionary in roads:
   if road.path.has([ramp.x,ramp.y]): return "Una carretera ocupa una rampa; ajusta el trazado."
 var incoming: Vector2 = Vector2(path[first]-path[first-1]).normalized()
 var outgoing: Vector2 = Vector2(path[last+1]-path[last]).normalized()
 if incoming.dot(outgoing) < 0.70: return "El paso elevado necesita rampas más rectas."
 return ""

static func _span_available(spans: Array, first: int, last: int) -> bool:
 for span: Dictionary in spans:
  if first <= int(span.last)+2 and last >= int(span.first)-2: return false
 return true

static func _make_span(path: Array, first: int, last: int) -> Dictionary:
 var start: Vector2i = path[first-1]
 var end: Vector2i = path[last+1]
 var length: float = 0.0
 for i: int in range(first-1,last+1): length += Vector2(path[i+1]-path[i]).length()
 return {"first":first,"last":last,"start":[start.x,start.y],"end":[end.x,end.y],"length":length}

static func _crossing_error(proposal: Dictionary, message: String, index: int) -> Dictionary:
 proposal["error"] = message
 proposal["conflict_index"] = index
 return proposal
