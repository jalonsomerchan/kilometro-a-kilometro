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

# Crossing structures are attached to individual path indices rather than to an
# entire road, leaving both ends and the ramps at ground level.
static func add_crossings(world: WorldGenerator, proposal: Dictionary, roads: Array, elevated: bool, road_type: int) -> Dictionary:
 if proposal.has("error"): return proposal
 var path: Array = proposal.path
 var crossings: Array = []
 var raised: Array = []
 for i: int in range(1,path.size()-1):
  var point: Vector2i = path[i]
  var overlaps: Array = []
  for road: Dictionary in roads:
   if road.path.has([point.x,point.y]): overlaps.append(road)
  if overlaps.is_empty(): continue
  var require_grade: bool = road_type >= 4
  for road: Dictionary in overlaps:
   if int(road.type) >= 4: require_grade = true
  if not elevated and require_grade:
   return {"error":"La categoría exige un paso elevado en (%d, %d). Actívalo en el menú." % [point.x,point.y]}
  if elevated:
   if i < 2 or i > path.size()-3:
    return {"error":"Falta espacio para las rampas en (%d, %d)." % [point.x,point.y]}
   if world.terrain(path[i-1]) == "agua" or world.terrain(path[i+1]) == "agua":
    return {"error":"Las rampas necesitan apoyos en tierra en (%d, %d)." % [point.x,point.y]}
   if not raised.is_empty() and i-int(raised[-1]) <= 2:
    return {"error":"Los cruces están demasiado próximos para colocar rampas separadas."}
   raised.append(i)
  crossings.append({"index":i,"x":point.x,"y":point.y,"elevated":elevated})
 proposal["crossings"] = crossings
 proposal["raised_indices"] = raised
 proposal["overpass_cost"] = float(raised.size()) * 650.0
 return proposal
