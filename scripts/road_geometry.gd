class_name RoadGeometry
extends RefCounted

# Round each grid corner with a quadratic Bézier between the midpoints of its
# neighbouring edges. Shared road nodes remain fixed so the visual junction and
# the route graph agree. Each curve lies inside the corner's own grid cell.
static func point(path: Array, segment: int, t: float, anchors: Dictionary = {}) -> Vector2:
 var count: int = path.size()
 if count == 0: return Vector2.ZERO
 if count == 1: return _vector(path[0])
 var i: int = clampi(segment,0,count-2)
 var a: Vector2 = _vector(path[i])
 var b: Vector2 = _vector(path[i+1])
 var u: float = clampf(t,0.0,1.0)
 if u <= 0.5:
  if i == 0 or anchors.has(Vector2i(a)): return a.lerp((a+b)*0.5,u*2.0)
  var previous: Vector2 = _vector(path[i-1])
  return _quadratic((previous+a)*0.5,a,(a+b)*0.5,0.5+u)
 if i+1 == count-1 or anchors.has(Vector2i(b)): return ((a+b)*0.5).lerp(b,(u-0.5)*2.0)
 var following: Vector2 = _vector(path[i+2])
 return _quadratic((a+b)*0.5,b,(b+following)*0.5,u-0.5)

static func _quadratic(a: Vector2, control: Vector2, b: Vector2, t: float) -> Vector2:
 return a*(1.0-t)*(1.0-t) + control*(2.0*(1.0-t)*t) + b*t*t

static func polyline(path: Array, offset: Vector2, cell: float, steps: int = 8, anchors: Dictionary = {}) -> PackedVector2Array:
 var result := PackedVector2Array()
 if path.is_empty(): return result
 if path.size() == 1:
  result.append(offset+(_vector(path[0])+Vector2(0.5,0.5))*cell)
  return result
 for i: int in range(path.size()-1):
  for j: int in range(steps): result.append(offset+(point(path,i,float(j)/float(steps),anchors)+Vector2(0.5,0.5))*cell)
 result.append(offset+(_vector(path[-1])+Vector2(0.5,0.5))*cell)
 return result

static func _vector(value: Variant) -> Vector2:
 if value is Vector2i or value is Vector2: return Vector2(value)
 return Vector2(float(value[0]),float(value[1]))
