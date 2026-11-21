extends SceneTree

func _initialize() -> void:
 var path: Array = [[0,0],[1,0],[1,1],[2,2],[3,2]]
 var anchors: Dictionary = {Vector2i(1,1):true}
 var has_curve: bool = false
 for i: int in range(path.size()-1):
  var a := Vector2(float(path[i][0]),float(path[i][1]))
  var b := Vector2(float(path[i+1][0]),float(path[i+1][1]))
  var previous: Vector2 = RoadGeometry.point(path,i,0.0,anchors)
  if i == 0: assert(previous.is_equal_approx(a))
  if i > 0: assert(previous.is_equal_approx(RoadGeometry.point(path,i-1,1.0,anchors)))
  if anchors.has(Vector2i(a)): assert(previous.is_equal_approx(a))
  for j: int in range(1,101):
   var t: float = float(j)/100.0
   var p: Vector2 = RoadGeometry.point(path,i,t,anchors)
   assert((absf(p.x-a.x) <= 0.5001 and absf(p.y-a.y) <= 0.5001) or (absf(p.x-b.x) <= 0.5001 and absf(p.y-b.y) <= 0.5001))
   assert(p.distance_to(previous)<0.05, "La geometría debe ser continua")
   if p.distance_to(a.lerp(b,t)) > 0.02: has_curve = true
   previous = p
  if anchors.has(Vector2i(b)): assert(previous.is_equal_approx(b))
 assert(has_curve, "Los giros deben redondearse visiblemente")
 assert(RoadGeometry.point(path,0,1.0,anchors).distance_to(Vector2(1,0)) > 0.1)
 var pixels: PackedVector2Array = RoadGeometry.polyline(path,Vector2.ZERO,24.0,8,anchors)
 assert(pixels.size() == (path.size()-1)*8+1)
 print("GEOMETRY OK: curvas redondeadas, continuidad y cruces fijos")
 quit()
